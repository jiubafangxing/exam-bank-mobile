import { repo } from '../common/repo/CandidateRepository';
import { ScoreRecord, ScorePage as ScorePageData } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { Formatters } from '../common/util/Formatters';
import { CardContainer, TagPill, LoadingView, ErrorBanner, EmptyView } from '../components/Common';

@Entry
@Component
struct ScorePage {
  @State records: ScoreRecord[] = [];
  @State page: number = 1;
  @State total: number = 0;
  @State loading: boolean = true;
  @State error: string = '';

  aboutToAppear(): void {
    this.load(1);
  }

  async load(nextPage: number): Promise<void> {
    this.loading = true;
    try {
      const res: ScorePageData = await repo.scores(nextPage, 20);
      const list = res.records ? res.records : [];
      this.records = nextPage === 1 ? list : this.records.concat(list);
      this.total = res.total ? res.total : this.records.length;
      this.page = nextPage;
      this.error = '';
    } catch (e) {
      this.error = (e as Error).message;
    } finally {
      this.loading = false;
    }
  }

  build() {
    Column() {
      if (this.loading && this.records.length === 0) {
        LoadingView()
      } else if (this.error.length > 0 && this.records.length === 0) {
        ErrorBanner({ message: this.error }).margin(16)
      } else if (this.records.length === 0) {
        EmptyView({ text: '暂无成绩记录' })
      } else {
        Scroll() {
          Column({ space: 10 }) {
            ForEach(this.records, (score: ScoreRecord) => {
              CardContainer() {
                Column({ space: 6 }) {
                  Row() {
                    Text(score.examName ? score.examName : '考试').fontSize(15).fontWeight(FontWeight.Medium).layoutWeight(1).maxLines(1)
                    Text(Formatters.scoreText(score.totalScore)).fontSize(24).fontWeight(FontWeight.Bold).fontColor(Tokens.PRIMARY)
                  }.width('100%')
                  Row({ space: 16 }) {
                    Text('客观题 ' + Formatters.scoreText(score.objectiveScore)).fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
                    Text('主观题 ' + Formatters.scoreText(score.subjectiveScore)).fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
                    Blank()
                    if (score.status === 'PUBLISHED') {
                      TagPill({ label: '已发布', fg: Tokens.SUCCESS, bg: Tokens.SUCCESS_SOFT })
                    } else {
                      TagPill({ label: '待发布', fg: Tokens.WARNING, bg: Tokens.WARNING_SOFT })
                    }
                  }.width('100%')
                  if (score.publishedAt) {
                    Text('发布时间：' + score.publishedAt).fontSize(11).fontColor(Tokens.TEXT_TERTIARY)
                  }
                }.alignItems(HorizontalAlign.Start).width('100%')
              }
            }, (score: ScoreRecord, index: number) => index.toString())

            if (this.records.length < this.total) {
              Button('加载更多')
                .width('100%').height(44).borderRadius(999)
                .backgroundColor(Tokens.SURFACE).fontColor(Tokens.PRIMARY)
                .onClick(() => { this.load(this.page + 1); })
            }
          }.padding(16)
        }.layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }
}
