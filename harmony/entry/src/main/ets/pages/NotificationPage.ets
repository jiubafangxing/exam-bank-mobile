import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import common from '@ohos.app.ability.common';
import { repo } from '../common/repo/CandidateRepository';
import { NotificationItem } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import {
  CardContainer, LoadingView, ErrorBanner, TagPill, EmptyView
} from '../components/Common';

@Entry
@Component
struct NotificationPage {
  @State list: NotificationItem[] = [];
  @State loading: boolean = true;
  @State error: string = '';
  @State filter: string = '';

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

  private filtered(): NotificationItem[] {
    if (this.filter.length === 0) return this.list;
    const result: NotificationItem[] = [];
    for (let i = 0; i < this.list.length; i++) {
      const item = this.list[i];
      if (item && (item.type ? item.type : '').toUpperCase() === this.filter) {
        result.push(item);
      }
    }
    return result;
  }

  async markAll(): Promise<void> {
    try {
      await repo.markAllNotificationsRead();
      await this.load();
      promptAction.showToast({ message: '已全部标记为已读' });
    } catch (e) {
      this.error = (e as Error).message;
    }
  }

  async markOne(item: NotificationItem): Promise<void> {
    if (item.read === true) return;
    try {
      await repo.markNotificationRead(item.id ? item.id : '');
      await this.load();
    } catch (e) {
      this.error = (e as Error).message;
    }
  }

  private openLink(item: NotificationItem): void {
    const link = item.linkUrl ? item.linkUrl : '';
    if (link.length === 0) return;
    if (link.toLowerCase().indexOf('http') === 0) {
      const context = getContext(this) as common.UIAbilityContext;
      context.startAbility({ action: 'ohos.want.action.viewData', uri: link }).catch(() => {});
      return;
    }
    const lower = link.toLowerCase();
    if (lower.indexOf('exam') >= 0) {
      router.replaceUrl({ url: 'pages/Index', params: { tab: 1 } });
    } else if (lower.indexOf('practice') >= 0) {
      router.replaceUrl({ url: 'pages/Index', params: { tab: 2 } });
    } else if (lower.indexOf('member') >= 0) {
      router.pushUrl({ url: 'pages/MemberPage' });
    } else if (lower.indexOf('score') >= 0) {
      router.pushUrl({ url: 'pages/ScorePage' });
    } else if (lower.indexOf('wrong') >= 0) {
      router.pushUrl({ url: 'pages/WrongPage' });
    }
  }

  private typeLabel(type?: string): string {
    switch ((type ? type : '').toUpperCase()) {
      case 'APPEAL_RESULT': return '申诉';
      case 'EXAM_PUBLISH': return '考试';
      case 'SYSTEM': return '系统';
      default: return '通知';
    }
  }

  private typeFg(type?: string): string {
    switch ((type ? type : '').toUpperCase()) {
      case 'APPEAL_RESULT': return Tokens.WARNING;
      case 'EXAM_PUBLISH': return Tokens.PRIMARY;
      case 'SYSTEM': return Tokens.SLATE;
      default: return Tokens.TEXT_SECONDARY;
    }
  }

  private typeBg(type?: string): string {
    switch ((type ? type : '').toUpperCase()) {
      case 'APPEAL_RESULT': return Tokens.WARNING_SOFT;
      case 'EXAM_PUBLISH': return Tokens.PRIMARY_SOFT;
      case 'SYSTEM': return Tokens.SLATE_SOFT;
      default: return Tokens.SURFACE_ALT;
    }
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        this.chip('全部', '', this.filter === '')
        this.chip('考试', 'EXAM_PUBLISH', this.filter === 'EXAM_PUBLISH')
        this.chip('系统', 'SYSTEM', this.filter === 'SYSTEM')
        this.chip('申诉', 'APPEAL_RESULT', this.filter === 'APPEAL_RESULT')
        Blank()
        Text('全部已读')
          .fontSize(12).fontColor(Tokens.PRIMARY)
          .onClick(() => { this.markAll(); })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      if (this.loading) {
        LoadingView()
      } else if (this.error.length > 0) {
        Column() { ErrorBanner({ message: this.error }) }.margin(16)
      } else if (this.filtered().length === 0) {
        EmptyView({ text: '暂无通知' })
      } else {
        Scroll() {
          Column({ space: 8 }) {
            ForEach(this.filtered(), (item: NotificationItem, index: number) => {
              CardContainer() {
                Row({ space: 8 }) {
                  if (item.read !== true) {
                    Circle({ width: 7, height: 7 }).fill(Tokens.DANGER)
                  }
                  Column({ space: 4 }) {
                    Row({ space: 6 }) {
                      Text(item.title ? item.title : '')
                        .fontSize(15).fontWeight(FontWeight.Bold).fontColor(Tokens.TEXT_PRIMARY)
                        .layoutWeight(1).maxLines(1)
                      TagPill({
                        label: this.typeLabel(item.type),
                        fg: this.typeFg(item.type),
                        bg: this.typeBg(item.type)
                      })
                      if (item.linkUrl && item.linkUrl.length > 0) {
                        Text('›').fontSize(18).fontColor(Tokens.TEXT_TERTIARY)
                      }
                    }.width('100%')
                    if (item.content && item.content.length > 0) {
                      Text(item.content).fontSize(12).fontColor(Tokens.TEXT_SECONDARY).maxLines(3)
                    }
                    if (item.createdAt && item.createdAt.length > 0) {
                      Text(item.createdAt).fontSize(11).fontColor(Tokens.TEXT_TERTIARY)
                    }
                  }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                }.width('100%')
                .onClick(() => {
                  this.markOne(item);
                  this.openLink(item);
                })
              }
            }, (item: NotificationItem, index: number) => index.toString())
            Row().height(20)
          }.padding({ left: 16, right: 16, bottom: 16 })
        }.layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }

  @Builder
  chip(label: string, value: string, active: boolean) {
    Text(label)
      .fontSize(12)
      .fontColor(active ? '#FFFFFF' : Tokens.TEXT_SECONDARY)
      .backgroundColor(active ? Tokens.PRIMARY : Tokens.SURFACE)
      .borderRadius(Tokens.RADIUS_PILL)
      .padding({ left: 14, right: 14, top: 7, bottom: 7 })
      .onClick(() => { this.filter = value; })
  }
}
