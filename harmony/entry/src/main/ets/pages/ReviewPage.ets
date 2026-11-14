import router from '@ohos.router';
import { repo } from '../common/repo/CandidateRepository';
import { AttemptReview, ReviewQuestion, ExamOption, ExamRouteParams } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { Formatters } from '../common/util/Formatters';
import {
  CardContainer, TagPill, LoadingView, ErrorBanner, KeyValueRow, DividerLine, GradientHero
} from '../components/Common';
import { RichContent, htmlToText } from '../components/RichContent';

@Entry
@Component
struct ReviewPage {
  @State review: AttemptReview = {};
  @State loading: boolean = true;
  @State error: string = '';

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    const params = router.getParams() as ExamRouteParams;
    try {
      this.review = await repo.review(params && params.attemptId ? params.attemptId : '');
      this.error = '';
    } catch (e) {
      this.error = (e as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private policyText(policy?: string): string {
    switch (policy) {
      case 'NEVER': return '本场考试不展示答题详情';
      case 'AFTER_PUBLISH': return '成绩发布后可查看答题详情';
      case 'AFTER_END': return '考试结束后可查看答题详情';
      default: return '暂不可查看答题详情';
    }
  }

  private formatAnswer(value?: string): string {
    if (!value) return '未作答';
    try {
      const arr = JSON.parse(value) as string[];
      if (Array.isArray(arr)) return arr.join(' / ');
      return value;
    } catch (e) {
      return value;
    }
  }

  build() {
    Column() {
      if (this.loading) {
        LoadingView()
      } else if (this.error.length > 0) {
        Column() { ErrorBanner({ message: this.error }) }.margin(16)
      } else if (this.review.allowed === false) {
        Column() { ErrorBanner({ message: this.policyText(this.review.policy) }) }.margin(16)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            GradientHero({ gradientStart: Tokens.PRIMARY, gradientEnd: Tokens.HERO_END }) {
              Column({ space: 5 }) {
                Text('答题详情').fontSize(21).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
                Text('共 ' + String(this.review.questions ? this.review.questions.length : 0) + ' 题 · 得分 ' +
                  Formatters.scoreText(this.review.score ? this.review.score.totalScore : undefined))
                  .fontSize(13).fontColor('#E0FFFFFF')
              }.alignItems(HorizontalAlign.Start).width('100%')
            }

            CardContainer() {
              Row() {
                Text('共 ' + String(this.review.questions ? this.review.questions.length : 0) + ' 题')
                  .fontSize(13).fontColor(Tokens.TEXT_SECONDARY)
                Blank()
                Text('得分 ' + Formatters.scoreText(this.review.score ? this.review.score.totalScore : undefined))
                  .fontSize(15).fontWeight(FontWeight.Bold).fontColor(Tokens.PRIMARY)
              }.width('100%')
            }

            ForEach(this.review.questions ? this.review.questions : [], (item: ReviewQuestion, index: number) => {
              CardContainer() {
                Column({ space: 8 }) {
                  Row({ space: 8 }) {
                    Text('第 ' + (index + 1) + ' 题').fontSize(15).fontWeight(FontWeight.Bold)
                    if (item.correct === true) {
                      TagPill({ label: '正确', fg: Tokens.SUCCESS, bg: Tokens.SUCCESS_SOFT })
                    } else if (item.correct === false) {
                      TagPill({ label: '错误', fg: Tokens.DANGER, bg: Tokens.DANGER_SOFT })
                    } else {
                      TagPill({ label: '待阅卷', fg: Tokens.WARNING, bg: Tokens.WARNING_SOFT })
                    }
                    Blank()
                    Text(Formatters.scoreText(item.score) + ' 分').fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
                  }.width('100%')

                  RichContent({ content: item.stem ? item.stem : '', fontSize: 15 })

                  if (item.options && item.options.length > 0) {
                    Column({ space: 3 }) {
                      ForEach(item.options, (option: ExamOption) => {
                        Row({ space: 8 }) {
                          Text(option.key ? option.key : '').fontSize(14).fontWeight(FontWeight.Bold).fontColor(Tokens.PRIMARY)
                          Text(htmlToText(option.text ? option.text : option.content)).fontSize(14).layoutWeight(1)
                        }.width('100%')
                      }, (option: ExamOption, i: number) => i.toString())
                    }.width('100%')
                  }

                  DividerLine()
                  KeyValueRow({ label: '我的答案', value: this.formatAnswer(item.myAnswerJson) })
                  if (item.expected && item.expected.length > 0) {
                    KeyValueRow({ label: '正确答案', value: item.expected.join(' / ') })
                  }
                  if (item.analysis) {
                    Column({ space: 4 }) {
                      Text('解析').fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
                      RichContent({ content: item.analysis, fontSize: 13 })
                    }
                    .width('100%')
                    .padding(10)
                    .backgroundColor(Tokens.SURFACE_ALT)
                    .borderRadius(8)
                    .alignItems(HorizontalAlign.Start)
                  }
                }.alignItems(HorizontalAlign.Start).width('100%')
              }
            }, (item: ReviewQuestion, index: number) => index.toString())
          }.padding(16)
        }.layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }
}
