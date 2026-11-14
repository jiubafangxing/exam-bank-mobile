import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { repo } from '../common/repo/CandidateRepository';
import {
  PracticeRecord, Question, ExamOption, ExamRouteParams,
  PracticeAnswerRequest, PracticeVerdict
} from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { Formatters } from '../common/util/Formatters';
import {
  CardContainer, TagPill, LoadingView, ErrorBanner,
  PrimaryButton, SecondaryButton
} from '../components/Common';
import { RichContent, htmlToText } from '../components/RichContent';

@Entry
@Component
struct PracticeTakingPage {
  @State record: PracticeRecord = {};
  @State questions: Question[] = [];
  @State index: number = 0;
  @State selected: string[] = [];
  @State fillInputs: string[] = [];
  @State essayText: string = '';
  @State hasVerdict: boolean = false;
  @State verdictCorrect: boolean = false;
  @State expectedText: string = '';
  @State expectedKeys: string[] = [];
  @State verdictAnalysis: string = '';
  @State answeredCount: number = 0;
  @State correctCount: number = 0;
  @State wrongCount: number = 0;
  @State submitting: boolean = false;
  @State loading: boolean = true;
  @State error: string = '';

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    this.loading = true;
    const params = router.getParams() as ExamRouteParams;
    const recordId = params && params.recordId ? params.recordId : '';
    const setId = params && params.setId ? params.setId : '';
    try {
      let data: PracticeRecord = {};
      if (recordId.length > 0) {
        data = await repo.practiceState(recordId);
      } else {
        data = await repo.practiceStart(setId);
      }
      this.record = data;
      const list = data.questions ? data.questions : [];
      this.questions = list.length > 0 ? list : (data.question ? [data.question] : []);
      this.answeredCount = data.answeredCount ? data.answeredCount : 0;
      this.correctCount = data.correctCount ? data.correctCount : 0;
      this.wrongCount = data.wrongCount ? data.wrongCount : 0;
      const start = data.currentIndex ? data.currentIndex : 0;
      this.index = start >= 0 && start < this.questions.length ? start : 0;
      this.resetCurrent();
      this.error = '';
    } catch (e) {
      this.error = (e as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private resolvedType(question: Question): string {
    if (question.type && question.type.length > 0) return question.type;
    return question.typeCode ? question.typeCode : '';
  }

  private isChoice(question: Question): boolean {
    const type = this.resolvedType(question).toUpperCase();
    if (type === 'SINGLE' || type === 'MULTIPLE' || type === 'JUDGE') return true;
    return question.options ? question.options.length > 0 : false;
  }

  private blankCount(question: Question): number {
    const blanks = question.blanks ? question.blanks : 0;
    return blanks > 0 ? blanks : 1;
  }

  private resetCurrent(): void {
    this.selected = [];
    this.essayText = '';
    this.hasVerdict = false;
    this.verdictCorrect = false;
    this.expectedText = '';
    this.expectedKeys = [];
    this.verdictAnalysis = '';
    let count = 1;
    if (this.questions.length > this.index) {
      count = this.blankCount(this.questions[this.index]);
    }
    const values: string[] = [];
    for (let i = 0; i < count; i++) values.push('');
    this.fillInputs = values;
  }

  private choose(question: Question, key: string): void {
    if (this.hasVerdict) return;
    const next = this.selected.slice();
    if (this.resolvedType(question).toUpperCase() === 'MULTIPLE') {
      const pos = next.indexOf(key);
      if (pos >= 0) next.splice(pos, 1); else next.push(key);
    } else {
      next.splice(0, next.length, key);
    }
    this.selected = next;
  }

  private updateFill(blank: number, value: string): void {
    const next = this.fillInputs.slice();
    while (next.length <= blank) next.push('');
    next[blank] = value;
    this.fillInputs = next;
  }

  private hasAnyAnswer(): boolean {
    if (this.selected.length > 0) return true;
    for (let i = 0; i < this.fillInputs.length; i++) {
      if (this.fillInputs[i].length > 0) return true;
    }
    return this.essayText.length > 0;
  }

  private async submitCurrent(): Promise<void> {
    if (this.submitting || this.hasVerdict) return;
    if (this.questions.length <= this.index) return;
    if (!this.hasAnyAnswer()) {
      promptAction.showToast({ message: '请先作答本题' });
      return;
    }
    const question = this.questions[this.index];
    const type = this.resolvedType(question).toUpperCase();
    let answerJson: string = '';
    let answerText: string = '';
    if (this.isChoice(question) && (question.options ? question.options.length > 0 : false)) {
      answerJson = JSON.stringify(this.selected);
    } else if (type === 'FILL') {
      answerJson = JSON.stringify(this.fillInputs);
    } else if (type === 'ESSAY') {
      answerText = this.essayText;
    } else {
      answerJson = JSON.stringify(this.selected);
    }
    const body: PracticeAnswerRequest = {
      questionId: question.questionId ? question.questionId : (question.paperQuestionId ? question.paperQuestionId : ''),
      answerJson: answerJson.length > 0 ? answerJson : undefined,
      answerText: answerText.length > 0 ? answerText : undefined
    };
    this.submitting = true;
    try {
      const v: PracticeVerdict = await repo.practiceAnswer(this.record.recordId ? this.record.recordId : '', body);
      this.verdictCorrect = v.correct === true;
      this.expectedText = v.expectedText ? v.expectedText : (v.expected ? v.expected.join(' / ') : '');
      const keys = v.expectedKeys ? v.expectedKeys : [];
      const normalized: string[] = [];
      for (let i = 0; i < keys.length; i++) normalized.push(keys[i].toUpperCase());
      this.expectedKeys = normalized;
      this.verdictAnalysis = v.analysis ? v.analysis : '';
      this.answeredCount = v.answeredCount !== undefined ? v.answeredCount : this.answeredCount + 1;
      this.correctCount = v.correctCount !== undefined
        ? v.correctCount : this.correctCount + (v.correct === true ? 1 : 0);
      this.wrongCount = v.wrongCount !== undefined
        ? v.wrongCount : this.wrongCount + (v.correct === false ? 1 : 0);
      this.hasVerdict = true;
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message });
    } finally {
      this.submitting = false;
    }
  }

  private goPrevious(): void {
    if (this.index > 0 && !this.hasVerdict) {
      this.index--;
      this.resetCurrent();
    }
  }

  private goNext(): void {
    if (!this.hasVerdict) return;
    if (this.index < this.questions.length - 1) {
      this.index++;
      this.resetCurrent();
    } else {
      this.showDone();
    }
  }

  private showDone(): void {
    const total = this.record.questionCount ? this.record.questionCount : this.questions.length;
    AlertDialog.show({
      title: '练习完成',
      message: '已完成 ' + this.answeredCount + '/' + total + ' 题\n正确 ' + this.correctCount + ' 题 · 错误 ' + this.wrongCount + ' 题',
      primaryButton: {
        value: '留在当前',
        action: () => {}
      },
      secondaryButton: {
        value: '结束并退出',
        action: () => { this.finishAndExit(); }
      }
    });
  }

  private async finishAndExit(): Promise<void> {
    try {
      await repo.practiceFinish(this.record.recordId ? this.record.recordId : '');
      promptAction.showToast({ message: '练习完成' });
      router.back();
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message });
    }
  }

  private isCorrectKey(key: string): boolean {
    return this.hasVerdict && this.expectedKeys.indexOf(key.toUpperCase()) >= 0;
  }

  build() {
    Column() {
      if (this.loading) {
        LoadingView()
      } else if (this.error.length > 0) {
        Column({ space: 12 }) {
          ErrorBanner({ message: this.error })
          SecondaryButton({ label: '重试', onTap: () => { this.load(); } })
        }.padding(16)
      } else if (this.questions.length > this.index) {
        this.headerBar()
        Scroll() {
          Column({ space: 12 }) {
            this.questionCard(this.questions[this.index])
            if (this.hasVerdict) {
              this.verdictCard()
            }
          }.padding(16)
        }.layoutWeight(1)

        Row({ space: 10 }) {
          SecondaryButton({
            label: '上一题',
            isEnabled: this.index > 0 && !this.hasVerdict,
            onTap: () => { this.goPrevious(); }
          })
          Column() {
            PrimaryButton({
              label: this.hasVerdict
                ? (this.index < this.questions.length - 1 ? '下一题' : '完成练习')
                : (this.submitting ? '提交中…' : '提交本题'),
              isEnabled: this.hasVerdict || (!this.submitting && this.hasAnyAnswer()),
              loading: this.submitting,
              onTap: () => {
                if (this.hasVerdict) {
                  this.goNext();
                } else {
                  this.submitCurrent();
                }
              }
            })
          }.layoutWeight(1)
        }
        .width('100%')
        .padding(12)
        .backgroundColor(Tokens.SURFACE)
      } else {
        Text('暂无题目').fontSize(14).fontColor(Tokens.TEXT_SECONDARY).padding(48)
      }
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }

  @Builder
  headerBar() {
    Column({ space: 6 }) {
      Row() {
        Text(this.record.title ? this.record.title : (this.record.setName ? this.record.setName : '练习'))
          .fontSize(15).fontWeight(FontWeight.Bold).fontColor(Tokens.TEXT_PRIMARY)
          .layoutWeight(1).maxLines(1)
        Text('第 ' + String(this.index + 1) + ' / ' + String(this.questions.length) + ' 题')
          .fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
      }.width('100%')
      Row({ space: 6 }) {
        TagPill({ label: '已答 ' + this.answeredCount, fg: Tokens.PRIMARY, bg: Tokens.PRIMARY_SOFT })
        TagPill({ label: '正确 ' + this.correctCount, fg: Tokens.SUCCESS, bg: Tokens.SUCCESS_SOFT })
        TagPill({ label: '错误 ' + this.wrongCount, fg: Tokens.DANGER, bg: Tokens.DANGER_SOFT })
        Blank()
        Text('第 ' + String(this.record.attemptNo ? this.record.attemptNo : 1) + ' 次练习')
          .fontSize(11).fontColor(Tokens.TEXT_SECONDARY)
      }.width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .backgroundColor(Tokens.SURFACE)
  }

  @Builder
  questionCard(question: Question) {
    CardContainer() {
      Column({ space: 12 }) {
        Row({ space: 8 }) {
          TagPill({
            label: Formatters.questionTypeLabel(this.resolvedType(question)),
            fg: Tokens.typeColor(this.resolvedType(question)).fg,
            bg: Tokens.typeColor(this.resolvedType(question)).bg
          })
          Text(Formatters.scoreText(question.score) + ' 分').fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
          Blank()
          Text(this.hasVerdict ? '已判定' : '待作答')
            .fontSize(11).fontColor(this.hasVerdict ? Tokens.TEXT_TERTIARY : Tokens.PRIMARY)
        }.width('100%')

        RichContent({ content: question.stem ? question.stem : '', fontSize: 16 })

        if (this.isChoice(question)) {
          Column({ space: 8 }) {
            ForEach(question.options ? question.options : [], (option: ExamOption, i: number) => {
              Row({ space: 10 }) {
                Text(option.key ? option.key : '')
                  .fontSize(12).fontWeight(FontWeight.Bold)
                  .fontColor(this.isCorrectKey(option.key ? option.key : '') || this.selected.indexOf(option.key ? option.key : '') >= 0
                    ? '#FFFFFF' : Tokens.TEXT_SECONDARY)
                  .width(26).height(26).textAlign(TextAlign.Center)
                  .backgroundColor(this.isCorrectKey(option.key ? option.key : '') ? Tokens.SUCCESS
                    : (this.selected.indexOf(option.key ? option.key : '') >= 0 ? Tokens.PRIMARY : Tokens.SURFACE))
                  .borderRadius(13)
                Text(htmlToText(option.text ? option.text : option.content)).fontSize(15)
                  .fontColor(Tokens.TEXT_PRIMARY).layoutWeight(1)
              }
              .width('100%')
              .padding(12)
              .backgroundColor(this.isCorrectKey(option.key ? option.key : '') ? Tokens.SUCCESS_SOFT
                : (this.selected.indexOf(option.key ? option.key : '') >= 0 ? Tokens.PRIMARY_SOFT : Tokens.SURFACE_ALT))
              .borderRadius(Tokens.RADIUS_MD)
              .onClick(() => { this.choose(question, option.key ? option.key : ''); })
            }, (option: ExamOption, i: number) => i.toString())
          }.width('100%')
        } else if (this.resolvedType(question).toUpperCase() === 'FILL') {
          Column({ space: 10 }) {
            ForEach(this.fillInputs, (value: string, blank: number) => {
              TextInput({ placeholder: '第 ' + String(blank + 1) + ' 空', text: value })
                .width('100%').height(46)
                .backgroundColor(Tokens.SURFACE_ALT)
                .borderRadius(Tokens.RADIUS_MD)
                .enabled(!this.hasVerdict)
                .onChange((v: string) => { this.updateFill(blank, v); })
            }, (value: string, blank: number) => blank.toString())
          }.width('100%')
        } else {
          TextArea({ placeholder: '请输入作答内容', text: this.essayText })
            .width('100%').height(160)
            .backgroundColor(Tokens.SURFACE_ALT)
            .borderRadius(Tokens.RADIUS_MD)
            .enabled(!this.hasVerdict)
            .onChange((v: string) => { this.essayText = v; })
        }
      }.alignItems(HorizontalAlign.Start).width('100%')
    }
  }

  @Builder
  verdictCard() {
    Column({ space: 8 }) {
      Text(this.verdictCorrect ? '回答正确' : '回答错误')
        .fontSize(15).fontWeight(FontWeight.Bold)
        .fontColor(this.verdictCorrect ? Tokens.SUCCESS : Tokens.DANGER)
      if (this.expectedText.length > 0) {
        Text('正确答案：' + this.expectedText).fontSize(13).fontColor(Tokens.SUCCESS)
      }
      if (this.verdictAnalysis.length > 0) {
        Column({ space: 4 }) {
          Text('解析').fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
          RichContent({ content: this.verdictAnalysis, fontSize: 13 })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(12)
        .backgroundColor(Tokens.SURFACE_ALT)
        .borderRadius(Tokens.RADIUS_MD)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(14)
    .backgroundColor(this.verdictCorrect ? Tokens.SUCCESS_SOFT : Tokens.DANGER_SOFT)
    .borderRadius(Tokens.RADIUS_LG)
  }
}
