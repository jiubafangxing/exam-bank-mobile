import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import common from '@ohos.app.ability.common';
import { repo } from '../common/repo/CandidateRepository';
import { SessionStore } from '../common/storage/SessionStore';
import {
  ExamSummary, OpenExamSummary, PracticeSet, PracticeStatistics,
  HomeComponent, HomeItem, User, TabRouteParams
} from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { AppConfig } from '../common/config/AppConfig';
import { Formatters } from '../common/util/Formatters';
import {
  CardContainer, TagPill, EmptyView, LoadingView, ErrorBanner,
  GradientHero, IconTile, SectionHeader,
  StatTile, ListRow, DividerLine
} from '../components/Common';

@Entry
@Component
struct Index {
  @State activeTab: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as TabRouteParams;
    if (params && params.tab !== undefined && params.tab !== null) {
      const tab = Number(params.tab);
      if (tab >= 0 && tab <= 3) this.activeTab = tab;
    }
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.activeTab }) {
      TabContent() {
        HomeTab({ activeTab: $activeTab })
      }.tabBar(this.tabBar('首页', 0))

      TabContent() {
        ExamsTab()
      }.tabBar(this.tabBar('考试', 1))

      TabContent() {
        PracticeTab()
      }.tabBar(this.tabBar('练习', 2))

      TabContent() {
        ProfileTab({ activeTab: $activeTab })
      }.tabBar(this.tabBar('我的', 3))
    }
    .onChange((index: number) => {
      this.activeTab = index;
    })
    .barHeight(64)
    .backgroundColor(Tokens.BACKGROUND)
  }

  @Builder
  tabBar(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(12)
        .fontWeight(this.activeTab === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.activeTab === index ? Tokens.PRIMARY : Tokens.TEXT_SECONDARY)
        .padding({ left: 16, right: 16, top: 7, bottom: 7 })
        .backgroundColor(this.activeTab === index ? Tokens.PRIMARY_SOFT : '#00000000')
        .borderRadius(Tokens.RADIUS_PILL)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}

// ============================ 首页 ============================

@Component
struct HomeTab {
  @Link activeTab: number;
  @State components: HomeComponent[] = [];
  @State loading: boolean = true;
  @State error: string = '';
  @State displayName: string = '同学';
  @State dateText: string = '';

  aboutToAppear(): void {
    this.initHeader();
    this.load();
  }

  private initHeader(): void {
    if (SessionStore.userJson) {
      try {
        const user = JSON.parse(SessionStore.userJson) as User;
        this.displayName = user.realName ? user.realName : (user.username ? user.username : '同学');
      } catch (e) {
        this.displayName = '同学';
      }
    }
    const now = new Date();
    const weekdays: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    this.dateText = (now.getMonth() + 1) + '月' + now.getDate() + '日 · ' + weekdays[now.getDay()];
  }

  async load(): Promise<void> {
    try {
      this.components = await repo.home();
      this.error = '';
    } catch (e) {
      this.error = (e as Error).message;
    } finally {
      this.loading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        GradientHero({ gradientStart: Tokens.PRIMARY, gradientEnd: Tokens.HERO_END }) {
          Column({ space: 14 }) {
            Row() {
              Text(this.dateText).fontSize(12).fontColor('#E6FFFFFF')
              Blank()
              Text('在线考试平台')
                .fontSize(11)
                .fontColor('#FFE3A8')
                .backgroundColor('#2EFFFFFF')
                .borderRadius(Tokens.RADIUS_PILL)
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            }.width('100%')

            Column({ space: 6 }) {
              Text(Formatters.greeting() + '，' + this.displayName)
                .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
              Text('今天也要稳稳拿分。考试、练习、错题与班级内容都在这里。')
                .fontSize(13).fontColor('#E0FFFFFF')
            }.alignItems(HorizontalAlign.Start).width('100%')

            Row({ space: 10 }) {
              Text('进入我的考试')
                .fontSize(13).fontWeight(FontWeight.Bold).fontColor(Tokens.PRIMARY)
                .backgroundColor('#FFFFFF').borderRadius(Tokens.RADIUS_PILL)
                .padding({ left: 18, right: 18, top: 9, bottom: 9 })
                .onClick(() => { this.activeTab = 1; })
              Text('继续练习')
                .fontSize(13).fontWeight(FontWeight.Medium).fontColor('#FFFFFF')
                .backgroundColor('#24FFFFFF').borderRadius(Tokens.RADIUS_PILL)
                .padding({ left: 18, right: 18, top: 9, bottom: 9 })
                .onClick(() => { this.activeTab = 2; })
            }.width('100%')
          }.width('100%')
        }

        SectionHeader({ title: '快捷服务' })
        CardContainer() {
          Column({ space: 2 }) {
            Row() {
              this.quickLink('我的考试', 0, () => { this.activeTab = 1; })
              this.quickLink('在线练习', 1, () => { this.activeTab = 2; })
              this.quickLink('错题集', 2, () => { router.pushUrl({ url: 'pages/WrongPage' }); })
              this.quickLink('班级', 3, () => { router.pushUrl({ url: 'pages/ClassPage' }); })
            }.width('100%').padding({ top: 6, bottom: 6 })
            Row() {
              this.quickLink('考试组', 4, () => { router.pushUrl({ url: 'pages/ExamGroupPage' }); })
              this.quickLink('排行榜', 5, () => { router.pushUrl({ url: 'pages/RankingPage' }); })
              this.quickLink('文章', 6, () => { router.pushUrl({ url: 'pages/ArticleListPage' }); })
              this.quickLink('教师风采', 7, () => { router.pushUrl({ url: 'pages/TeacherPage' }); })
            }.width('100%').padding({ top: 6, bottom: 6 })
          }.width('100%')
        }

        if (AppConfig.REGISTRATION_URL.length > 0) {
          CardContainer() {
            Row({ space: 12 }) {
              IconTile({ label: '报', fg: Tokens.AMBER, bg: Tokens.AMBER_SOFT, tileSize: 44 })
              Column({ space: 3 }) {
                Text('考试报名').fontSize(15).fontWeight(FontWeight.Bold).fontColor(Tokens.TEXT_PRIMARY)
                Text('查看招录公告、岗位与报名进度').fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              Text('›').fontSize(20).fontColor(Tokens.TEXT_TERTIARY)
            }
            .width('100%')
            .onClick(() => this.openRegistration())
          }
        }

        if (this.loading) {
          LoadingView()
        } else if (this.error.length > 0) {
          ErrorBanner({ message: this.error })
        } else {
          ForEach(this.components, (component: HomeComponent) => {
            this.componentView(component)
          }, (component: HomeComponent, index: number) => index.toString())
        }

        Row().height(8)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Tokens.BACKGROUND)
  }

  @Builder
  quickLink(label: string, paletteIndex: number, action: () => void) {
    Column({ space: 7 }) {
      IconTile({
        label: label,
        fg: Tokens.palette(paletteIndex).fg,
        bg: Tokens.palette(paletteIndex).bg,
        tileSize: 46,
        fontSize: 19
      })
      Text(label).fontSize(12).fontColor(Tokens.TEXT_PRIMARY).maxLines(1)
    }
    .layoutWeight(1)
    .onClick(action)
  }

  @Builder
  componentView(component: HomeComponent) {
    if (component.componentType === 'BANNER') {
      this.bannerView(component)
    } else if (component.componentType === 'NAV') {
      this.navView(component)
    } else if (component.componentType === 'NOTICE') {
      this.noticeView(component)
    } else if (component.componentType === 'HOT_EXAM') {
      this.hotExamView(component)
    } else if (component.componentType === 'ARTICLE' || component.componentType === 'TEACHER'
      || component.componentType === 'CLASS_RECOMMEND') {
      this.contentView(component)
    } else {
      this.genericView(component)
    }
  }

  @Builder
  bannerView(component: HomeComponent) {
    if (component.items && component.items.length > 0) {
      Scroll() {
        Row({ space: 12 }) {
          ForEach(component.items ? component.items : [], (item: HomeItem, index: number) => {
            Stack({ alignContent: Alignment.BottomStart }) {
              if ((item.imageUrl ? item.imageUrl : (item.coverUrl ? item.coverUrl : '')).length > 0) {
                Image(item.imageUrl ? item.imageUrl : (item.coverUrl ? item.coverUrl : ''))
                  .width('100%').height('100%').objectFit(ImageFit.Cover)
              }
              Column()
                .width('100%').height('100%')
                .linearGradient({
                  angle: 90,
                  colors: [['#CC0B1B2E', 0], ['#550B1B2E', 0.55], ['#000B1B2E', 1]]
                })
              Column({ space: 5 }) {
                Text(item.tag ? item.tag : '推荐')
                  .fontSize(10).fontColor('#FFFFFF')
                  .backgroundColor('#38FFFFFF').borderRadius(Tokens.RADIUS_PILL)
                  .padding({ left: 9, right: 9, top: 3, bottom: 3 })
                Text(item.title ? item.title : (item.name ? item.name : ''))
                  .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#FFFFFF').maxLines(1)
                if ((item.summary ? item.summary : (item.intro ? item.intro : (item.description ? item.description : ''))).length > 0) {
                  Text(item.summary ? item.summary : (item.intro ? item.intro : (item.description ? item.description : '')))
                    .fontSize(12).fontColor('#E6FFFFFF').maxLines(1)
                }
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
              .padding(16)
            }
            .width(300).height(160).borderRadius(Tokens.RADIUS_XL)
            .backgroundColor(Tokens.SURFACE_ALT)
            .clip(true)
            .onClick(() => this.openHomeItem(item))
          }, (item: HomeItem, index: number) => index.toString())
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .padding({ top: 4, bottom: 4 })
    }
  }

  @Builder
  navView(component: HomeComponent) {
    if (component.items && component.items.length > 0) {
      SectionHeader({ title: component.title ? component.title : '推荐入口' })
      CardContainer() {
        Column({ space: 2 }) {
          ForEach(this.rowIndexes(component.items ? component.items.length : 0), (row: number) => {
            Row() {
              ForEach(component.items ? component.items.slice(row * 4, row * 4 + 4) : [],
                (item: HomeItem, col: number) => {
                  Column({ space: 6 }) {
                    IconTile({
                      label: this.itemLabel(item),
                      fg: Tokens.palette(row * 4 + col).fg,
                      bg: Tokens.palette(row * 4 + col).bg,
                      tileSize: 44,
                      fontSize: 18
                    })
                    Text(this.itemLabel(item)).fontSize(12).fontColor(Tokens.TEXT_PRIMARY).maxLines(1)
                  }
                  .layoutWeight(1)
                  .onClick(() => this.openHomeItem(item))
                }, (item: HomeItem, col: number) => row.toString() + '-' + col.toString())
            }.width('100%').padding({ top: 6, bottom: 6 })
          }, (row: number) => row.toString())
        }.width('100%')
      }
    }
  }

  @Builder
  noticeView(component: HomeComponent) {
    if (component.items && component.items.length > 0) {
      CardContainer() {
        Row({ space: 12 }) {
          IconTile({ label: '公', fg: Tokens.AMBER, bg: '#FFFFFFFF', tileSize: 38, fontSize: 16 })
          Text(this.itemLabel(component.items ? component.items[0] : this.emptyItem()))
            .fontSize(13).fontColor(Tokens.TEXT_PRIMARY).maxLines(1).layoutWeight(1)
          Text('查看').fontSize(12).fontColor(Tokens.AMBER)
          Text('›').fontSize(18).fontColor(Tokens.AMBER)
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor(Tokens.AMBER_SOFT)
        .borderRadius(Tokens.RADIUS_MD)
        .onClick(() => this.openNotice(component.items ? component.items[0] : this.emptyItem()))
      }
    }
  }

  @Builder
  hotExamView(component: HomeComponent) {
    if (component.items && component.items.length > 0) {
      SectionHeader({
        title: component.title ? component.title : '热门考试',
        actionLabel: '全部考试',
        onAction: () => { this.activeTab = 1; }
      })
      Scroll() {
        Row({ space: 12 }) {
          ForEach(component.items ? component.items : [], (item: HomeItem, index: number) => {
            Column({ space: 8 }) {
              Text('待参加')
                .fontSize(10).fontColor(Tokens.PRIMARY)
                .backgroundColor(Tokens.PRIMARY_SOFT).borderRadius(Tokens.RADIUS_PILL)
                .padding({ left: 9, right: 9, top: 3, bottom: 3 })
              Text(this.itemLabel(item))
                .fontSize(15).fontWeight(FontWeight.Bold).fontColor(Tokens.TEXT_PRIMARY)
                .maxLines(2)
              Text(item.summary ? item.summary : '点击查看考试详情')
                .fontSize(12).fontColor(Tokens.TEXT_SECONDARY).maxLines(1)
            }
            .alignItems(HorizontalAlign.Start)
            .width(220)
            .padding(14)
            .backgroundColor(Tokens.SURFACE)
            .borderRadius(Tokens.RADIUS_LG + 2)
            .shadow({ radius: 14, color: Tokens.SHADOW_CARD_COLOR, offsetX: 0, offsetY: 4 })
            .onClick(() => { this.activeTab = 1; })
          }, (item: HomeItem, index: number) => index.toString())
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .padding({ bottom: 2 })
    }
  }

  @Builder
  contentView(component: HomeComponent) {
    if (component.items && component.items.length > 0) {
      SectionHeader({
        title: component.title ? component.title : (component.componentType === 'TEACHER' ? '教师风采'
          : (component.componentType === 'CLASS_RECOMMEND' ? '推荐班级' : '精选内容')),
        actionLabel: '查看更多',
        onAction: () => this.openSectionMore(component.componentType ? component.componentType : '')
      })
      CardContainer() {
        Column() {
          ForEach(component.items ? component.items : [], (item: HomeItem, index: number) => {
            Row({ space: 12 }) {
              if ((item.coverUrl ? item.coverUrl : (item.avatarUrl ? item.avatarUrl : '')).length > 0) {
                Image(item.coverUrl ? item.coverUrl : (item.avatarUrl ? item.avatarUrl : ''))
                  .width(58).height(58).borderRadius(Tokens.RADIUS_MD + 2).objectFit(ImageFit.Cover)
              } else {
                IconTile({
                  label: this.sectionGlyph(component.componentType ? component.componentType : ''),
                  fg: Tokens.palette(index).fg,
                  bg: Tokens.palette(index).bg,
                  tileSize: 52,
                  fontSize: 20
                })
              }
              Column({ space: 3 }) {
                Text(this.itemLabel(item))
                  .fontSize(15).fontWeight(FontWeight.Bold).fontColor(Tokens.TEXT_PRIMARY).maxLines(1)
                if ((item.summary ? item.summary : (item.intro ? item.intro : (item.description ? item.description : ''))).length > 0) {
                  Text(item.summary ? item.summary : (item.intro ? item.intro : (item.description ? item.description : '')))
                    .fontSize(12).fontColor(Tokens.TEXT_SECONDARY).maxLines(2)
                }
                if ((item.publishAt ? item.publishAt : (item.createdAt ? item.createdAt : '')).length > 0) {
                  Text(item.publishAt ? item.publishAt : (item.createdAt ? item.createdAt : ''))
                    .fontSize(11).fontColor(Tokens.TEXT_TERTIARY).maxLines(1)
                }
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              Text('›').fontSize(18).fontColor(Tokens.TEXT_TERTIARY)
            }
            .width('100%')
            .padding({ top: 9, bottom: 9 })
            .onClick(() => this.openHomeItem(item))

            if (index < (component.items ? component.items.length - 1 : 0)) {
              DividerLine()
            }
          }, (item: HomeItem, index: number) => index.toString())
        }.width('100%')
      }
    }
  }

  @Builder
  genericView(component: HomeComponent) {
    if (component.items && component.items.length > 0) {
      SectionHeader({ title: component.title ? component.title : '更多内容' })
      CardContainer() {
        Column() {
          ForEach(component.items ? component.items : [], (item: HomeItem, index: number) => {
            Row({ space: 12 }) {
              if ((item.coverUrl ? item.coverUrl : (item.avatarUrl ? item.avatarUrl : '')).length > 0) {
                Image(item.coverUrl ? item.coverUrl : (item.avatarUrl ? item.avatarUrl : ''))
                  .width(48).height(48).borderRadius(Tokens.RADIUS_MD).objectFit(ImageFit.Cover)
              }
              Column({ space: 2 }) {
                Text(this.itemLabel(item)).fontSize(15).fontWeight(FontWeight.Medium).fontColor(Tokens.TEXT_PRIMARY).maxLines(1)
                if ((item.summary ? item.summary : (item.intro ? item.intro : (item.description ? item.description : ''))).length > 0) {
                  Text(item.summary ? item.summary : (item.intro ? item.intro : (item.description ? item.description : '')))
                    .fontSize(12).fontColor(Tokens.TEXT_SECONDARY).maxLines(1)
                }
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              Text('›').fontSize(18).fontColor(Tokens.TEXT_TERTIARY)
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
            .onClick(() => this.openHomeItem(item))
          }, (item: HomeItem, index: number) => index.toString())
        }.width('100%')
      }
    }
  }

  private rowIndexes(count: number): number[] {
    const rows: number[] = [];
    for (let i = 0; i < Math.ceil(count / 4); i++) rows.push(i);
    return rows;
  }

  private itemLabel(item: HomeItem): string {
    return item.name ? item.name : (item.title ? item.title : '入口');
  }

  private emptyItem(): HomeItem {
    return {};
  }

  private sectionGlyph(type: string): string {
    if (type === 'TEACHER') return '师';
    if (type === 'CLASS_RECOMMEND') return '班';
    return '文';
  }

  private openRegistration(): void {
    if (AppConfig.REGISTRATION_URL.length === 0) {
      promptAction.showToast({ message: '报名入口未配置' });
      return;
    }
    const base = AppConfig.REGISTRATION_URL.endsWith('/')
      ? AppConfig.REGISTRATION_URL.slice(0, AppConfig.REGISTRATION_URL.length - 1)
      : AppConfig.REGISTRATION_URL;
    this.openExternal(base + '/campaigns');
  }

  private openExternal(url: string): void {
    if (url.length === 0) return;
    const context = getContext(this) as common.UIAbilityContext;
    context.startAbility({ action: 'ohos.want.action.viewData', uri: url }).catch(() => {});
  }

  private openNotice(item: HomeItem): void {
    const link = item.linkUrl ? item.linkUrl : (item.url ? item.url : '');
    if (link.toLowerCase().indexOf('http') === 0) {
      this.openExternal(link);
      return;
    }
    if (link.length > 0 && link !== 'notifications') {
      const temp: HomeItem = { path: link, title: item.title, name: item.name, id: item.id };
      this.openHomeItem(temp);
      return;
    }
    router.pushUrl({ url: 'pages/NotificationPage' });
  }

  private openSectionMore(type: string): void {
    if (type === 'TEACHER') {
      router.pushUrl({ url: 'pages/TeacherPage' });
    } else if (type === 'CLASS_RECOMMEND') {
      router.pushUrl({ url: 'pages/ClassPage' });
    } else {
      router.pushUrl({ url: 'pages/ArticleListPage' });
    }
  }

  private openHomeItem(item: HomeItem): void {
    const path = (item.path ? item.path : (item.url ? item.url : '')).toLowerCase();
    const label = this.itemLabel(item).toLowerCase();
    if (path.indexOf('http') === 0 || (item.url ? item.url : '').toLowerCase().indexOf('http') === 0) {
      this.openExternal(item.url ? item.url : (item.path ? item.path : ''));
      return;
    }
    if (path.indexOf('exam') >= 0 || label.indexOf('考试') >= 0) {
      this.activeTab = 1;
      return;
    }
    if (path.indexOf('practice') >= 0 || label.indexOf('练习') >= 0) {
      this.activeTab = 2;
      return;
    }
    if (path.indexOf('class') >= 0 || label.indexOf('班级') >= 0) {
      router.pushUrl({ url: 'pages/ClassPage' });
      return;
    }
    if (path.indexOf('teacher') >= 0 || label.indexOf('教师') >= 0) {
      router.pushUrl({ url: 'pages/TeacherPage' });
      return;
    }
    if (path.indexOf('notification') >= 0 || label.indexOf('通知') >= 0) {
      router.pushUrl({ url: 'pages/NotificationPage' });
      return;
    }
    if (path.indexOf('article') >= 0 || label.indexOf('文章') >= 0) {
      router.pushUrl({ url: 'pages/ArticleListPage' });
      return;
    }
    if (item.id) {
      router.pushUrl({ url: 'pages/ArticleDetailPage', params: { articleId: item.id } });
    }
  }
}

// ============================ 考试 ============================

@Component
struct ExamsTab {
  @State keyword: string = '';
  @State paidFilter: string = '';
  @State sort: string = 'startTime';
  @State exams: ExamSummary[] = [];
  @State openExams: OpenExamSummary[] = [];
  @State loading: boolean = true;
  @State error: string = '';
  @State showPassword: boolean = false;
  @State passwordValue: string = '';
  @State pendingExam: ExamSummary = {};
  @State pendingResult: boolean = false;

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    this.loading = true;
    try {
      const params = new Map<string, string>();
      if (this.keyword.length > 0) params.set('keyword', this.keyword);
      if (this.paidFilter.length > 0) params.set('paid', this.paidFilter);
      if (this.sort.length > 0) params.set('sort', this.sort);
      const list = await repo.exams(params);
      this.exams = list;
      const assigned: string[] = [];
      for (let i = 0; i < list.length; i++) {
        const exam = list[i];
        if (exam && exam.id) assigned.push(exam.id);
      }
      const open = await repo.openExams();
      const visible: OpenExamSummary[] = [];
      for (let i = 0; i < open.length; i++) {
        const item = open[i];
        if (item && item.id && assigned.indexOf(item.id) < 0) visible.push(item);
      }
      this.openExams = visible;
      this.error = '';
    } catch (e) {
      this.error = (e as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private statusLabel(status?: string): string {
    const s = (status ? status : '').toUpperCase();
    if (s === 'IN_PROGRESS' || s === 'STARTED') return '作答中';
    if (s === 'GRADED') return '已出分';
    if (s === 'SUBMITTED' || s === 'GRADING') return '已交卷';
    if (s === 'ABSENT') return '缺考';
    if (s === 'EXPIRED') return '已过期';
    return Formatters.attemptStatusLabel(status);
  }

  private statusFg(status?: string): string {
    const s = (status ? status : '').toUpperCase();
    if (s === 'IN_PROGRESS' || s === 'STARTED') return Tokens.PRIMARY;
    if (s === 'GRADED') return Tokens.SUCCESS;
    if (s === 'SUBMITTED' || s === 'GRADING') return Tokens.WARNING;
    if (s === 'ABSENT') return Tokens.DANGER;
    return Tokens.TEXT_SECONDARY;
  }

  private statusBg(status?: string): string {
    const s = (status ? status : '').toUpperCase();
    if (s === 'IN_PROGRESS' || s === 'STARTED') return Tokens.PRIMARY_SOFT;
    if (s === 'GRADED') return Tokens.SUCCESS_SOFT;
    if (s === 'SUBMITTED' || s === 'GRADING') return Tokens.WARNING_SOFT;
    if (s === 'ABSENT') return Tokens.DANGER_SOFT;
    return Tokens.SURFACE_ALT;
  }

  private canStart(status?: string): boolean {
    const s = (status ? status : '').toUpperCase();
    return ['SUBMITTED', 'GRADED', 'REGISTERED', 'REJECTED', 'CANCELLED'].indexOf(s) < 0;
  }

  private accessModeText(mode?: string): string {
    switch ((mode ? mode : '').toUpperCase()) {
      case 'PAID': return '付费考试';
      case 'PASSWORD': return '密码考试';
      case 'VIP': return 'VIP 考试';
      case 'POINTS': return '积分考试';
      case 'QRCODE': return '扫码考试';
      case 'ORG_POSITION': return '部门考试';
      case 'REGISTER': return '报名考试';
      case 'APPROVAL': return '申报审核';
      case 'CLASS': return '班级考试';
      case 'FIXED': return '固定人群';
      default: return mode ? mode : '开放考试';
    }
  }

  private conditionText(exam: OpenExamSummary): string {
    if (exam.accessMode === 'REGISTER') return '请先报名';
    if (exam.accessMode === 'APPROVAL') return '报名审核中';
    return this.accessModeText(exam.accessMode);
  }

  private openRegistration(): void {
    const base = AppConfig.REGISTRATION_URL.endsWith('/')
      ? AppConfig.REGISTRATION_URL.slice(0, AppConfig.REGISTRATION_URL.length - 1)
      : AppConfig.REGISTRATION_URL;
    if (base.length === 0) {
      promptAction.showToast({ message: '报名入口未配置' });
      return;
    }
    const context = getContext(this) as common.UIAbilityContext;
    context.startAbility({ action: 'ohos.want.action.viewData', uri: base + '/campaigns' }).catch(() => {});
  }

  private async launchExam(exam: ExamSummary, result: boolean, password?: string): Promise<void> {
    try {
      const state = await repo.startExam(exam.id ? exam.id : '', password);
      if (result || state.status === 'SUBMITTED' || state.status === 'GRADED') {
        router.pushUrl({ url: 'pages/ResultPage', params: { attemptId: state.attemptId } });
      } else {
        router.pushUrl({ url: 'pages/ExamTakingPage', params: { examId: exam.id } });
      }
    } catch (e) {
      const message = (e as Error).message;
      if (!password && message.indexOf('密码') >= 0) {
        this.pendingExam = exam;
        this.pendingResult = result;
        this.passwordValue = '';
        this.showPassword = true;
      } else {
        promptAction.showToast({ message: message });
      }
    }
  }

  private confirmPassword(): void {
    if (this.passwordValue.length === 0) {
      promptAction.showToast({ message: '请输入考试密码' });
      return;
    }
    const target = this.pendingExam;
    const asResult = this.pendingResult;
    this.showPassword = false;
    this.launchExam(target, asResult, this.passwordValue);
  }

  private async startOpen(exam: OpenExamSummary): Promise<void> {
    if (exam.eligibility === 'NEED_PAYMENT') {
      try {
        await repo.payOpenExam(exam.id ? exam.id : '');
        promptAction.showToast({ message: '缴费成功' });
        await this.load();
        const assigned: ExamSummary = { id: exam.id, name: exam.name };
        this.launchExam(assigned, false);
      } catch (e) {
        promptAction.showToast({ message: (e as Error).message });
      }
      return;
    }
    if (exam.eligibility === 'READY_TO_START') {
      const assigned: ExamSummary = { id: exam.id, name: exam.name };
      this.launchExam(assigned, false);
      return;
    }
    if (exam.accessMode === 'REGISTER' || exam.accessMode === 'APPROVAL') {
      this.openRegistration();
      return;
    }
    promptAction.showToast({ message: this.conditionText(exam) });
  }

  build() {
    Stack() {
      Column() {
        Scroll() {
          Column({ space: 12 }) {
            GradientHero({ gradientStart: Tokens.PRIMARY, gradientEnd: Tokens.HERO_END }) {
              Column({ space: 6 }) {
                Text(Formatters.greeting() + '，同学')
                  .fontSize(21).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
                Text('欢迎回来，请按考试时间参加；支持断线续考，作答会自动保存。')
                  .fontSize(13).fontColor('#E0FFFFFF')
              }.alignItems(HorizontalAlign.Start).width('100%')
            }

            CardContainer() {
              Column({ space: 10 }) {
                Row({ space: 8 }) {
                  TextInput({ placeholder: '搜索考试名称', text: this.keyword })
                    .layoutWeight(1).height(44)
                    .backgroundColor(Tokens.SURFACE_ALT).borderRadius(Tokens.RADIUS_LG - 2)
                    .padding({ left: 12, right: 12 })
                    .onChange((value: string) => { this.keyword = value; })
                  Button('搜索')
                    .height(44).borderRadius(Tokens.RADIUS_MD)
                    .fontSize(13).fontColor('#FFFFFF')
                    .backgroundColor(Tokens.PRIMARY)
                    .onClick(() => { this.load(); })
                }.width('100%')

                Scroll() {
                  Row({ space: 8 }) {
                    this.chip('全部', this.paidFilter === '', () => { this.paidFilter = ''; this.load(); })
                    this.chip('免费', this.paidFilter === 'false', () => { this.paidFilter = 'false'; this.load(); })
                    this.chip('付费', this.paidFilter === 'true', () => { this.paidFilter = 'true'; this.load(); })
                    this.chip('最新', this.sort === 'startTime', () => { this.sort = 'startTime'; this.load(); })
                    this.chip('名称', this.sort === 'name', () => { this.sort = 'name'; this.load(); })
                    this.chip('价格↑', this.sort === 'priceAsc', () => { this.sort = 'priceAsc'; this.load(); })
                    this.chip('价格↓', this.sort === 'priceDesc', () => { this.sort = 'priceDesc'; this.load(); })
                  }
                }
                .scrollable(ScrollDirection.Horizontal)
                .scrollBar(BarState.Off)
                .width('100%')
              }.width('100%')
            }

            SectionHeader({ title: '我的考试' })

            if (this.loading) {
              LoadingView()
            } else if (this.error.length > 0) {
              ErrorBanner({ message: this.error })
            } else if (this.exams.length === 0) {
              EmptyView({ text: '暂无考试' })
            } else {
              ForEach(this.exams, (exam: ExamSummary, index: number) => {
                this.examCard(exam)
              }, (exam: ExamSummary, index: number) => index.toString())
            }

            if (this.openExams.length > 0) {
              SectionHeader({
                title: '开放考试',
                actionLabel: '刷新',
                onAction: () => { this.load(); }
              })
              ForEach(this.openExams, (exam: OpenExamSummary, index: number) => {
                this.openExamCard(exam)
              }, (exam: OpenExamSummary, index: number) => index.toString())
            }

            Row().height(20)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 16 })
        }
        .layoutWeight(1)
      }
      .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)

      if (this.showPassword) {
        this.passwordOverlay()
      }
    }
    .width('100%').height('100%')
  }

  @Builder
  chip(label: string, active: boolean, action: () => void) {
    Text(label)
      .fontSize(12)
      .fontColor(active ? '#FFFFFF' : Tokens.TEXT_SECONDARY)
      .backgroundColor(active ? Tokens.PRIMARY : Tokens.SURFACE)
      .borderRadius(Tokens.RADIUS_PILL)
      .padding({ left: 14, right: 14, top: 7, bottom: 7 })
      .onClick(action)
  }

  @Builder
  metaItem(label: string, value: string) {
    Column({ space: 2 }) {
      Text(label).fontSize(10).fontColor(Tokens.TEXT_TERTIARY)
      Text(value).fontSize(12).fontWeight(FontWeight.Medium).fontColor(Tokens.TEXT_SECONDARY).maxLines(1)
    }.alignItems(HorizontalAlign.Start)
  }

  @Builder
  gradientAction(label: string, action: () => void) {
    Stack({ alignContent: Alignment.Center }) {
      Text(label)
        .fontSize(13).fontWeight(FontWeight.Medium).fontColor('#FFFFFF')
    }
    .padding({ left: 16, right: 16, top: 9, bottom: 9 })
    .borderRadius(Tokens.RADIUS_MD)
    .linearGradient({
      angle: 135,
      colors: [[Tokens.GRADIENT_PRIMARY[0], 0], [Tokens.GRADIENT_PRIMARY[2], 1]]
    })
    .onClick(action)
  }

  @Builder
  softAction(label: string, action: () => void) {
    Text(label)
      .fontSize(13).fontWeight(FontWeight.Medium).fontColor(Tokens.PRIMARY)
      .padding({ left: 16, right: 16, top: 9, bottom: 9 })
      .borderRadius(Tokens.RADIUS_MD)
      .backgroundColor(Tokens.PRIMARY_SOFT)
      .onClick(action)
  }

  @Builder
  examCard(exam: ExamSummary) {
    CardContainer() {
      Column({ space: 6 }) {
        if ((exam.coverUrl ? exam.coverUrl : '').length > 0) {
          Image(exam.coverUrl ? exam.coverUrl : '')
            .width('100%').height(132).objectFit(ImageFit.Cover)
            .borderRadius(Tokens.RADIUS_LG)
            .margin({ bottom: 6 })
        }
        Row({ space: 8 }) {
          Text(exam.name ? exam.name : '').fontSize(16).fontWeight(FontWeight.Bold)
            .fontColor(Tokens.TEXT_PRIMARY).layoutWeight(1).maxLines(2)
          TagPill({
            label: this.statusLabel(exam.attemptStatus),
            fg: this.statusFg(exam.attemptStatus),
            bg: this.statusBg(exam.attemptStatus)
          })
        }.width('100%')

        if ((exam.paperName ? exam.paperName : '').length > 0 || exam.displayPrice !== undefined) {
          Row() {
            Text(exam.paperName ? exam.paperName : '未命名试卷')
              .fontSize(13).fontColor(Tokens.TEXT_SECONDARY)
            if (exam.displayPrice !== undefined) {
              Text(' · ¥' + Formatters.scoreText(exam.displayPrice))
                .fontSize(13).fontWeight(FontWeight.Medium).fontColor(Tokens.DANGER)
            }
          }.width('100%')
        }

        if ((exam.intro ? exam.intro : '').length > 0) {
          Text(exam.intro ? exam.intro : '')
            .fontSize(12).fontColor(Tokens.TEXT_SECONDARY).maxLines(2)
        }

        Row({ space: 14 }) {
          this.metaItem('开始', Formatters.epochToDateTime(exam.startEpochMillis))
          this.metaItem('时长', Formatters.durationText(exam.durationSeconds))
          if (exam.totalScore !== undefined) {
            this.metaItem('总分', Formatters.scoreText(exam.totalScore))
          }
          if (exam.score !== undefined) {
            this.metaItem('得分', Formatters.scoreText(exam.score))
          }
        }.width('100%').margin({ top: 4 })

        Row({ space: 10 }) {
          if (this.canStart(exam.attemptStatus)) {
            this.gradientAction('开始/继续作答', () => { this.launchExam(exam, false); })
          }
          if (exam.attemptStatus === 'SUBMITTED' || exam.attemptStatus === 'GRADED') {
            this.softAction('查看成绩', () => { this.launchExam(exam, true); })
          }
        }.width('100%').margin({ top: 6 })
      }.alignItems(HorizontalAlign.Start).width('100%')
    }
  }

  @Builder
  openExamCard(exam: OpenExamSummary) {
    CardContainer() {
      Row({ space: 10 }) {
        Column({ space: 5 }) {
          Text(exam.name ? exam.name : '').fontSize(16).fontWeight(FontWeight.Bold).fontColor(Tokens.TEXT_PRIMARY)
          Row() {
            Text(this.accessModeText(exam.accessMode)).fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
            if (exam.price !== undefined && exam.price > 0) {
              Text(' / ¥' + Formatters.scoreText(exam.price))
                .fontSize(12).fontWeight(FontWeight.Medium).fontColor(Tokens.DANGER)
            }
          }
          Text(Formatters.epochToDateTime(exam.startEpochMillis) + ' · ' + Formatters.durationText(exam.durationSeconds))
            .fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)

        Column({ space: 8 }) {
          if (exam.eligibility === 'READY_TO_START') {
            TagPill({ label: '可开始', fg: Tokens.SUCCESS, bg: Tokens.SUCCESS_SOFT })
          } else if (exam.eligibility === 'NEED_PAYMENT') {
            TagPill({ label: '待缴费', fg: Tokens.WARNING, bg: Tokens.WARNING_SOFT })
          } else {
            TagPill({ label: '需条件', fg: Tokens.TEXT_SECONDARY, bg: Tokens.SURFACE_ALT })
          }
          if (exam.eligibility === 'NEED_PAYMENT') {
            this.gradientAction('缴费进入', () => { this.startOpen(exam); })
          } else if (exam.eligibility === 'READY_TO_START') {
            this.gradientAction('开始作答', () => { this.startOpen(exam); })
          } else if (exam.accessMode === 'REGISTER' || exam.accessMode === 'APPROVAL') {
            this.softAction('去报名', () => { this.startOpen(exam); })
          } else {
            Text(this.conditionText(exam)).fontSize(12).fontColor(Tokens.TEXT_TERTIARY)
          }
        }.alignItems(HorizontalAlign.End)
      }.width('100%')
    }
  }

  @Builder
  passwordOverlay() {
    Column() {
      Blank().layoutWeight(1).onClick(() => { this.showPassword = false; })
      Column({ space: 12 }) {
        Text('请输入考试密码').fontSize(17).fontWeight(FontWeight.Bold).fontColor(Tokens.TEXT_PRIMARY)
        TextInput({ placeholder: '请输入考试密码', text: this.passwordValue })
          .type(InputType.Password)
          .height(46)
          .backgroundColor(Tokens.SURFACE_ALT)
          .borderRadius(Tokens.RADIUS_MD)
          .onChange((value: string) => { this.passwordValue = value; })
        Row({ space: 12 }) {
          Button('取消')
            .layoutWeight(1).height(44).borderRadius(Tokens.RADIUS_MD)
            .backgroundColor(Tokens.SURFACE_ALT).fontColor(Tokens.TEXT_SECONDARY)
            .onClick(() => { this.showPassword = false; })
          Button('进入考试')
            .layoutWeight(1).height(44).borderRadius(Tokens.RADIUS_MD)
            .fontColor('#FFFFFF')
            .backgroundColor(Tokens.PRIMARY)
            .onClick(() => { this.confirmPassword(); })
        }.width('100%')
      }
      .width('100%')
      .padding(20)
      .backgroundColor(Tokens.SURFACE)
      .borderRadius({ topLeft: Tokens.RADIUS_XL, topRight: Tokens.RADIUS_XL })
    }
    .width('100%').height('100%')
    .backgroundColor(Tokens.OVERLAY)
    .justifyContent(FlexAlign.End)
  }
}

// ============================ 练习 ============================

@Component
struct PracticeTab {
  @State sets: PracticeSet[] = [];
  @State stats: PracticeStatistics = {};
  @State loading: boolean = true;
  @State error: string = '';
  @State showPassword: boolean = false;
  @State passwordValue: string = '';
  @State pendingSet: PracticeSet = {};

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    try {
      this.sets = await repo.practiceSets();
      this.stats = await repo.practiceStatistics();
      this.error = '';
    } catch (e) {
      this.error = (e as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private modeText(mode?: string): string {
    switch ((mode ? mode : '').toUpperCase()) {
      case 'FIXED': return '固定试题';
      case 'RANDOM': return '随机抽题';
      case 'SHUFFLE': return '顺序随机';
      default: return '在线练习';
    }
  }

  private openSet(set: PracticeSet): void {
    if (set.unlocked === false) {
      const reason = set.lockReason ? set.lockReason : '';
      if (reason.indexOf('密码') >= 0) {
        this.pendingSet = set;
        this.passwordValue = '';
        this.showPassword = true;
        return;
      }
      promptAction.showToast({ message: reason.length > 0 ? reason : '该练习需要先满足进入条件' });
      if (reason.indexOf('购买') >= 0) {
        router.pushUrl({
          url: 'pages/MemberPage',
          params: { bizType: 'PRACTICE', bizId: set.id }
        });
      }
      return;
    }
    if (set.accessMode === 'POINTS') {
      promptAction.showToast({ message: '将消耗 ' + String(set.pointsCost ? set.pointsCost : 0) + ' 积分进入' });
    }
    this.startSet(set);
  }

  private async startSet(set: PracticeSet, password?: string): Promise<void> {
    try {
      const record = await repo.practiceStart(set.id ? set.id : '', password);
      promptAction.showToast({ message: '已进入练习' });
      router.pushUrl({
        url: 'pages/PracticeTakingPage',
        params: { recordId: record.recordId, setId: record.setId ? record.setId : set.id }
      });
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message });
    }
  }

  private confirmPassword(): void {
    const target = this.pendingSet;
    this.showPassword = false;
    this.startSet(target, this.passwordValue);
  }

  build() {
    Stack() {
      Scroll() {
        Column({ space: 12 }) {
          GradientHero({ gradientStart: Tokens.PRIMARY, gradientEnd: Tokens.ACCENT }) {
            Column({ space: 5 }) {
              Text('在线练习').fontSize(21).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
              Text('逐题判定、自动收录错题，坚持每天进步一点。')
                .fontSize(13).fontColor('#E0FFFFFF')
            }.alignItems(HorizontalAlign.Start).width('100%')
          }

          SectionHeader({
            title: '练习概览',
            actionLabel: '详细统计',
            onAction: () => { router.pushUrl({ url: 'pages/PracticeStatsPage' }); }
          })
          Row({ space: 10 }) {
            Column() {
              StatTile({ label: '练习次数', value: String(this.stats.totalRecords ? this.stats.totalRecords : 0), tint: Tokens.PRIMARY, bg: Tokens.PRIMARY_SOFT })
            }.layoutWeight(1)
            Column() {
              StatTile({ label: '完成', value: String(this.stats.finishedRecords ? this.stats.finishedRecords : 0), tint: Tokens.ACCENT, bg: Tokens.ACCENT_SOFT })
            }.layoutWeight(1)
            Column() {
              StatTile({ label: '正确率', value: Math.round((this.stats.averageAccuracy ? this.stats.averageAccuracy : 0) * 100) + '%', tint: Tokens.SUCCESS, bg: Tokens.SUCCESS_SOFT })
            }.layoutWeight(1)
            Column() {
              StatTile({ label: '题量', value: String(this.stats.totalQuestions ? this.stats.totalQuestions : 0), tint: Tokens.VIOLET, bg: Tokens.VIOLET_SOFT })
            }.layoutWeight(1)
          }.width('100%')

          SectionHeader({ title: '练习题库' })

          if (this.loading) {
            LoadingView()
          } else if (this.error.length > 0) {
            ErrorBanner({ message: this.error })
          } else if (this.sets.length === 0) {
            EmptyView({ text: '暂无练习题集' })
          } else {
            ForEach(this.sets, (set: PracticeSet, index: number) => {
              this.setCard(set)
            }, (set: PracticeSet, index: number) => index.toString())
          }

          Row().height(20)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
      }
      .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)

      if (this.showPassword) {
        this.passwordOverlay()
      }
    }
    .width('100%').height('100%')
  }

  @Builder
  setCard(set: PracticeSet) {
    CardContainer() {
      Row({ space: 12 }) {
        IconTile({ label: '练', fg: Tokens.ACCENT, bg: Tokens.ACCENT_SOFT, tileSize: 46, fontSize: 19 })
        Column({ space: 4 }) {
          Text(set.name ? set.name : (set.title ? set.title : ''))
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor(Tokens.TEXT_PRIMARY).maxLines(2)
          if ((set.description ? set.description : '').length > 0) {
            Text(set.description ? set.description : '')
              .fontSize(12).fontColor(Tokens.TEXT_SECONDARY).maxLines(1)
          }
          Row({ space: 6 }) {
            TagPill({ label: this.modeText(set.mode), fg: Tokens.ACCENT, bg: Tokens.ACCENT_SOFT })
            Text(String(set.questionCount ? set.questionCount : 0) + ' 题')
              .fontSize(11).fontColor(Tokens.TEXT_SECONDARY)
            if (set.durationSeconds !== undefined && set.durationSeconds > 0) {
              Text('限时 ' + Math.ceil((set.durationSeconds ? set.durationSeconds : 0) / 60) + ' 分钟')
                .fontSize(11).fontColor(Tokens.TEXT_SECONDARY)
            }
            if (set.pointsCost !== undefined && set.pointsCost > 0) {
              Text(String(set.pointsCost ? set.pointsCost : 0) + ' 积分').fontSize(11).fontColor(Tokens.AMBER)
            }
            if (set.price !== undefined && set.price > 0) {
              Text('¥' + Formatters.scoreText(set.price)).fontSize(11).fontColor(Tokens.DANGER)
            }
          }.width('100%')
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)

        if (set.unlocked === false) {
          TagPill({
            label: set.lockReason ? set.lockReason.substring(0, Math.min(6, set.lockReason.length)) : '未开放',
            fg: Tokens.WARNING, bg: Tokens.WARNING_SOFT
          })
        } else if (set.joined === true) {
          TagPill({ label: '继续练习', fg: Tokens.SUCCESS, bg: Tokens.SUCCESS_SOFT })
        } else {
          TagPill({ label: '开始练习', fg: Tokens.PRIMARY, bg: Tokens.PRIMARY_SOFT })
        }
      }.width('100%')
      .onClick(() => this.openSet(set))
    }
  }

  @Builder
  passwordOverlay() {
    Column() {
      Blank().layoutWeight(1).onClick(() => { this.showPassword = false; })
      Column({ space: 12 }) {
        Text('请输入练习密码').fontSize(17).fontWeight(FontWeight.Bold).fontColor(Tokens.TEXT_PRIMARY)
        TextInput({ placeholder: '请输入练习密码', text: this.passwordValue })
          .type(InputType.Password)
          .height(46)
          .backgroundColor(Tokens.SURFACE_ALT)
          .borderRadius(Tokens.RADIUS_MD)
          .onChange((value: string) => { this.passwordValue = value; })
        Row({ space: 12 }) {
          Button('取消')
            .layoutWeight(1).height(44).borderRadius(Tokens.RADIUS_MD)
            .backgroundColor(Tokens.SURFACE_ALT).fontColor(Tokens.TEXT_SECONDARY)
            .onClick(() => { this.showPassword = false; })
          Button('进入练习')
            .layoutWeight(1).height(44).borderRadius(Tokens.RADIUS_MD)
            .fontColor('#FFFFFF')
            .backgroundColor(Tokens.ACCENT)
            .onClick(() => { this.confirmPassword(); })
        }.width('100%')
      }
      .width('100%')
      .padding(20)
      .backgroundColor(Tokens.SURFACE)
      .borderRadius({ topLeft: Tokens.RADIUS_XL, topRight: Tokens.RADIUS_XL })
    }
    .width('100%').height('100%')
    .backgroundColor(Tokens.OVERLAY)
    .justifyContent(FlexAlign.End)
  }
}

// ============================ 我的 ============================

@Component
struct ProfileTab {
  @Link activeTab: number;
  @State displayName: string = '同学';
  @State username: string = '';

  aboutToAppear(): void {
    if (SessionStore.userJson) {
      try {
        const user = JSON.parse(SessionStore.userJson) as User;
        this.displayName = user.realName ? user.realName : (user.username ? user.username : '同学');
        this.username = user.username ? user.username : '';
      } catch (e) {
        this.displayName = '同学';
      }
    }
  }

  build() {
    Scroll() {
      Column({ space: 2 }) {
        GradientHero({ gradientStart: Tokens.PRIMARY, gradientEnd: Tokens.HERO_END }) {
          Row({ space: 14 }) {
            Stack({ alignContent: Alignment.Center }) {
              Circle({ width: 64, height: 64 }).fill('#33FFFFFF')
              Text(this.displayName.substring(0, 1))
                .fontSize(25).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
            }.width(64).height(64)
            Column({ space: 3 }) {
              Text(this.displayName).fontSize(20).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
              Text(this.username.length > 0 ? this.username : '在线考试学员')
                .fontSize(13).fontColor('#D9FFFFFF')
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            Text('学员')
              .fontSize(11).fontColor('#FFFFFF')
              .backgroundColor('#2EFFFFFF').borderRadius(Tokens.RADIUS_PILL)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          }.width('100%')
        }

        SectionHeader({ title: '学习与成绩' })
        CardContainer() {
          Column() {
            ListRow({
              title: '我的成绩', tileLabel: '绩', tileFg: Tokens.AMBER, tileBg: Tokens.AMBER_SOFT,
              onTap: () => { router.pushUrl({ url: 'pages/ScorePage' }); }
            })
            DividerLine()
            ListRow({
              title: '成绩申诉', tileLabel: '诉', tileFg: Tokens.CORAL, tileBg: Tokens.CORAL_SOFT,
              onTap: () => { router.pushUrl({ url: 'pages/AppealPage' }); }
            })
            DividerLine()
            ListRow({
              title: '考试日历', tileLabel: '日', tileFg: Tokens.ACCENT, tileBg: Tokens.ACCENT_SOFT,
              onTap: () => { router.pushUrl({ url: 'pages/CalendarPage' }); }
            })
            DividerLine()
            ListRow({
              title: '消息通知', tileLabel: '信', tileFg: Tokens.SKY, tileBg: Tokens.SKY_SOFT,
              onTap: () => { router.pushUrl({ url: 'pages/NotificationPage' }); }
            })
            DividerLine()
            ListRow({
              title: '考试组进度', tileLabel: '组', tileFg: Tokens.VIOLET, tileBg: Tokens.VIOLET_SOFT,
              onTap: () => { router.pushUrl({ url: 'pages/ExamGroupPage' }); }
            })
            DividerLine()
            ListRow({
              title: '排行榜', tileLabel: '榜', tileFg: Tokens.PRIMARY, tileBg: Tokens.PRIMARY_SOFT,
              onTap: () => { router.pushUrl({ url: 'pages/RankingPage' }); }
            })
          }.width('100%')
        }

        SectionHeader({ title: '练习与成长' })
        CardContainer() {
          Column() {
            ListRow({
              title: '在线练习', tileLabel: '练', tileFg: Tokens.ACCENT, tileBg: Tokens.ACCENT_SOFT,
              onTap: () => { this.activeTab = 2; }
            })
            DividerLine()
            ListRow({
              title: '我的错题集', tileLabel: '错', tileFg: Tokens.DANGER, tileBg: Tokens.DANGER_SOFT,
              onTap: () => { router.pushUrl({ url: 'pages/WrongPage' }); }
            })
            DividerLine()
            ListRow({
              title: '练习统计', tileLabel: '统', tileFg: Tokens.SKY, tileBg: Tokens.SKY_SOFT,
              onTap: () => { router.pushUrl({ url: 'pages/PracticeStatsPage' }); }
            })
            DividerLine()
            ListRow({
              title: '会员中心', tileLabel: '会', tileFg: Tokens.AMBER, tileBg: Tokens.AMBER_SOFT,
              onTap: () => { router.pushUrl({ url: 'pages/MemberPage' }); }
            })
            DividerLine()
            ListRow({
              title: '个人分析', tileLabel: '析', tileFg: Tokens.VIOLET, tileBg: Tokens.VIOLET_SOFT,
              onTap: () => { router.pushUrl({ url: 'pages/AnalysisPage' }); }
            })
            DividerLine()
            ListRow({
              title: '班级', tileLabel: '班', tileFg: Tokens.CORAL, tileBg: Tokens.CORAL_SOFT,
              onTap: () => { router.pushUrl({ url: 'pages/ClassPage' }); }
            })
          }.width('100%')
        }

        SectionHeader({ title: '账号与安全' })
        CardContainer() {
          Column() {
            ListRow({
              title: '人脸核验', tileLabel: '脸', tileFg: Tokens.SKY, tileBg: Tokens.SKY_SOFT,
              onTap: () => { router.pushUrl({ url: 'pages/FacePage' }); }
            })
            DividerLine()
            ListRow({
              title: '设备管理', tileLabel: '备', tileFg: Tokens.SLATE, tileBg: Tokens.SLATE_SOFT,
              onTap: () => { router.pushUrl({ url: 'pages/DevicePage' }); }
            })
            DividerLine()
            ListRow({
              title: '修改密码', tileLabel: '密', tileFg: Tokens.PRIMARY, tileBg: Tokens.PRIMARY_SOFT,
              onTap: () => { router.pushUrl({ url: 'pages/ResetPasswordPage' }); }
            })
          }.width('100%')
        }

        Row().height(18)
        Text('退出登录')
          .width('100%').height(50)
          .textAlign(TextAlign.Center)
          .fontSize(15).fontWeight(FontWeight.Medium).fontColor(Tokens.DANGER)
          .backgroundColor(Tokens.DANGER_SOFT)
          .borderRadius(Tokens.RADIUS_LG)
          .onClick(() => {
            AlertDialog.show({
              title: '退出登录',
              message: '确认退出当前账号？',
              primaryButton: { value: '取消', action: () => {} },
              secondaryButton: {
                value: '退出',
                action: () => {
                  SessionStore.clear().then(() => {
                    router.replaceUrl({ url: 'pages/LoginPage' });
                  });
                }
              }
            });
          })
        Row().height(20)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Tokens.BACKGROUND)
  }
}
