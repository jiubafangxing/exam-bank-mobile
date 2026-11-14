import promptAction from '@ohos.promptAction';
import { repo } from '../common/repo/CandidateRepository';
import { ClassItem } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { Formatters } from '../common/util/Formatters';
import { CardContainer, TagPill, LoadingView, ErrorBanner } from '../components/Common';

@Entry
@Component
struct ClassPage {
  @State tab: number = 0;
  @State keyword: string = '';
  @State paidFilter: string = '';
  @State sort: string = '';
  @State list: ClassItem[] = [];
  @State loading: boolean = true;
  @State error: string = '';
  @State hasPending: boolean = false;
  @State pendingId: string = '';
  @State pendingName: string = '';
  @State passwordInput: string = '';

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    this.loading = true;
    try {
      if (this.tab === 0) {
        this.list = await repo.myClasses();
      } else {
        const params = new Map<string, string>();
        if (this.keyword.length > 0) params.set('keyword', this.keyword);
        if (this.paidFilter.length > 0) params.set('paid', this.paidFilter);
        if (this.sort.length > 0) params.set('sort', this.sort);
        this.list = await repo.classes(params);
      }
      this.error = '';
    } catch (e) {
      this.error = (e as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private joinModeText(mode?: string): string {
    switch (mode) {
      case 'FREE': return '免费加入';
      case 'PASSWORD': return '密码加入';
      case 'PAID': return '付费加入';
      case 'APPROVAL': return '审核加入';
      default: return '加入';
    }
  }

  private doJoin(id: string, password?: string): void {
    repo.joinClass(id, password).then(() => {
      promptAction.showToast({ message: '已加入' });
      this.load();
    }).catch((e: Error) => {
      promptAction.showToast({ message: e.message });
    });
  }

  private join(item: ClassItem): void {
    const id = item.id ? item.id : '';
    if (item.joinMode === 'PAID') {
      AlertDialog.show({
        title: '付费加入',
        message: '需支付 ¥' + Formatters.scoreText(item.price) + '，确认支付？',
        primaryButton: { value: '取消', action: () => {} },
        secondaryButton: {
          value: '确认支付',
          action: () => {
            repo.createOrder('CLASS', id).then((order) => {
              return repo.payOrder(order.id ? order.id : '').then(() => {
                return repo.joinClass(id);
              });
            }).then(() => {
              promptAction.showToast({ message: '已加入' });
              this.load();
            }).catch((e: Error) => {
              promptAction.showToast({ message: e.message });
            });
          }
        }
      });
    } else if (item.joinMode === 'PASSWORD') {
      this.pendingId = id;
      this.pendingName = item.name ? item.name : '';
      this.passwordInput = '';
      this.hasPending = true;
    } else {
      this.doJoin(id);
    }
  }

  build() {
    Column() {
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          TextInput({ placeholder: '搜索班级', text: this.keyword })
            .layoutWeight(1).height(42).backgroundColor(Tokens.SURFACE).borderRadius(8)
            .onChange((v: string) => { this.keyword = v; })
          Button('搜索').height(42).fontSize(13).backgroundColor(Tokens.PRIMARY)
            .onClick(() => { this.load(); })
        }.width('100%')

        Flex({ wrap: FlexWrap.Wrap }) {
          this.chip('全部', this.paidFilter === '', () => { this.paidFilter = ''; this.load(); })
          this.chip('免费', this.paidFilter === 'false', () => { this.paidFilter = 'false'; this.load(); })
          this.chip('付费', this.paidFilter === 'true', () => { this.paidFilter = 'true'; this.load(); })
          this.chip('默认', this.sort === '', () => { this.sort = ''; this.load(); })
          this.chip('价格↑', this.sort === 'priceAsc', () => { this.sort = 'priceAsc'; this.load(); })
          this.chip('价格↓', this.sort === 'priceDesc', () => { this.sort = 'priceDesc'; this.load(); })
          this.chip('人数', this.sort === 'students', () => { this.sort = 'students'; this.load(); })
          this.chip('最新', this.sort === 'newest', () => { this.sort = 'newest'; this.load(); })
        }.width('100%')

        Row({ space: 8 }) {
          this.tabButton('我的班级', 0)
          this.tabButton('全部班级', 1)
        }.width('100%')

        if (this.hasPending) {
          CardContainer() {
            Column({ space: 8 }) {
              Text('班级密码 · ' + this.pendingName).fontSize(14).fontWeight(FontWeight.Medium)
              TextInput({ placeholder: '请输入班级加入密码', text: this.passwordInput })
                .type(InputType.Password).width('100%').height(42)
                .backgroundColor(Tokens.SURFACE_ALT).borderRadius(8)
                .onChange((v: string) => { this.passwordInput = v; })
              Row({ space: 12 }) {
                Button('加入').height(42).backgroundColor(Tokens.PRIMARY).fontColor('#FFFFFF')
                  .onClick(() => {
                    const id = this.pendingId;
                    const pwd = this.passwordInput;
                    this.hasPending = false;
                    this.doJoin(id, pwd);
                  })
                Button('取消').height(42).backgroundColor(Tokens.SURFACE).fontColor(Tokens.TEXT_SECONDARY)
                  .onClick(() => { this.hasPending = false; })
              }
            }.alignItems(HorizontalAlign.Start).width('100%')
          }
        }
      }.padding(16)

      if (this.loading) {
        LoadingView()
      } else if (this.error.length > 0) {
        Column() { ErrorBanner({ message: this.error }) }.margin(16)
      } else {
        Scroll() {
          Column({ space: 8 }) {
            ForEach(this.list, (item: ClassItem) => {
              CardContainer() {
                Row({ space: 12 }) {
                  if (item.coverUrl) {
                    Image(item.coverUrl).width(72).height(72).borderRadius(10).objectFit(ImageFit.Cover)
                  }
                  Column({ space: 4 }) {
                    Text(item.name ? item.name : '').fontSize(16).fontWeight(FontWeight.Medium)
                    Text(item.description ? item.description : '暂无简介').fontSize(12).fontColor(Tokens.TEXT_SECONDARY).maxLines(2)
                    Row({ space: 8 }) {
                      TagPill({ label: this.joinModeText(item.joinMode) })
                      if ((item.price ? item.price : 0) > 0) {
                        Text('¥' + Formatters.scoreText(item.price)).fontSize(12).fontColor(Tokens.DANGER)
                      }
                      Text(String(item.studentCount ? item.studentCount : (item.memberCount ? item.memberCount : 0)) + ' 人')
                        .fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
                    }
                  }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                  if (item.joined === true) {
                    TagPill({ label: '已加入', fg: Tokens.SUCCESS, bg: Tokens.SUCCESS_SOFT })
                  } else if (item.joinStatus === 'PENDING') {
                    TagPill({ label: '审核中', fg: Tokens.WARNING, bg: Tokens.WARNING_SOFT })
                  } else {
                    Text('加入').fontSize(13).fontColor(Tokens.PRIMARY).onClick(() => { this.join(item); })
                  }
                }.width('100%')
              }
            }, (item: ClassItem, index: number) => index.toString())
          }.padding({ left: 16, right: 16, bottom: 16 })
        }.layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }

  @Builder
  chip(label: string, active: boolean, action: () => void) {
    Text(label)
      .fontSize(12)
      .fontColor(active ? '#FFFFFF' : Tokens.TEXT_SECONDARY)
      .backgroundColor(active ? Tokens.PRIMARY : Tokens.SURFACE)
      .borderRadius(999)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .margin({ right: 8, bottom: 8 })
      .onClick(action)
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
