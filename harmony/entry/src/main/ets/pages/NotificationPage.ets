import { repo } from '../common/repo/CandidateRepository';
import { NotificationItem } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { CardContainer, LoadingView, ErrorBanner } from '../components/Common';

@Entry
@Component
struct NotificationPage {
  @State list: NotificationItem[] = [];
  @State loading: boolean = true;
  @State error: string = '';

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    try {
      this.list = await repo.notifications();
      this.error = '';
    } catch (e) {
      this.error = (e as Error).message;
    } finally {
      this.loading = false;
    }
  }

  async markAll(): Promise<void> {
    try {
      await repo.markAllNotificationsRead();
      this.load();
    } catch (e) {
      this.error = (e as Error).message;
    }
  }

  async markOne(item: NotificationItem): Promise<void> {
    if (item.read === true) return;
    try {
      await repo.markNotificationRead(item.id ? item.id : '');
      this.load();
    } catch (e) {
      this.error = (e as Error).message;
    }
  }

  build() {
    Column() {
      Row() {
        Blank()
        Text('全部已读').fontSize(13).fontColor(Tokens.PRIMARY).onClick(() => { this.markAll(); })
      }.width('100%').padding(16)

      if (this.loading) {
        LoadingView()
      } else if (this.error.length > 0) {
        Column() { ErrorBanner({ message: this.error }) }.margin(16)
      } else {
        Scroll() {
          Column({ space: 8 }) {
            ForEach(this.list, (item: NotificationItem) => {
              CardContainer() {
                Column({ space: 4 }) {
                  Row({ space: 6 }) {
                    if (item.read !== true) {
                      Circle().width(7).height(7).fill(Tokens.DANGER)
                    }
                    Text(item.title ? item.title : '').fontSize(15).fontWeight(FontWeight.Medium)
                  }.width('100%')
                  if (item.content) {
                    Text(item.content).fontSize(12).fontColor(Tokens.TEXT_SECONDARY).maxLines(3)
                  }
                  if (item.createdAt) {
                    Text(item.createdAt).fontSize(11).fontColor(Tokens.TEXT_TERTIARY)
                  }
                }.alignItems(HorizontalAlign.Start).width('100%')
              }
              .onClick(() => { this.markOne(item); })
            }, (item: NotificationItem, index: number) => index.toString())
          }.padding({ left: 16, right: 16, bottom: 16 })
        }.layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }
}
