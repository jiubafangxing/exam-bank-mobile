package com.example.exammobile.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.exammobile.core.model.Answer
import com.example.exammobile.core.model.AppJson
import com.example.exammobile.core.model.AttemptState
import com.example.exammobile.core.model.EventRequest
import com.example.exammobile.core.model.Question
import com.example.exammobile.core.model.SaveAnswerRequest
import com.example.exammobile.core.network.ApiException
import com.example.exammobile.core.util.UiState
import com.example.exammobile.data.CandidateRepository
import kotlinx.coroutines.Job
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.serializer

data class LocalAnswer(
    val answerJson: String? = null,
    val answerText: String = "",
    val flagged: Boolean = false
)

/**
 * 作答状态机：开考/续考 → 逐题防抖保存 → 30s 心跳 → 交卷（自动/手动）。
 */
class ExamTakingViewModel(
    private val repository: CandidateRepository,
    private val examId: String
) : ViewModel() {

    private val _state = MutableStateFlow<UiState<AttemptState>>(UiState.Loading)
    val state: StateFlow<UiState<AttemptState>> = _state.asStateFlow()

    private val _currentIndex = MutableStateFlow(0)
    val currentIndex: StateFlow<Int> = _currentIndex.asStateFlow()

    private val _remaining = MutableStateFlow(0)
    val remainingSeconds: StateFlow<Int> = _remaining.asStateFlow()

    private val _answers = MutableStateFlow<Map<String, LocalAnswer>>(emptyMap())
    val answers: StateFlow<Map<String, LocalAnswer>> = _answers.asStateFlow()

    private val _fillValues = MutableStateFlow<Map<String, List<String>>>(emptyMap())
    val fillValues: StateFlow<Map<String, List<String>>> = _fillValues.asStateFlow()

    private val _saveStatus = MutableStateFlow<Map<String, String>>(emptyMap())
    val saveStatus: StateFlow<Map<String, String>> = _saveStatus.asStateFlow()

    private val _submitting = MutableStateFlow(false)
    val submitting: StateFlow<Boolean> = _submitting.asStateFlow()

    private val events = Channel<ExamEvent>(Channel.BUFFERED)
    val uiEvents = events.receiveAsFlow()

    private var countdownJob: Job? = null
    private var heartbeatJob: Job? = null
    private var localDeadline = 0L
    private var autoSubmitting = false
    private val debounceJobs = mutableMapOf<String, Job>()
    private val lastEventAt = mutableMapOf<String, Long>()

    fun load() {
        viewModelScope.launch {
            _state.value = UiState.Loading
            try {
                val data = repository.startExam(examId)
                applyState(data)
                if (data.status == "SUBMITTED" || data.status == "GRADED") {
                    events.send(ExamEvent.NavigateResult(data.attemptId))
                    return@launch
                }
                _state.value = UiState.Success(data)
                startTimers()
                reportEvent("FOCUS", "exam-loaded")
            } catch (e: Exception) {
                _state.value = UiState.Error(e.userMessage())
            }
        }
    }

    private fun applyState(data: AttemptState) {
        val answers = mutableMapOf<String, LocalAnswer>()
        val fills = mutableMapOf<String, List<String>>()
        data.questions.forEach { q ->
            answers[q.paperQuestionId] = LocalAnswer()
            if (q.type == "FILL") fills[q.paperQuestionId] = List(q.blanks.coerceAtLeast(1)) { "" }
        }
        data.answers.forEach { a: Answer ->
            answers[a.paperQuestionId] = LocalAnswer(a.answerJson, a.answerText ?: "", a.flagged)
            val q = data.questions.find { it.paperQuestionId == a.paperQuestionId }
            if (q != null && q.type == "FILL") {
                fills[q.paperQuestionId] = parseArray(a.answerJson, q.blanks.coerceAtLeast(1))
            }
            _saveStatus.value = _saveStatus.value + (a.paperQuestionId to "saved")
        }
        _answers.value = answers
        _fillValues.value = fills
        val remain = ((data.deadlineEpochMillis.toLongOrNull() ?: 0L) - (data.serverEpochMillis.toLongOrNull() ?: 0L)) / 1000
        _remaining.value = remain.coerceAtLeast(0).toInt()
        localDeadline = System.currentTimeMillis() + _remaining.value * 1000L
    }

    private fun parseArray(value: String?, length: Int): List<String> {
        val result = MutableList(length) { "" }
        if (value.isNullOrBlank()) return result
        return runCatching {
            val arr = AppJson.decodeFromString(ListSerializer(String.serializer()), value)
            arr.forEachIndexed { i, v -> if (i < length) result[i] = v }
            result.toList()
        }.getOrDefault(result)
    }

    private fun encodeArray(list: List<String>): String =
        AppJson.encodeToString(ListSerializer(String.serializer()), list)

    // ---------------- 作答交互 ----------------

    fun answerOf(question: Question): LocalAnswer =
        _answers.value[question.paperQuestionId] ?: LocalAnswer()

    fun selectedKeys(question: Question): List<String> {
        val raw = answerOf(question).answerJson ?: return emptyList()
        return runCatching { AppJson.decodeFromString(ListSerializer(String.serializer()), raw) }.getOrDefault(emptyList())
    }

    fun isSelected(question: Question, key: String): Boolean = selectedKeys(question).contains(key)

    fun isAnswered(question: Question): Boolean {
        val a = answerOf(question)
        return when (question.type) {
            "ESSAY" -> a.answerText.isNotBlank()
            "FILL" -> (_fillValues.value[question.paperQuestionId] ?: emptyList()).any { it.isNotBlank() }
            else -> selectedKeys(question).isNotEmpty()
        }
    }

    fun choose(question: Question, key: String) {
        val keys = selectedKeys(question).toMutableList()
        if (question.type == "MULTIPLE") {
            if (keys.contains(key)) keys.remove(key) else keys.add(key)
        } else {
            keys.clear(); keys.add(key)
        }
        updateAnswer(question, answerOf(question).copy(answerJson = encodeArray(keys)))
    }

    fun updateFill(question: Question, index: Int, value: String) {
        val list = (_fillValues.value[question.paperQuestionId]
            ?: List(question.blanks.coerceAtLeast(1)) { "" }).toMutableList()
        if (index in list.indices) list[index] = value
        _fillValues.value = _fillValues.value + (question.paperQuestionId to list)
        updateAnswer(question, answerOf(question).copy(answerJson = encodeArray(list)))
    }

    fun updateEssay(question: Question, text: String) {
        updateAnswer(question, answerOf(question).copy(answerText = text))
    }

    fun toggleFlag(question: Question) {
        updateAnswer(question, answerOf(question).copy(flagged = !answerOf(question).flagged))
    }

    private fun updateAnswer(question: Question, answer: LocalAnswer) {
        _answers.value = _answers.value + (question.paperQuestionId to answer)
        queueSave(question)
    }

    fun jumpTo(index: Int) {
        val total = (_state.value as? UiState.Success)?.data?.questions?.size ?: return
        if (index in 0 until total) _currentIndex.value = index
    }

    // ---------------- 防抖保存 ----------------

    private fun queueSave(question: Question) {
        val id = question.paperQuestionId
        setSaveStatus(id, "pending")
        debounceJobs[id]?.cancel()
        debounceJobs[id] = viewModelScope.launch {
            delay(500)
            saveNow(question)
        }
    }

    private suspend fun saveNow(question: Question) {
        val attempt = (_state.value as? UiState.Success)?.data ?: return
        setSaveStatus(question.paperQuestionId, "saving")
        val a = answerOf(question)
        val body = SaveAnswerRequest(
            answerJson = a.answerJson,
            answerText = a.answerText.ifBlank { null },
            flagged = a.flagged
        )
        try {
            repository.saveAnswer(attempt.attemptId, question.paperQuestionId, body)
            setSaveStatus(question.paperQuestionId, "saved")
        } catch (e: Exception) {
            setSaveStatus(question.paperQuestionId, "error")
        }
    }

    private fun setSaveStatus(id: String, status: String) {
        _saveStatus.value = _saveStatus.value + (id to status)
    }

    private suspend fun flushAll() {
        val data = (_state.value as? UiState.Success)?.data ?: return
        data.questions.filter { _saveStatus.value[it.paperQuestionId] != "saved" }.forEach { saveNow(it) }
    }

    // ---------------- 计时与心跳 ----------------

    private fun startTimers() {
        stopTimers()
        countdownJob = viewModelScope.launch {
            while (isActive) {
                delay(1000)
                val remain = ((localDeadline - System.currentTimeMillis()) / 1000).toInt()
                _remaining.value = remain.coerceAtLeast(0)
                if (remain <= 0 && !autoSubmitting) {
                    autoSubmitting = true
                    submit(auto = true)
                }
            }
        }
        heartbeatJob = viewModelScope.launch {
            while (isActive) {
                delay(30_000)
                runCatching { repository.heartbeat(attemptId()) }.onSuccess { hb ->
                    _remaining.value = hb.remainingSeconds
                    localDeadline = System.currentTimeMillis() + hb.remainingSeconds * 1000L
                }
            }
        }
    }

    private fun attemptId(): String =
        (_state.value as? UiState.Success)?.data?.attemptId.orEmpty()

    private fun stopTimers() {
        countdownJob?.cancel(); countdownJob = null
        heartbeatJob?.cancel(); heartbeatJob = null
    }

    // ---------------- 交卷 ----------------

    fun askSubmit() {
        viewModelScope.launch { events.send(ExamEvent.ConfirmSubmit) }
    }

    fun submit(auto: Boolean) {
        val data = (_state.value as? UiState.Success)?.data ?: return
        if (_submitting.value) return
        viewModelScope.launch {
            _submitting.value = true
            try {
                debounceJobs.values.forEach { it.cancel() }
                flushAll()
                repository.submit(data.attemptId)
                stopTimers()
                events.send(ExamEvent.Submitted(data.attemptId, auto))
            } catch (e: Exception) {
                autoSubmitting = false
                events.send(ExamEvent.Toast("交卷失败，请重试：${e.userMessage()}"))
            } finally {
                _submitting.value = false
            }
        }
    }

    // ---------------- 行为事件 ----------------

    fun reportEvent(type: String, detail: String) {
        val id = attemptId()
        if (id.isBlank()) return
        val now = System.currentTimeMillis()
        val last = lastEventAt[type] ?: 0L
        if (now - last < 1000) return
        lastEventAt[type] = now
        viewModelScope.launch {
            runCatching {
                repository.reportEvent(id, EventRequest(type, now.toString(), detail))
            }
        }
    }

    override fun onCleared() {
        stopTimers()
        debounceJobs.values.forEach { it.cancel() }
        super.onCleared()
    }

    private fun Throwable.userMessage(): String =
        (this as? ApiException)?.message ?: "操作失败，请稍后重试"
}

sealed interface ExamEvent {
    data class Toast(val message: String) : ExamEvent
    data object ConfirmSubmit : ExamEvent
    data class Submitted(val attemptId: String, val auto: Boolean) : ExamEvent
    data class NavigateResult(val attemptId: String) : ExamEvent
}
