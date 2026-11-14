import { repo } from '../common/repo/CandidateRepository';
import { AnalysisView, ScorePoint } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { Formatters } from '../common/util/Formatters';
import { CardContainer, LoadingView, ErrorBanner, KeyValueRow, TagPill, SectionTitle } from '../components/Common';

@Entry
@Component
struct AnalysisPage {
  @State data: AnalysisView = {};
  @State loading: boolean = true;
  @State error: string = '';

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    try {
      this.data = await repo.analysis();
      this.error = '';
    } catch (e) {
      this.error = (e as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private weakPoints(): string[] {
    if (this.data.weakPoints && this.data.weakPoints.length > 0) return this.data.weakPoints;
    return this.data.weakestTypes ? this.data.weakestTypes : [];
  }

  build() {
    Column() {
      if (this.loading) {
        LoadingView()
      } else if (this.error.length > 0) {
        ErrorBanner({ message: this.error }).margin(16)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            CardContainer() {
              Row() {
                this.cell('总考试', String(this.data.totalExams ? this.data.totalExams : 0))
                this.cell('已参加', String(this.data.attendedExams !== undefined ? this.data.attendedExams : (this.data.totalExams ? this.data.totalExams : 0)))
                this.cell('平均分', Formatters.scoreText(this.data.avgScore !== undefined ? this.data.avgScore : this.data.averageScore))
                this.cell('及格率', Math.round((this.data.passRate ? this.data.passRate : 0) * 100) + '%')
              }.width('100%')
            }
            CardContainer() {
              Column({ space: 6 }) {
                Row() {
                  this.cell('最低分', Formatters.scoreText(this.data.lowestScore))
                  this.cell('最高分', Formatters.scoreText(this.data.highestScore))
                }.width('100%')
                if (this.data.studyMinutes !== undefined && this.data.studyMinutes > 0) {
                  KeyValueRow({ label: '学习时长', value: String(this.data.studyMinutes) + ' 分钟' })
                }
              }.width('100%')
            }
            if (this.weakPoints().length > 0) {
              SectionTitle({ title: '薄弱知识点' })
              CardContainer() {
                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(this.weakPoints(), (point: string) => {
                    TagPill({ label: Formatters.questionTypeLabel(point), fg: Tokens.WARNING, bg: Tokens.WARNING_SOFT })
                      .margin({ right: 8, bottom: 8 })
                  }, (point: string, i: number) => i.toString())
                }.width('100%')
              }
            }
            if (this.data.trend && this.data.trend.length > 0) {
              SectionTitle({ title: '成绩趋势' })
              CardContainer() {
                Column() {
                  ForEach(this.data.trend, (point: ScorePoint) => {
                    Row() {
                      Text(point.label ? point.label : '').fontSize(13).fontColor(Tokens.TEXT_SECONDARY)
                      Blank()
                      Text(Formatters.scoreText(point.value)).fontSize(14).fontColor(Tokens.PRIMARY)
                    }.width('100%').padding({ top: 5, bottom: 5 })
                  }, (point: ScorePoint, i: number) => i.toString())
                }.width('100%')
              }
            }
          }.padding(16)
        }.layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }

  @Builder
  cell(label: string, value: string) {
    Column({ space: 2 }) {
      Text(value).fontSize(19).fontWeight(FontWeight.Bold).fontColor(Tokens.PRIMARY)
      Text(label).fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
    }.layoutWeight(1)
  }
}
