import { repo } from '../common/repo/CandidateRepository';
import { PracticeStatistics } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { CardContainer, LoadingView, ErrorBanner, KeyValueRow } from '../components/Common';

@Entry
@Component
struct PracticeStatsPage {
  @State stats: PracticeStatistics = {};
  @State loading: boolean = true;
  @State error: string = '';

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    try {
      this.stats = await repo.practiceStatistics();
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
        CardContainer() {
          Column() {
            Row() {
              this.cell('练习次数', String(this.stats.totalRecords ? this.stats.totalRecords : 0))
              this.cell('完成', String(this.stats.finishedRecords ? this.stats.finishedRecords : 0))
              this.cell('正确率', Math.round((this.stats.averageAccuracy ? this.stats.averageAccuracy : 0) * 100) + '%')
            }.width('100%')
            KeyValueRow({ label: '累计做题', value: String(this.stats.totalQuestions ? this.stats.totalQuestions : 0) })
            KeyValueRow({ label: '答对', value: String(this.stats.correctQuestions ? this.stats.correctQuestions : 0) })
          }.width('100%')
        }
      }
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }

  @Builder
  cell(label: string, value: string) {
    Column({ space: 2 }) {
      Text(value).fontSize(20).fontWeight(FontWeight.Bold).fontColor(Tokens.PRIMARY)
      Text(label).fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
    }.layoutWeight(1)
  }
}
