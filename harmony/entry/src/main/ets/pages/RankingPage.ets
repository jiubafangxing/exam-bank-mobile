import { repo } from '../common/repo/CandidateRepository';
import { RankingRow } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { Formatters } from '../common/util/Formatters';
import { CardContainer, LoadingView, ErrorBanner } from '../components/Common';

@Entry
@Component
struct RankingPage {
  @State tab: number = 0;
  @State rows: RankingRow[] = [];
  @State loading: boolean = true;
  @State error: string = '';

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    this.loading = true;
    try {
      this.rows = this.tab === 0 ? await repo.pointsRanking() : await repo.classRanking();
      this.error = '';
    } catch (e) {
      this.error = (e as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private title(row: RankingRow): string {
    if (this.tab === 1) {
      return row.className ? row.className : (row.classId ? row.classId : '');
    }
    if (row.name && row.name.length > 0) return row.name;
    return row.memberNo ? row.memberNo : (row.userId ? row.userId : '');
  }

  private subtitle(row: RankingRow): string {
    if (this.tab === 1) {
      return String(row.participants ? row.participants : 0) + ' 人参考';
    }
    return row.levelCode ? row.levelCode : '';
  }

  private value(row: RankingRow): string {
    if (this.tab === 1) {
      return Formatters.scoreText(row.averageScore !== undefined ? row.averageScore : row.score);
    }
    return String(row.points ? row.points : 0) + ' 分';
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        this.tabButton('积分排行', 0)
        this.tabButton('班级排行', 1)
      }.width('100%').padding(16)

      if (this.loading) {
        LoadingView()
      } else if (this.error.length > 0) {
        ErrorBanner({ message: this.error }).margin(16)
      } else {
        Scroll() {
          Column({ space: 6 }) {
            ForEach(this.rows, (row: RankingRow) => {
              CardContainer() {
                Row() {
                  Text(String(row.rank ? row.rank : 0))
                    .fontSize(16).fontWeight(FontWeight.Bold)
                    .fontColor((row.rank ? row.rank : 0) <= 3 ? Tokens.WARNING : Tokens.TEXT_SECONDARY)
                    .width(36)
                  Column({ space: 2 }) {
                    Text(this.title(row)).fontSize(15).fontWeight(row.isMe === true ? FontWeight.Bold : FontWeight.Normal)
                    if (this.subtitle(row).length > 0) {
                      Text(this.subtitle(row)).fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
                    }
                  }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                  Text(this.value(row)).fontSize(15).fontColor(Tokens.PRIMARY)
                }.width('100%')
              }
            }, (row: RankingRow, index: number) => index.toString())
          }.padding({ left: 16, right: 16, bottom: 16 })
        }.layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }

  @Builder
  tabButton(label: string, index: number) {
    Text(label)
      .fontSize(14)
      .fontColor(this.tab === index ? '#FFFFFF' : Tokens.TEXT_SECONDARY)
      .backgroundColor(this.tab === index ? Tokens.PRIMARY : Tokens.SURFACE)
      .borderRadius(999)
      .padding({ left: 18, right: 18, top: 8, bottom: 8 })
      .onClick(() => { if (this.tab !== index) { this.tab = index; this.load(); } })
  }
}
