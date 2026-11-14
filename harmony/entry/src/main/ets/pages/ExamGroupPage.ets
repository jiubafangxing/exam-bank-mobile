import { repo } from '../common/repo/CandidateRepository';
import { ExamGroup, ExamGroupItem } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { Formatters } from '../common/util/Formatters';
import { CardContainer, TagPill, LoadingView, ErrorBanner } from '../components/Common';

@Entry
@Component
struct ExamGroupPage {
  @State list: ExamGroup[] = [];
  @State collapsed: string[] = [];
  @State loading: boolean = true;
  @State error: string = '';

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    try {
      this.list = await repo.examGroups();
      this.error = '';
    } catch (e) {
      this.error = (e as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private isOpen(id?: string): boolean {
    return this.collapsed.indexOf(id ? id : '') < 0;
  }

  private toggle(id?: string): void {
    const key = id ? id : '';
    const next = this.collapsed.slice();
    const pos = next.indexOf(key);
    if (pos >= 0) next.splice(pos, 1);
    else next.push(key);
    this.collapsed = next;
  }

  private statusTag(status?: string): string {
    switch (status) {
      case 'PASSED': return '已通过';
      case 'FAILED': return '未通过';
      case 'AVAILABLE': return '可参加';
      case 'LOCKED': return '未解锁';
      case 'NOT_PUBLISHED': return '成绩未发布';
      default: return status ? status : '';
    }
  }

  private statusColor(status?: string): string {
    switch (status) {
      case 'PASSED': return Tokens.SUCCESS;
      case 'FAILED': return Tokens.DANGER;
      case 'AVAILABLE': return Tokens.PRIMARY;
      case 'LOCKED':
      case 'NOT_PUBLISHED': return Tokens.WARNING;
      default: return Tokens.TEXT_SECONDARY;
    }
  }

  private statusBg(status?: string): string {
    switch (status) {
      case 'PASSED': return Tokens.SUCCESS_SOFT;
      case 'FAILED': return Tokens.DANGER_SOFT;
      case 'AVAILABLE': return Tokens.PRIMARY_SOFT;
      case 'LOCKED':
      case 'NOT_PUBLISHED': return Tokens.WARNING_SOFT;
      default: return Tokens.SURFACE_ALT;
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
            ForEach(this.list, (group: ExamGroup) => {
              CardContainer() {
                Column({ space: 6 }) {
                  Row({ space: 8 }) {
                    Column({ space: 4 }) {
                      Text(group.name ? group.name : '').fontSize(16).fontWeight(FontWeight.Medium)
                      Text((group.groupType === 'ALL_PASS' ? '通关：全部通过' : '闯关：按顺序解锁') +
                        ' · 及格线 ' + Formatters.scoreText(group.passScore))
                        .fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
                    }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                    if (group.passed === true) {
                      TagPill({ label: '已通关', fg: Tokens.SUCCESS, bg: Tokens.SUCCESS_SOFT })
                    } else {
                      TagPill({
                        label: String(group.passedCount ? group.passedCount : 0) + '/' +
                          String(group.requiredCount ? group.requiredCount : (group.examCount ? group.examCount : 0)),
                        fg: (group.passedCount ? group.passedCount : 0) > 0 ? Tokens.WARNING : Tokens.PRIMARY,
                        bg: (group.passedCount ? group.passedCount : 0) > 0 ? Tokens.WARNING_SOFT : Tokens.PRIMARY_SOFT
                      })
                    }
                  }.width('100%')
                  .onClick(() => { this.toggle(group.id); })

                  if (this.isOpen(group.id)) {
                    if (group.items && group.items.length > 0) {
                      Column() {
                        ForEach(group.items ? group.items : [], (item: ExamGroupItem) => {
                          Row({ space: 10 }) {
                            Text(String(item.sortNo ? item.sortNo : 0))
                              .fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
                              .width(24).height(24).textAlign(TextAlign.Center)
                              .backgroundColor(Tokens.SURFACE_ALT).borderRadius(12)
                            Column({ space: 2 }) {
                              Text(item.examName ? item.examName : (item.examId ? item.examId : '')).fontSize(14)
                              Text('及格 ' + Formatters.scoreText(item.passScore)).fontSize(11).fontColor(Tokens.TEXT_SECONDARY)
                            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                            TagPill({
                              label: this.statusTag(item.status),
                              fg: this.statusColor(item.status),
                              bg: this.statusBg(item.status)
                            })
                          }.width('100%').padding({ top: 6, bottom: 6 })
                        }, (item: ExamGroupItem, i: number) => i.toString())
                      }.width('100%')
                    } else {
                      Progress({
                        value: group.completedCount ? group.completedCount : 0,
                        total: Math.max(group.examCount ? group.examCount : 1, 1),
                        type: ProgressType.Linear
                      }).color(Tokens.PRIMARY).width('100%')
                      Text('共 ' + String(group.examCount ? group.examCount : 0) + ' 场 · 已完成 ' +
                        String(group.completedCount ? group.completedCount : 0) + ' 场')
                        .fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
                    }
                  }
                }.alignItems(HorizontalAlign.Start).width('100%')
              }
            }, (group: ExamGroup, index: number) => index.toString())
          }.padding(16)
        }.layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }
}
