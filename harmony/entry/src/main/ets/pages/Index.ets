import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import common from '@ohos.app.ability.common';
import { repo } from '../common/repo/CandidateRepository';
import { SessionStore } from '../common/storage/SessionStore';
import {
  ExamSummary, OpenExamSummary, PracticeSet, PracticeStatistics,
  HomeComponent, HomeItem, User
} from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { AppConfig } from '../common/config/AppConfig';
import { Formatters } from '../common/util/Formatters';
import {
  CardContainer, TagPill, EmptyView, LoadingView, ErrorBanner, SectionTitle
} from '../components/Common';

@Entry
@Component
struct Index {
  @State tabIndex: number = 0;

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.tabIndex }) {
      TabContent() {
        HomeTab({ tabIndex: $tabIndex })
      }.tabBar(this.tabBar('首页', 0))

      TabContent() {
        ExamsTab()
      }.tabBar(this.tabBar('考试', 1))

      TabContent() {
        PracticeTab()
      }.tabBar(this.tabBar('练习', 2))

      TabContent() {
        ProfileTab({ tabIndex: $tabIndex })
      }.tabBar(this.tabBar('我的', 3))
    }
    .onChange((index: number) => {
      this.tabIndex = index;
    })
    .barHeight(56)
    .backgroundColor(Tokens.BACKGROUND)
  }

  @Builder
  tabBar(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(12)
        .fontColor(this.tabIndex === index ? Tokens.PRIMARY : Tokens.TEXT_SECONDARY)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}

// ============================ 首页 ============================

@Component
struct HomeTab {
  @Link tabIndex: number;
  @State components: HomeComponent[] = [];
  @State loading: boolean = true;
  @State error: string = '';
  @State displayName: string = '同学';

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    try {
      if (SessionStore.userJson) {
        const user = JSON.parse(SessionStore.userJson) as User;
        this.displayName = user.realName ? user.realName : (user.username ? user.username : '同学');
      }
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
        Column({ space: 4 }) {
          Text(Formatters.greeting() + '，' + this.displayName).fontSize(20).fontWeight(FontWeight.Bold).fontColor(Tokens.TEXT_PRIMARY)
          Text('考试、练习、班级与学习内容都在这里。').fontSize(13).fontColor(Tokens.TEXT_SECONDARY)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ top: 8 })

        CardContainer() {
          Column({ space: 14 }) {
            Row() {
              this.quickCell('我的考试', () => { this.tabIndex = 1; })
              this.quickCell('在线练习', () => { this.tabIndex = 2; })
              this.quickCell('错题集', () => { router.pushUrl({ url: 'pages/WrongPage' }); })
              this.quickCell('班级', () => { router.pushUrl({ url: 'pages/ClassPage' }); })
            }.width('100%')
            Row() {
              this.quickCell('考试组', () => { router.pushUrl({ url: 'pages/ExamGroupPage' }); })
              this.quickCell('排行榜', () => { router.pushUrl({ url: 'pages/RankingPage' }); })
              this.quickCell('文章', () => { router.pushUrl({ url: 'pages/ArticleListPage' }); })
              this.quickCell('教师风采', () => { router.pushUrl({ url: 'pages/TeacherPage' }); })
            }.width('100%')
          }.width('100%')
        }

        if (AppConfig.REGISTRATION_URL.length > 0) {
          CardContainer() {
            Row() {
              Column({ space: 4 }) {
                Text('考试报名').fontSize(16).fontWeight(FontWeight.Medium).fontColor(Tokens.TEXT_PRIMARY)
                Text('查看招录公告、岗位与报名进度').fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              Text('›').fontSize(20).fontColor(Tokens.TEXT_TERTIARY)
            }.width('100%')
          }
          .onClick(() => {
            const base = AppConfig.REGISTRATION_URL.endsWith('/') ? AppConfig.REGISTRATION_URL : AppConfig.REGISTRATION_URL + '/';
            const context = getContext(this) as common.UIAbilityContext;
            context.startAbility({ action: 'ohos.want.action.viewData', uri: base + 'campaigns' }).catch(() => {});
          })
        }

        if (this.loading) {
          LoadingView()
        } else if (this.error.length > 0) {
          ErrorBanner({ message: this.error })
        } else {
          ForEach(this.components, (component: HomeComponent, index: number) => {
            if (component.componentType === 'BANNER') {
              this.bannerView(component)
            } else if (component.componentType === 'NAV') {
              this.navView(component)
            } else {
              SectionTitle({ title: component.title ? component.title : '' })
              CardContainer() {
                Column() {
                  ForEach(component.items ? component.items : [], (item: HomeItem, i: number) => {
                    Row({ space: 12 }) {
                      if (item.coverUrl || item.avatarUrl) {
                        Image(item.coverUrl ? item.coverUrl : (item.avatarUrl ? item.avatarUrl : ''))
                          .width(48).height(48).borderRadius(10).objectFit(ImageFit.Cover)
                      }
                      Column({ space: 2 }) {
                        Text(item.title ? item.title : (item.name ? item.name : '')).fontSize(15).fontColor(Tokens.TEXT_PRIMARY).maxLines(1)
                        Text(item.summary ? item.summary : (item.intro ? item.intro : (item.description ? item.description : '')))
                          .fontSize(12).fontColor(Tokens.TEXT_SECONDARY).maxLines(1)
                      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                    }
                    .width('100%')
                    .padding({ top: 10, bottom: 10 })
                  }, (item: HomeItem, i: number) => i.toString())
                }.width('100%')
              }
            }
          }, (component: HomeComponent, index: number) => index.toString())
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Tokens.BACKGROUND)
  }

  @Builder
  quickCell(label: string, action: () => void) {
    Column({ space: 6 }) {
      Text(label.substring(0, 1))
        .fontSize(15).fontWeight(FontWeight.Bold).fontColor(Tokens.PRIMARY)
        .width(42).height(42).textAlign(TextAlign.Center)
        .backgroundColor(Tokens.PRIMARY_SOFT).borderRadius(12)
      Text(label).fontSize(12).fontColor(Tokens.TEXT_PRIMARY).maxLines(1)
    }
    .layoutWeight(1)
    .onClick(action)
  }

  @Builder
  bannerView(component: HomeComponent) {
    Scroll() {
      Row({ space: 12 }) {
        ForEach(component.items ? component.items : [], (item: HomeItem, i: number) => {
          Column() {
            Image(item.imageUrl ? item.imageUrl : (item.coverUrl ? item.coverUrl : ''))
              .width(280).height(130).objectFit(ImageFit.Cover).borderRadius({ topLeft: 14, topRight: 14 })
            Text(item.title ? item.title : (item.name ? item.name : ''))
              .fontSize(14).fontWeight(FontWeight.Medium).fontColor(Tokens.TEXT_PRIMARY)
              .padding(10).maxLines(1)
          }
          .width(280)
          .backgroundColor(Tokens.SURFACE)
          .borderRadius(14)
        }, (item: HomeItem, i: number) => i.toString())
      }
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }

  @Builder
  navView(component: HomeComponent) {
    CardContainer() {
      Row() {
        ForEach(component.items ? component.items : [], (item: HomeItem, i: number) => {
          Column({ space: 6 }) {
            Text((item.name ? item.name : (item.title ? item.title : '·')).substring(0, 1))
              .fontSize(15).fontWeight(FontWeight.Bold).fontColor(Tokens.PRIMARY)
              .width(40).height(40).textAlign(TextAlign.Center)
              .backgroundColor(Tokens.PRIMARY_SOFT).borderRadius(12)
            Text(item.name ? item.name : (item.title ? item.title : '')).fontSize(12).maxLines(1)
          }
          .layoutWeight(1)
        }, (item: HomeItem, i: number) => i.toString())
      }.width('100%')
    }
  }
}

// ============================ 考试 ============================

@Component
struct ExamsTab {
  @State filter: number = 0;
  @State exams: ExamSummary[] = [];
  @State openExams: OpenExamSummary[] = [];
  @State loading: boolean = true;
  @State error: string = '';

  private filters: string[] = ['全部', '进行中', '已结束', '开放报名'];

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    try {
      this.exams = await repo.exams();
      this.openExams = await repo.openExams();
      this.error = '';
    } catch (e) {
      this.error = (e as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private filtered(): ExamSummary[] {
    if (this.filter === 1) {
      return this.exams.filter((e: ExamSummary) => ['STARTED', 'IN_PROGRESS', 'ASSIGNED'].indexOf(e.attemptStatus ? e.attemptStatus : '') >= 0);
    }
    if (this.filter === 2) {
      return this.exams.filter((e: ExamSummary) => ['SUBMITTED', 'GRADING', 'GRADED', 'EXPIRED', 'ABSENT'].indexOf(e.attemptStatus ? e.attemptStatus : '') >= 0);
    }
    return this.exams;
  }

  build() {
    Column({ space: 8 }) {
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.filters, (label: string, index: number) => {
            Text(label)
              .fontSize(13)
              .fontColor(this.filter === index ? '#FFFFFF' : Tokens.TEXT_SECONDARY)
              .backgroundColor(this.filter === index ? Tokens.PRIMARY : Tokens.SURFACE)
              .borderRadius(999)
              .padding({ left: 14, right: 14, top: 7, bottom: 7 })
              .onClick(() => { this.filter = index; })
          }, (label: string, index: number) => index.toString())
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .padding({ left: 16 })

      if (this.loading) {
        LoadingView()
      } else if (this.error.length > 0) {
        ErrorBanner({ message: this.error }).margin(16)
      } else {
        Scroll() {
          Column({ space: 8 }) {
            if (this.filter === 3) {
              ForEach(this.openExams, (exam: OpenExamSummary) => {
                CardContainer() {
                  Row() {
                    Column({ space: 4 }) {
                      Text(exam.name ? exam.name : '').fontSize(16).fontWeight(FontWeight.Medium).fontColor(Tokens.TEXT_PRIMARY)
                      Text(Formatters.epochToDateTime(exam.startEpochMillis) + ' · ' + Formatters.durationText(exam.durationSeconds))
                        .fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
                    }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                    Column({ space: 6 }) {
                      Text('¥' + Formatters.scoreText(exam.price)).fontSize(15).fontColor(Tokens.DANGER)
                      TagPill({ label: exam.payStatus === 'PAID' ? '已报名' : '报名', fg: Tokens.SUCCESS, bg: Tokens.SUCCESS_SOFT })
                        .onClick(async () => {
                          try {
                            await repo.payOpenExam(exam.id ? exam.id : '');
                            promptAction.showToast({ message: '报名成功' });
                          } catch (e) {
                            promptAction.showToast({ message: (e as Error).message });
                          }
                        })
                    }.alignItems(HorizontalAlign.End)
                  }.width('100%')
                }
              }, (exam: OpenExamSummary, index: number) => index.toString())
            } else {
              ForEach(this.filtered(), (exam: ExamSummary) => {
                CardContainer() {
                  Column({ space: 6 }) {
                    Row() {
                      Text(exam.name ? exam.name : '').fontSize(16).fontWeight(FontWeight.Medium).fontColor(Tokens.TEXT_PRIMARY).layoutWeight(1).maxLines(1)
                      TagPill({
                        label: Formatters.attemptStatusLabel(exam.attemptStatus),
                        fg: ['STARTED', 'IN_PROGRESS'].indexOf(exam.attemptStatus ? exam.attemptStatus : '') >= 0 ? Tokens.PRIMARY : Tokens.TEXT_SECONDARY,
                        bg: ['STARTED', 'IN_PROGRESS'].indexOf(exam.attemptStatus ? exam.attemptStatus : '') >= 0 ? Tokens.PRIMARY_SOFT : Tokens.SURFACE_ALT
                      })
                    }.width('100%')
                    if (exam.paperName) {
                      Text(exam.paperName).fontSize(13).fontColor(Tokens.TEXT_SECONDARY)
                    }
                    Row({ space: 16 }) {
                      Text(Formatters.epochToDateTime(exam.startEpochMillis)).fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
                      Text(Formatters.durationText(exam.durationSeconds)).fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
                      if (exam.score !== undefined) {
                        Text('得分 ' + Formatters.scoreText(exam.score)).fontSize(12).fontColor(Tokens.PRIMARY)
                      }
                    }
                  }.alignItems(HorizontalAlign.Start).width('100%')
                }
                .onClick(() => {
                  router.pushUrl({ url: 'pages/ExamTakingPage', params: { examId: exam.id } });
                })
              }, (exam: ExamSummary, index: number) => index.toString())
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ top: 8 })
    .backgroundColor(Tokens.BACKGROUND)
  }
}

// ============================ 练习 ============================

@Component
struct PracticeTab {
  @State sets: PracticeSet[] = [];
  @State stats: PracticeStatistics = {};
  @State loading: boolean = true;
  @State error: string = '';

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

  build() {
    Scroll() {
      Column({ space: 12 }) {
        CardContainer() {
          Row() {
            this.statCell('练习次数', String(this.stats.totalRecords ? this.stats.totalRecords : 0))
            this.statCell('完成', String(this.stats.finishedRecords ? this.stats.finishedRecords : 0))
            this.statCell('正确率', Math.round((this.stats.averageAccuracy ? this.stats.averageAccuracy : 0) * 100) + '%')
            this.statCell('题量', String(this.stats.totalQuestions ? this.stats.totalQuestions : 0))
          }.width('100%')
        }

        if (this.loading) {
          LoadingView()
        } else if (this.error.length > 0) {
          ErrorBanner({ message: this.error })
        } else {
          ForEach(this.sets, (set: PracticeSet) => {
            CardContainer() {
              Row() {
                Column({ space: 4 }) {
                  Text(set.name ? set.name : '').fontSize(16).fontWeight(FontWeight.Medium).fontColor(Tokens.TEXT_PRIMARY)
                  Text((set.questionCount ? set.questionCount : 0) + ' 题').fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                TagPill({ label: '开始练习' })
              }.width('100%')
            }
            .onClick(() => {
              router.pushUrl({ url: 'pages/PracticeTakingPage', params: { setId: set.id } });
            })
          }, (set: PracticeSet, index: number) => index.toString())

          Text('查看练习统计')
            .fontSize(13).fontColor(Tokens.PRIMARY)
            .onClick(() => { router.pushUrl({ url: 'pages/PracticeStatsPage' }); })
        }
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Tokens.BACKGROUND)
  }

  @Builder
  statCell(label: string, value: string) {
    Column({ space: 2 }) {
      Text(value).fontSize(20).fontWeight(FontWeight.Bold).fontColor(Tokens.PRIMARY)
      Text(label).fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
    }.layoutWeight(1)
  }
}

// ============================ 我的 ============================

@Component
struct ProfileTab {
  @Link tabIndex: number;
  @State displayName: string = '同学';
  @State username: string = '';

  aboutToAppear(): void {
    if (SessionStore.userJson) {
      const user = JSON.parse(SessionStore.userJson) as User;
      this.displayName = user.realName ? user.realName : (user.username ? user.username : '同学');
      this.username = user.username ? user.username : '';
    }
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        CardContainer() {
          Row({ space: 16 }) {
            Text(this.displayName.substring(0, 1))
              .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
              .width(56).height(56).textAlign(TextAlign.Center)
              .backgroundColor(Tokens.PRIMARY).borderRadius(28)
            Column({ space: 4 }) {
              Text(this.displayName).fontSize(18).fontWeight(FontWeight.Bold).fontColor(Tokens.TEXT_PRIMARY)
              Text(this.username).fontSize(13).fontColor(Tokens.TEXT_SECONDARY)
            }.alignItems(HorizontalAlign.Start)
          }.width('100%')
        }

        CardContainer() {
          Column() {
            this.link('我的成绩', 'pages/ScorePage')
            this.link('成绩申诉', 'pages/AppealPage')
            this.link('考试日历', 'pages/CalendarPage')
            this.link('消息通知', 'pages/NotificationPage')
            this.link('考试组进度', 'pages/ExamGroupPage')
            this.link('排行榜', 'pages/RankingPage')
          }.width('100%')
        }

        CardContainer() {
          Column() {
            this.link('在线练习', 'pages/Index')
            this.link('我的错题集', 'pages/WrongPage')
            this.link('练习统计', 'pages/PracticeStatsPage')
            this.link('会员中心', 'pages/MemberPage')
            this.link('个人分析', 'pages/AnalysisPage')
            this.link('班级', 'pages/ClassPage')
            this.link('人脸核验', 'pages/FacePage')
            this.link('设备管理', 'pages/DevicePage')
            this.link('修改密码', 'pages/ResetPasswordPage')
          }.width('100%')
        }

        Button('退出登录')
          .width('100%').height(48).borderRadius(999)
          .backgroundColor(Tokens.DANGER_SOFT).fontColor(Tokens.DANGER)
          .onClick(async () => {
            await SessionStore.clear();
            router.replaceUrl({ url: 'pages/LoginPage' });
          })
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Tokens.BACKGROUND)
  }

  @Builder
  link(title: string, url: string) {
    Row() {
      Text(title).fontSize(15).fontColor(Tokens.TEXT_PRIMARY)
      Blank()
      Text('›').fontSize(18).fontColor(Tokens.TEXT_TERTIARY)
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .onClick(() => {
      if (url === 'pages/Index') {
        this.tabIndex = 2;
      } else {
        router.pushUrl({ url: url });
      }
    })
  }
}
