import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { repo } from '../common/repo/CandidateRepository';
import {
  AttemptState, Question, ExamOption, SaveAnswerRequest, ExamRouteParams
} from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { Formatters } from '../common/util/Formatters';
import {
  CardContainer, TagPill, LoadingView, ErrorBanner
} from '../components/Common';
import { RichContent, htmlToText } from '../components/RichContent';

@Entry
@Component
struct ExamTakingPage {
  @State attempt: AttemptState = {};
  @State questions: Question[] = [];
  @State currentIndex: number = 0;
  @State remaining: number = 0;
  @State answerJsons: string[] = [];
  @State answerTexts: string[] = [];
  @State flags: boolean[] = [];
  @State fillValues: string[][] = [];
  @State saveStatuses: string[] = [];
  @State loaded: boolean = false;
  @State error: string = '';
  @State submitting: boolean = false;
  @State showSheet: boolean = false;

  private countdownId: number = -1;
  private heartbeatId: number = -1;
  private debounceIds: number[] = [];
  private localDeadline: number = 0;
  private autoSubmitting: boolean = false;
  private lastEventAt: number = 0;

  aboutToAppear(): void {
    this.load();
  }

  aboutToDisappear(): void {
    this.stopTimers();
    this.reportEvent('APP_SWITCH');
  }

  async load(): Promise<void> {
    const params = router.getParams() as ExamRouteParams;
    const examId = params && params.examId ? params.examId : '';
    try {
      const data = await repo.startExam(examId);
      this.applyState(data);
      if (data.status === 'SUBMITTED' || data.status === 'GRADED') {
        router.replaceUrl({ url: 'pages/ResultPage', params: { attemptId: data.attemptId } });
        return;
      }
      this.loaded = true;
      this.startTimers();
      this.reportEvent('FOCUS');
    } catch (e) {
      this.error = (e as Error).message;
      this.loaded = true;
    }
  }

  private applyState(data: AttemptState): void {
    this.attempt = data;
    const qs = data.questions ? data.questions : [];
    this.questions = qs;

    const js: string[] = [];
    const ts: string[] = [];
    const fs: boolean[] = [];
    const st: string[] = [];
    const fv: string[][] = [];
    for (let i = 0; i < qs.length; i++) {
      js.push('');
      ts.push('');
      fs.push(false);
      st.push('pending');
      const blanks = qs[i].blanks ? qs[i].blanks as number : 1;
      const row: string[] = [];
      for (let b = 0; b < Math.max(blanks, 1); b++) row.push('');
      fv.push(row);
    }

    const answers = data.answers ? data.answers : [];
    for (let a = 0; a < answers.length; a++) {
      const item = answers[a];
      let index = -1;
      for (let i = 0; i < qs.length; i++) {
        if (qs[i].paperQuestionId === item.paperQuestionId) { index = i; break; }
      }
      if (index < 0) continue;
      js[index] = item.answerJson ? item.answerJson : '';
      ts[index] = item.answerText ? item.answerText : '';
      fs[index] = item.flagged === true;
      st[index] = 'saved';
      if (qs[index].type === 'FILL' && item.answerJson) {
        try {
          const arr = JSON.parse(item.answerJson) as string[];
          for (let k = 0; k < arr.length && k < fv[index].length; k++) fv[index][k] = arr[k];
        } catch (e) {
          // ignore
        }
      }
    }

    this.answerJsons = js;
    this.answerTexts = ts;
    this.flags = fs;
    this.saveStatuses = st;
    this.fillValues = fv;

    const deadline = Number(data.deadlineEpochMillis ? data.deadlineEpochMillis : '0');
    const server = Number(data.serverEpochMillis ? data.serverEpochMillis : '0');
    this.remaining = Math.max(Math.floor((deadline - server) / 1000), 0);
  }

  private startTimers(): void {
    this.stopTimers();
    this.localDeadline = Date.now() + this.remaining * 1000;
    this.countdownId = setInterval(() => {
      const remain = Math.floor((this.localDeadline - Date.now()) / 1000);
      this.remaining = Math.max(remain, 0);
      if (remain <= 0 && !this.autoSubmitting) {
        this.autoSubmitting = true;
        this.doSubmit(true);
      }
    }, 1000);
    this.heartbeatId = setInterval(async () => {
      try {
        const hb = await repo.heartbeat(this.attempt.attemptId ? this.attempt.attemptId : '');
        this.remaining = hb.remainingSeconds ? hb.remainingSeconds : this.remaining;
        this.localDeadline = Date.now() + (hb.remainingSeconds ? hb.remainingSeconds : 0) * 1000;
      } catch (e) {
        // ignore heartbeat failure
      }
    }, 30000);
  }

  private stopTimers(): void {
    if (this.countdownId >= 0) { clearInterval(this.countdownId); this.countdownId = -1; }
    if (this.heartbeatId >= 0) { clearInterval(this.heartbeatId); this.heartbeatId = -1; }
  }

  private selectedKeys(index: number): string[] {
    const raw = this.answerJsons[index];
    if (!raw) return [];
    try {
      return JSON.parse(raw) as string[];
    } catch (e) {
      return [];
    }
  }

  private isSelected(index: number, key: string): boolean {
    return this.selectedKeys(index).indexOf(key) >= 0;
  }

  private choose(index: number, question: Question, key: string): void {
    let keys = this.selectedKeys(index);
    if (question.type === 'MULTIPLE') {
      const pos = keys.indexOf(key);
      if (pos >= 0) keys.splice(pos, 1); else keys.push(key);
    } else {
      keys = [key];
    }
    const arr = this.answerJsons.slice();
    arr[index] = JSON.stringify(keys);
    this.answerJsons = arr;
    this.queueSave(index);
  }

  private updateFill(index: number, blank: number, value: string): void {
    const all = this.fillValues.slice();
    const row = all[index].slice();
    row[blank] = value;
    all[index] = row;
    this.fillValues = all;
    const arr = this.answerJsons.slice();
    arr[index] = JSON.stringify(row);
    this.answerJsons = arr;
    this.queueSave(index);
  }

  private updateEssay(index: number, text: string): void {
    const arr = this.answerTexts.slice();
    arr[index] = text;
    this.answerTexts = arr;
    this.queueSave(index);
  }

  private toggleFlag(index: number): void {
    const arr = this.flags.slice();
    arr[index] = !arr[index];
    this.flags = arr;
    this.queueSave(index);
  }

  private queueSave(index: number): void {
    const st = this.saveStatuses.slice();
    st[index] = 'pending';
    this.saveStatuses = st;
    if (this.debounceIds[index]) clearTimeout(this.debounceIds[index]);
    this.debounceIds[index] = setTimeout(() => { this.saveNow(index); }, 500);
  }

  private async saveNow(index: number): Promise<void> {
    const question = this.questions[index];
    if (!question) return;
    const st = this.saveStatuses.slice();
    st[index] = 'saving';
    this.saveStatuses = st;
    const body: SaveAnswerRequest = {
      answerJson: this.answerJsons[index] ? this.answerJsons[index] : undefined,
      answerText: this.answerTexts[index] ? this.answerTexts[index] : undefined,
      flagged: this.flags[index] === true
    };
    try {
      await repo.saveAnswer(
        this.attempt.attemptId ? this.attempt.attemptId : '',
        question.paperQuestionId ? question.paperQuestionId : '',
        body
      );
      const done = this.saveStatuses.slice();
      done[index] = 'saved';
      this.saveStatuses = done;
    } catch (e) {
      const failed = this.saveStatuses.slice();
      failed[index] = 'error';
      this.saveStatuses = failed;
    }
  }

  private async flushAll(): Promise<void> {
    for (let i = 0; i < this.questions.length; i++) {
      if (this.saveStatuses[i] !== 'saved') {
        await this.saveNow(i);
      }
    }
  }

  private confirmSubmit(): void {
    AlertDialog.show({
      title: '交卷确认',
      message: '交卷后不可再修改答案，确认交卷？',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '确认交卷',
        action: () => { this.doSubmit(false); }
      }
    });
  }

  private async doSubmit(auto: boolean): Promise<void> {
    if (this.submitting) return;
    this.submitting = true;
    try {
      for (let i = 0; i < this.debounceIds.length; i++) {
        if (this.debounceIds[i]) clearTimeout(this.debounceIds[i]);
      }
      await this.flushAll();
      await repo.submit(this.attempt.attemptId ? this.attempt.attemptId : '');
      this.stopTimers();
      promptAction.showToast({ message: auto ? '时间到，已自动交卷' : '交卷成功' });
      router.replaceUrl({ url: 'pages/ResultPage', params: { attemptId: this.attempt.attemptId } });
    } catch (e) {
      this.autoSubmitting = false;
      promptAction.showToast({ message: '交卷失败，请重试：' + (e as Error).message });
    } finally {
      this.submitting = false;
    }
  }

  private reportEvent(type: string): void {
    const now = Date.now();
    if (now - this.lastEventAt < 1000) return;
    this.lastEventAt = now;
    repo.reportEvent(this.attempt.attemptId ? this.attempt.attemptId : '', {
      eventType: type,
      clientTime: String(now),
      detail: 'harmony'
    }).catch((e: Error) => {});
  }

  private resolvedType(question: Question): string {
    if (question.type && question.type.length > 0) return question.type;
    return question.typeCode ? question.typeCode : '';
  }

  private saveStatusText(index: number): string {
    switch (this.saveStatuses[index]) {
      case 'saving': return '保存中';
      case 'saved': return '已保存';
      case 'error': return '保存失败';
      default: return '待保存';
    }
  }

  private answeredCount(): number {
    let count = 0;
    for (let i = 0; i < this.questions.length; i++) {
      const q = this.questions[i];
      if (q.type === 'ESSAY') {
        if (this.answerTexts[i] && this.answerTexts[i].length > 0) count++;
      } else if (q.type === 'FILL') {
        const row = this.fillValues[i];
        let has = false;
        for (let b = 0; b < row.length; b++) { if (row[b]) has = true; }
        if (has) count++;
      } else if (this.selectedKeys(i).length > 0) {
        count++;
      }
    }
    return count;
  }

  build() {
    Stack() {
      Column() {
        if (!this.loaded) {
          LoadingView()
        } else if (this.error.length > 0) {
          Column() { ErrorBanner({ message: this.error }) }.margin(16)
        } else {
          Row() {
            Text('第 ' + (this.currentIndex + 1) + ' / ' + this.questions.length + ' 题').fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
            Blank()
            Text('已答 ' + this.answeredCount()).fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
            Blank()
            Text(Formatters.countdown(this.remaining))
              .fontSize(15).fontWeight(FontWeight.Bold)
              .fontColor(this.remaining <= 300 ? Tokens.DANGER : Tokens.PRIMARY)
          }
          .width('100%')
          .padding(12)
          .backgroundColor(Tokens.PRIMARY_SOFT)

          Scroll() {
            Column() {
              if (this.questions.length > this.currentIndex) {
                this.questionCard(this.currentIndex, this.questions[this.currentIndex])
              }
            }.padding(16)
          }.layoutWeight(1)

          Row({ space: 8 }) {
            Button('上一题')
              .height(44).fontSize(13).backgroundColor(Tokens.SURFACE).fontColor(Tokens.PRIMARY)
              .enabled(this.currentIndex > 0)
              .onClick(() => { if (this.currentIndex > 0) this.currentIndex--; })
            Button('答题卡')
              .height(44).fontSize(13).backgroundColor(Tokens.SURFACE).fontColor(Tokens.PRIMARY)
              .onClick(() => { this.showSheet = true; })
            Blank()
            if (this.currentIndex < this.questions.length - 1) {
              Button('下一题')
                .height(44).fontSize(13).backgroundColor(Tokens.PRIMARY).fontColor('#FFFFFF')
                .onClick(() => { this.currentIndex++; })
            } else {
              Button('交卷')
                .height(44).fontSize(13).backgroundColor(Tokens.SUCCESS).fontColor('#FFFFFF')
                .enabled(!this.submitting)
                .onClick(() => { this.confirmSubmit(); })
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor(Tokens.SURFACE)
        }
      }
      .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)

      if (this.showSheet) {
        Column() {
          Blank().onClick(() => { this.showSheet = false; })
          Column({ space: 12 }) {
            Text('答题卡').fontSize(17).fontWeight(FontWeight.Bold)
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(this.questions, (q: Question, index: number) => {
                Text(String(index + 1))
                  .width(48).height(42).textAlign(TextAlign.Center)
                  .margin(4)
                  .fontSize(14)
                  .fontColor(index === this.currentIndex ? Tokens.PRIMARY : Tokens.TEXT_PRIMARY)
                  .backgroundColor(this.saveStatuses[index] === 'saved' ? Tokens.PRIMARY_SOFT : Tokens.SURFACE)
                  .borderRadius(8)
                  .onClick(() => { this.currentIndex = index; this.showSheet = false; })
              }, (q: Question, index: number) => index.toString())
            }.width('100%')
            Button('交卷').width('100%').height(46).backgroundColor(Tokens.SUCCESS).fontColor('#FFFFFF')
              .onClick(() => { this.showSheet = false; this.confirmSubmit(); })
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Tokens.SURFACE)
          .borderRadius({ topLeft: 20, topRight: 20 })
        }
        .width('100%').height('100%')
        .backgroundColor('#66000000')
      }
    }
    .width('100%').height('100%')
  }

  @Builder
  questionCard(index: number, question: Question) {
    CardContainer() {
      Column({ space: 12 }) {
        Row({ space: 8 }) {
          Text('第 ' + (question.sortNo ? question.sortNo : 0) + ' 题').fontSize(15).fontWeight(FontWeight.Bold)
          TagPill({
            label: Formatters.questionTypeLabel(resolvedType(question)),
            fg: Tokens.typeColor(resolvedType(question)).fg,
            bg: Tokens.typeColor(resolvedType(question)).bg
          })
          Blank()
          Text(this.saveStatusText(index)).fontSize(11).fontColor(Tokens.TEXT_TERTIARY)
          Text('标记')
            .fontSize(12)
            .fontColor(this.flags[index] ? Tokens.WARNING : Tokens.TEXT_SECONDARY)
            .onClick(() => { this.toggleFlag(index); })
        }.width('100%')

        RichContent({ content: question.stem ? question.stem : '', fontSize: 16 })

        if (resolvedType(question) === 'FILL') {
          Column({ space: 8 }) {
            ForEach(this.fillValues[index], (value: string, blank: number) => {
              TextInput({ placeholder: '第' + (blank + 1) + '空', text: value })
                .width('100%').height(44).backgroundColor(Tokens.SURFACE_ALT).borderRadius(8)
                .onChange((v: string) => { this.updateFill(index, blank, v); })
            }, (value: string, blank: number) => blank.toString())
          }.width('100%')
        } else if (resolvedType(question) === 'ESSAY') {
          TextArea({ placeholder: '请输入作答内容', text: this.answerTexts[index] })
            .width('100%').height(150).backgroundColor(Tokens.SURFACE_ALT).borderRadius(8)
            .onChange((v: string) => { this.updateEssay(index, v); })
        } else {
          Column({ space: 10 }) {
            ForEach(question.options ? question.options : [], (option: ExamOption) => {
              Row({ space: 10 }) {
                Text(option.key ? option.key : '')
                  .fontSize(12)
                  .fontColor(this.isSelected(index, option.key ? option.key : '') ? '#FFFFFF' : Tokens.TEXT_PRIMARY)
                  .width(24).height(24).textAlign(TextAlign.Center)
                  .backgroundColor(this.isSelected(index, option.key ? option.key : '') ? Tokens.PRIMARY : Tokens.SURFACE_ALT)
                  .borderRadius(12)
                Text(htmlToText(option.text ? option.text : option.content)).fontSize(15).fontColor(Tokens.TEXT_PRIMARY).layoutWeight(1)
              }
              .width('100%')
              .padding(12)
              .backgroundColor(this.isSelected(index, option.key ? option.key : '') ? Tokens.PRIMARY_SOFT : Tokens.SURFACE)
              .borderRadius(8)
              .border({
                width: 1,
                color: this.isSelected(index, option.key ? option.key : '') ? Tokens.PRIMARY : Tokens.BORDER
              })
              .onClick(() => { this.choose(index, question, option.key ? option.key : ''); })
            }, (option: ExamOption, i: number) => i.toString())
          }.width('100%')
        }
      }.alignItems(HorizontalAlign.Start).width('100%')
    }
  }
}
