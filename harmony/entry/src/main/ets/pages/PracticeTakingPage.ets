import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { repo } from '../common/repo/CandidateRepository';
import {
  PracticeRecord, Question, ExamOption, ExamRouteParams,
  PracticeAnswerRequest, PracticeVerdict
} from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { Formatters } from '../common/util/Formatters';
import { CardContainer, TagPill, LoadingView, ErrorBanner } from '../components/Common';
import { RichContent, htmlToText } from '../components/RichContent';

@Entry
@Component
struct PracticeTakingPage {
  @State record: PracticeRecord = {};
  @State questions: Question[] = [];
  @State index: number = 0;
  @State selected: string[] = [];
  @State hasVerdict: boolean = false;
  @State verdictCorrect: boolean = false;
  @State verdictExpected: string = '';
  @State verdictAnalysis: string = '';
  @State submitting: boolean = false;
  @State loading: boolean = true;
  @State error: string = '';

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    const params = router.getParams() as ExamRouteParams;
    try {
      this.record = await repo.practiceStart(params && params.setId ? params.setId : '');
      const list = this.record.questions ? this.record.questions : [];
      this.questions = list.length > 0 ? list : (this.record.question ? [this.record.question] : []);
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

  private choose(question: Question, key: string): void {
    if (this.hasVerdict) return;
    const next = this.selected.slice();
    if (this.resolvedType(question) === 'MULTIPLE') {
      const pos = next.indexOf(key);
      if (pos >= 0) next.splice(pos, 1); else next.push(key);
    } else {
      next.splice(0, next.length, key);
    }
    this.selected = next;
  }

  async submit(question: Question): Promise<void> {
    if (this.submitting || this.hasVerdict) return;
    const body: PracticeAnswerRequest = {
      questionId: question.questionId ? question.questionId : '',
      answerJson: JSON.stringify(this.selected)
    };
    this.submitting = true;
    try {
      const v = await repo.practiceAnswer(this.record.recordId ? this.record.recordId : '', body);
      this.verdictCorrect = v.correct === true;
      this.verdictExpected = v.expectedText ? v.expectedText : '';
      this.verdictAnalysis = v.analysis ? v.analysis : '';
      this.hasVerdict = true;
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message });
    } finally {
      this.submitting = false;
    }
  }

  async next(): Promise<void> {
    if (!this.hasVerdict) return;
    if (this.index < this.questions.length - 1) {
      this.index++;
      this.selected = [];
      this.hasVerdict = false;
      this.verdictCorrect = false;
      this.verdictExpected = '';
      this.verdictAnalysis = '';
    } else {
      try {
        await repo.practiceFinish(this.record.recordId ? this.record.recordId : '');
        promptAction.showToast({ message: '练习完成' });
        router.back();
      } catch (e) {
        promptAction.showToast({ message: (e as Error).message });
      }
    }
  }

  build() {
    Column() {
      if (this.loading) {
        LoadingView()
      } else if (this.error.length > 0) {
        ErrorBanner({ message: this.error }).margin(16)
      } else if (this.questions.length > this.index) {
        Row() {
          Text((this.record.title ? this.record.title : (this.record.setName ? this.record.setName : '练习')) + ' · 第 ' + (this.record.attemptNo ? this.record.attemptNo : 1) + ' 次')
            .fontSize(13).fontColor(Tokens.TEXT_SECONDARY)
          Blank()
          Text(String(this.record.answeredCount ? this.record.answeredCount : (this.index + 1)) + '/' +
            String(this.record.questionCount ? this.record.questionCount : this.questions.length) +
            ' · 对 ' + String(this.record.correctCount ? this.record.correctCount : 0) +
            ' / 错 ' + String(this.record.wrongCount ? this.record.wrongCount : 0))
            .fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
        }.width('100%').padding(16).backgroundColor(Tokens.PRIMARY_SOFT)

        Scroll() {
          Column({ space: 12 }) {
            this.card(this.questions[this.index])
            if (this.hasVerdict) {
              CardContainer() {
                Column({ space: 6 }) {
                  Text(this.verdictCorrect ? '回答正确' : '回答错误')
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.verdictCorrect ? Tokens.SUCCESS : Tokens.DANGER)
                  if (this.verdictExpected.length > 0) {
                    Text('正确答案：' + this.verdictExpected).fontSize(13).fontColor(Tokens.SUCCESS)
                  }
                  if (this.verdictAnalysis.length > 0) {
                    Column({ space: 4 }) {
                      Text('解析').fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
                      RichContent({ content: this.verdictAnalysis, fontSize: 13 })
                    }
                    .width('100%').padding(10).backgroundColor(Tokens.SURFACE_ALT).borderRadius(8)
                    .alignItems(HorizontalAlign.Start)
                  }
                }.alignItems(HorizontalAlign.Start).width('100%')
              }
            }
          }.padding(16)
        }.layoutWeight(1)

        Row({ space: 8 }) {
          Button('上一题')
            .height(44).backgroundColor(Tokens.SURFACE).fontColor(Tokens.PRIMARY)
            .enabled(this.index > 0 && !this.hasVerdict)
            .onClick(() => {
              if (this.index > 0) {
                this.index--;
                this.selected = [];
                this.hasVerdict = false;
                this.verdictCorrect = false;
                this.verdictExpected = '';
                this.verdictAnalysis = '';
              }
            })
          Blank()
          if (!this.hasVerdict) {
            Button(this.submitting ? '提交中…' : '提交本题')
              .height(44)
              .backgroundColor(this.selected.length > 0 ? Tokens.PRIMARY : '#9DBDD9')
              .fontColor('#FFFFFF')
              .enabled(!this.submitting && this.selected.length > 0)
              .onClick(() => { this.submit(this.questions[this.index]); })
          } else {
            Button(this.index < this.questions.length - 1 ? '下一题' : '完成')
              .height(44)
              .backgroundColor(this.index < this.questions.length - 1 ? Tokens.PRIMARY : Tokens.SUCCESS)
              .fontColor('#FFFFFF')
              .onClick(() => { this.next(); })
          }
        }.width('100%').padding(12).backgroundColor(Tokens.SURFACE)
      } else {
        Text('暂无题目').fontSize(14).fontColor(Tokens.TEXT_SECONDARY).padding(48)
      }
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }

  @Builder
  card(question: Question) {
    CardContainer() {
      Column({ space: 12 }) {
        Row({ space: 8 }) {
          TagPill({
            label: Formatters.questionTypeLabel(this.resolvedType(question)),
            fg: Tokens.typeColor(this.resolvedType(question)).fg,
            bg: Tokens.typeColor(this.resolvedType(question)).bg
          })
          Text(Formatters.scoreText(question.score) + ' 分').fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
        }.width('100%')
        RichContent({ content: question.stem ? question.stem : '', fontSize: 16 })
        Column({ space: 10 }) {
          ForEach(question.options ? question.options : [], (option: ExamOption) => {
            Row({ space: 10 }) {
              Text(option.key ? option.key : '')
                .fontSize(14).fontWeight(FontWeight.Bold)
                .fontColor(this.selected.indexOf(option.key ? option.key : '') >= 0 ? Tokens.PRIMARY : Tokens.TEXT_PRIMARY)
              Text(htmlToText(option.text ? option.text : option.content)).fontSize(15).layoutWeight(1)
            }
            .width('100%')
            .padding(12)
            .backgroundColor(this.selected.indexOf(option.key ? option.key : '') >= 0 ? Tokens.PRIMARY_SOFT : Tokens.SURFACE_ALT)
            .borderRadius(8)
            .onClick(() => { this.choose(question, option.key ? option.key : ''); })
          }, (option: ExamOption, i: number) => i.toString())
        }.width('100%')
      }.alignItems(HorizontalAlign.Start).width('100%')
    }
  }
}
