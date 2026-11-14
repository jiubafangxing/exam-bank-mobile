import router from '@ohos.router';
import { repo } from '../common/repo/CandidateRepository';
import { SubmitResult, ExamRouteParams } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { Formatters } from '../common/util/Formatters';
import {
  CardContainer, TagPill, LoadingView, ErrorBanner, KeyValueRow, DividerLine
} from '../components/Common';

@Entry
@Component
struct ResultPage {
  @State result: SubmitResult = {};
  @State loading: boolean = true;
  @State error: string = '';

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    const params = router.getParams() as ExamRouteParams;
    try {
      this.result = await repo.result(params && params.attemptId ? params.attemptId : '');
      this.error = '';
    } catch (e) {
      this.error = (e as Error).message;
    } finally {
      this.loading = false;
    }
  }

  build() {
    Column() {
      if (this.loading) {
        LoadingView()
      } else if (this.error.length > 0) {
        Column() { ErrorBanner({ message: this.error }) }.margin(16)
      } else {
        Scroll() {
          Column({ space: 16 }) {
            CardContainer() {
              Column({ space: 8 }) {
                Text(Formatters.scoreText(this.result.totalScore))
                  .fontSize(44).fontWeight(FontWeight.Bold).fontColor(Tokens.PRIMARY)
                Text('总分').fontSize(13).fontColor(Tokens.TEXT_SECONDARY)
                if (this.result.isPassed === true) {
                  TagPill({ label: '已通过', fg: Tokens.SUCCESS, bg: Tokens.SUCCESS_SOFT })
                } else if (this.result.isPassed === false) {
                  TagPill({ label: '未通过', fg: Tokens.DANGER, bg: Tokens.DANGER_SOFT })
                } else {
                  TagPill({ label: '主观题阅卷中', fg: Tokens.WARNING, bg: Tokens.WARNING_SOFT })
                }
              }.width('100%').alignItems(HorizontalAlign.Center)

              DividerLine().margin({ top: 12, bottom: 12 })
              KeyValueRow({ label: '客观题', value: Formatters.scoreText(this.result.objectiveScore) + ' / ' + Formatters.scoreText(this.result.objectiveTotal) })
              KeyValueRow({ label: '主观题', value: Formatters.scoreText(this.result.subjectiveScore) + ' / ' + Formatters.scoreText(this.result.subjectiveTotal) })
              KeyValueRow({ label: '答对', value: String(this.result.correctCount ? this.result.correctCount : 0) + ' 题' })
              KeyValueRow({ label: '答错', value: String(this.result.wrongCount ? this.result.wrongCount : 0) + ' 题' })
              KeyValueRow({ label: '待阅', value: String(this.result.pendingCount ? this.result.pendingCount : 0) + ' 题' })
            }

            Button('查看解析')
              .width('100%').height(48).borderRadius(999).backgroundColor(Tokens.PRIMARY)
              .onClick(() => {
                router.pushUrl({ url: 'pages/ReviewPage', params: { attemptId: this.result.attemptId } });
              })
            Button('返回首页')
              .width('100%').height(48).borderRadius(999).backgroundColor(Tokens.SURFACE).fontColor(Tokens.PRIMARY)
              .onClick(() => { router.replaceUrl({ url: 'pages/Index' }); })
          }.padding(16)
        }.layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }
}
