import promptAction from '@ohos.promptAction';
import { repo } from '../common/repo/CandidateRepository';
import { MemberProfile, MemberLevel, OrderItem } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { Formatters } from '../common/util/Formatters';
import { CardContainer, TagPill, LoadingView, ErrorBanner, SectionTitle, EmptyView } from '../components/Common';

@Entry
@Component
struct MemberPage {
  @State profile: MemberProfile = {};
  @State levels: MemberLevel[] = [];
  @State orders: OrderItem[] = [];
  @State loading: boolean = true;
  @State error: string = '';

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    try {
      this.profile = await repo.memberProfile();
      this.levels = await repo.memberLevels();
      this.orders = await repo.orders();
      this.error = '';
    } catch (e) {
      this.error = (e as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private bizText(biz?: string): string {
    switch (biz) {
      case 'EXAM': return '考试订单';
      case 'PRACTICE': return '练习订单';
      case 'CLASS': return '班级订单';
      case 'VIP': return '会员订单';
      default: return biz ? biz : '订单';
    }
  }

  private statusText(status?: string): string {
    switch (status) {
      case 'CREATED':
      case 'UNPAID':
      case 'PENDING': return '待支付';
      case 'PAID': return '已支付';
      case 'CANCELLED': return '已取消';
      case 'CLOSED': return '已关闭';
      case 'REFUNDED': return '已退款';
      default: return status ? status : '';
    }
  }

  private statusColor(status?: string): string {
    switch (status) {
      case 'PAID': return Tokens.SUCCESS;
      case 'CREATED':
      case 'UNPAID':
      case 'PENDING': return Tokens.WARNING;
      case 'REFUNDED': return Tokens.DANGER;
      default: return Tokens.TEXT_SECONDARY;
    }
  }

  private statusBg(status?: string): string {
    switch (status) {
      case 'PAID': return Tokens.SUCCESS_SOFT;
      case 'CREATED':
      case 'UNPAID':
      case 'PENDING': return Tokens.WARNING_SOFT;
      case 'REFUNDED': return Tokens.DANGER_SOFT;
      default: return Tokens.SURFACE_ALT;
    }
  }

  async buy(level: MemberLevel): Promise<void> {
    try {
      const order = await repo.createOrder('VIP', level.code ? level.code : '');
      await repo.payOrder(order.id ? order.id : '');
      promptAction.showToast({ message: '开通成功' });
      await this.load();
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message });
    }
  }

  async pay(order: OrderItem): Promise<void> {
    try {
      await repo.payOrder(order.id ? order.id : '');
      promptAction.showToast({ message: '支付成功' });
      await this.load();
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message });
    }
  }

  async cancel(order: OrderItem): Promise<void> {
    try {
      await repo.cancelOrder(order.id ? order.id : '');
      promptAction.showToast({ message: '已取消' });
      await this.load();
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message });
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
          Column({ space: 12 }) {
            CardContainer() {
              Row() {
                Column({ space: 4 }) {
                  Text((this.profile.realName ? this.profile.realName : '我') + ' · ' +
                    (this.profile.levelName ? this.profile.levelName :
                      (this.profile.levelCode === 'BASIC' || !this.profile.levelCode ? '基础会员' : this.profile.levelCode)))
                    .fontSize(17).fontWeight(FontWeight.Bold).fontColor(Tokens.PRIMARY)
                  Text(this.profile.vipExpireAt && this.profile.vipExpireAt.length > 0 ? 'VIP 有效期至 ' + this.profile.vipExpireAt :
                    (this.profile.levelCode && this.profile.levelCode !== 'BASIC' ? '长期有效' : '基础会员，购买等级享专属考试与练习'))
                    .fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                Column({ space: 2 }) {
                  Text(String(this.profile.pointsBalance !== undefined ? this.profile.pointsBalance : (this.profile.points ? this.profile.points : 0)))
                    .fontSize(20).fontWeight(FontWeight.Bold).fontColor(Tokens.PRIMARY)
                  Text('积分').fontSize(11).fontColor(Tokens.TEXT_SECONDARY)
                }.alignItems(HorizontalAlign.End)
              }.width('100%')
            }

            SectionTitle({ title: '会员等级' })
            if (this.levels.length === 0) {
              EmptyView({ text: '暂无在售等级' })
            } else {
              ForEach(this.levels, (level: MemberLevel) => {
                CardContainer() {
                  Column({ space: 8 }) {
                    Row() {
                      Column({ space: 4 }) {
                        Text(level.name ? level.name : '').fontSize(15).fontWeight(FontWeight.Medium)
                        Text(String(level.durationDays ? level.durationDays : 0) + ' 天 · ' + (level.description ? level.description : ''))
                          .fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
                      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                      Text('¥' + Formatters.scoreText(level.price)).fontSize(16).fontWeight(FontWeight.Bold).fontColor(Tokens.DANGER)
                    }.width('100%')
                    Button('立即开通')
                      .width('100%').height(40).borderRadius(999).backgroundColor(Tokens.PRIMARY)
                      .onClick(() => { this.buy(level); })
                  }.alignItems(HorizontalAlign.Start).width('100%')
                }
              }, (level: MemberLevel, i: number) => i.toString())
            }

            SectionTitle({ title: '我的订单' })
            if (this.orders.length === 0) {
              EmptyView({ text: '暂无订单' })
            } else {
              ForEach(this.orders, (order: OrderItem) => {
                CardContainer() {
                  Column({ space: 8 }) {
                    Row() {
                      Column({ space: 4 }) {
                        Text(this.bizText(order.bizType) +
                          (order.bizType === 'VIP' && order.bizId ? ' / ' + order.bizId : ''))
                          .fontSize(14).fontWeight(FontWeight.Medium)
                        Text((order.orderNo ? order.orderNo : '') + ' · ' + (order.createdAt ? order.createdAt : ''))
                          .fontSize(11).fontColor(Tokens.TEXT_SECONDARY)
                      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                      Column({ space: 4 }) {
                        Text('¥' + Formatters.scoreText(order.amount)).fontSize(15).fontColor(Tokens.DANGER)
                        TagPill({
                          label: this.statusText(order.status),
                          fg: this.statusColor(order.status),
                          bg: this.statusBg(order.status)
                        })
                      }.alignItems(HorizontalAlign.End)
                    }.width('100%')
                    if (order.status === 'CREATED' || order.status === 'UNPAID' || order.status === 'PENDING') {
                      Row({ space: 12 }) {
                        Button('继续支付').height(40).borderRadius(999).backgroundColor(Tokens.PRIMARY)
                          .onClick(() => { this.pay(order); })
                        Button('取消').height(40).borderRadius(999).backgroundColor(Tokens.SURFACE).fontColor(Tokens.TEXT_SECONDARY)
                          .onClick(() => { this.cancel(order); })
                      }
                    }
                  }.alignItems(HorizontalAlign.Start).width('100%')
                }
              }, (order: OrderItem, i: number) => i.toString())
            }
          }.padding(16)
        }.layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }
}
