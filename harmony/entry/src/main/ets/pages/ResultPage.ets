import router from '@ohos.router';
import { repo } from '../common/repo/CandidateRepository';
import { SubmitResult, ExamRouteParams } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { Formatters } from '../common/util/Formatters';
import {
  CardContainer, TagPill, LoadingView, ErrorBanner, KeyValueRow, DividerLine,
  PrimaryButton, SecondaryButton
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

  private totalScore(): number {
    const total = (this.result.objectiveTotal ? this.result.objectiveTotal : 0)
      + (this.result.subjectiveTotal ? this.result.subjectiveTotal : 0);
    return total > 0 ? total : 0;
  }

  private fraction(): number {
    const total = this.totalScore();
    if (total <= 0) return 0;
    const score = this.result.totalScore ? this.result.totalScore : 0;
    const ratio = score / total;
    if (ratio < 0) return 0;
    if (ratio > 1) return 1;
    return ratio;
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
              Column() {
                Stack({ alignContent: Alignment.Center }) {
                  Progress({
                    value: this.fraction() * 100,
                    total: 100,
                    type: ProgressType.Ring
                  })
                    .width(150).height(150)
                    .color(Tokens.PRIMARY)
                    .backgroundColor(Tokens.PRIMARY_SOFT)
                    .style({ strokeWidth: 11 })
                  Column({ space: 2 }) {
                    Text(Formatters.scoreText(this.result.totalScore))
                      .fontSize(44).fontWeight(FontWeight.Bold).fontColor(Tokens.PRIMARY_DEEP)
                    Text('总分').fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
                  }
                }
                .width(150).height(150)
                .margin({ top: 6 })

                if (this.result.isPassed === true) {
                  TagPill({ label: '考试通过', fg: Tokens.SUCCESS, bg: Tokens.SUCCESS_SOFT })
                    .margin({ top: 12 })
                } else if (this.result.isPassed === false) {
                  TagPill({ label: '未通过', fg: Tokens.DANGER, bg: Tokens.DANGER_SOFT })
                    .margin({ top: 12 })
                } else {
                  TagPill({ label: '主观题阅卷中', fg: Tokens.WARNING, bg: Tokens.WARNING_SOFT })
                    .margin({ top: 12 })
                }
                Text('满分 ' + Formatters.scoreText(this.totalScore()))
                  .fontSize(12).fontColor(Tokens.TEXT_TERTIARY).margin({ top: 6 })

                DividerLine().margin({ top: 14, bottom: 10 })
                KeyValueRow({ label: '客观题', value: Formatters.scoreText(this.result.objectiveScore) + ' / ' + Formatters.scoreText(this.result.objectiveTotal) })
                KeyValueRow({ label: '主观题', value: Formatters.scoreText(this.result.subjectiveScore) + ' / ' + Formatters.scoreText(this.result.subjectiveTotal) })
                KeyValueRow({ label: '答对', value: String(this.result.correctCount ? this.result.correctCount : 0) + ' 题' })
                KeyValueRow({ label: '答错', value: String(this.result.wrongCount ? this.result.wrongCount : 0) + ' 题' })
                KeyValueRow({ label: '待阅', value: String(this.result.pendingCount ? this.result.pendingCount : 0) + ' 题' })
                KeyValueRow({ label: '交卷方式', value: this.result.auto === true ? '超时自动交卷' : '手动交卷' })
                if (this.result.submittedAt && this.result.submittedAt.length > 0) {
                  KeyValueRow({ label: '交卷时间', value: this.result.submittedAt })
                }
              }.width('100%')
            }

            PrimaryButton({
              label: '查看解析',
              onTap: () => {
                router.pushUrl({ url: 'pages/ReviewPage', params: { attemptId: this.result.attemptId } });
              }
            })
            SecondaryButton({
              label: '返回首页',
              onTap: () => { router.replaceUrl({ url: 'pages/Index' }); }
            })
          }.padding(16)
        }.layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }
}
