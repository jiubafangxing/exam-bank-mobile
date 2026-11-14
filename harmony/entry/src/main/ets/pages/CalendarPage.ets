import { repo } from '../common/repo/CandidateRepository';
import { CalendarItem } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { CardContainer, TagPill, LoadingView, ErrorBanner } from '../components/Common';

@Entry
@Component
struct CalendarPage {
  @State list: CalendarItem[] = [];
  @State loading: boolean = true;
  @State error: string = '';

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    try {
      this.list = await repo.calendar();
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
        ErrorBanner({ message: this.error }).margin(16)
      } else {
        Scroll() {
          Column({ space: 8 }) {
            ForEach(this.list, (item: CalendarItem) => {
              CardContainer() {
                Row() {
                  Column({ space: 4 }) {
                    Text(item.title ? item.title : '').fontSize(15).fontWeight(FontWeight.Medium)
                    Text((item.date ? item.date : '') + ' ' + (item.startTime ? item.startTime : '') + ' ' + (item.endTime ? item.endTime : ''))
                      .fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
                  }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                  if (item.type) {
                    TagPill({ label: item.type })
                  }
                }.width('100%')
              }
            }, (item: CalendarItem, index: number) => index.toString())
          }.padding(16)
        }.layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }
}
