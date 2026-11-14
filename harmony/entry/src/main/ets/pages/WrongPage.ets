import promptAction from '@ohos.promptAction';
import { repo } from '../common/repo/CandidateRepository';
import { WrongQuestion, WrongOption } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { Formatters } from '../common/util/Formatters';
import {
  CardContainer, TagPill, LoadingView, ErrorBanner, SmallAction, EmptyView
} from '../components/Common';
import { RichContent, htmlToText } from '../components/RichContent';

@Entry
@Component
struct WrongPage {
  @State source: string = '';
  @State reviewOnly: boolean = false;
  @State list: WrongQuestion[] = [];
  @State loading: boolean = true;
  @State error: string = '';
  @State expandedIds: string[] = [];

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    this.loading = true;
    try {
      if (this.source.length > 0) {
        this.list = await repo.wrongQuestions(this.source, !this.reviewOnly);
      } else {
        this.list = await repo.wrongQuestions(undefined, !this.reviewOnly);
      }
      this.error = '';
    } catch (e) {
      this.error = (e as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private typeOf(item: WrongQuestion): string {
    if (item.typeCode && item.typeCode.length > 0) return item.typeCode;
    return item.questionType ? item.questionType : '';
  }

  private isExpanded(item: WrongQuestion): boolean {
    return this.expandedIds.indexOf(item.id ? item.id : '') >= 0;
  }

  private toggleExpand(item: WrongQuestion): void {
    const id = item.id ? item.id : '';
    const next = this.expandedIds.slice();
    const pos = next.indexOf(id);
    if (pos >= 0) next.splice(pos, 1); else next.push(id);
    this.expandedIds = next;
  }

  async toggleMaster(item: WrongQuestion): Promise<void> {
    try {
      if (item.mastered === true) {
        await repo.unmasterWrong(item.id ? item.id : '');
      } else {
        await repo.masterWrong(item.id ? item.id : '');
      }
      promptAction.showToast({ message: item.mastered === true ? '已标记待复习' : '已标记掌握' });
      await this.load();
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message });
    }
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        this.chip('全部', this.source === '', () => { this.source = ''; this.load(); })
        this.chip('考试', this.source === 'EXAM', () => { this.source = 'EXAM'; this.load(); })
        this.chip('练习', this.source === 'PRACTICE', () => { this.source = 'PRACTICE'; this.load(); })
        Blank()
        SmallAction({
          label: this.reviewOnly ? '看全部' : '只看待复习',
          onTap: () => { this.reviewOnly = !this.reviewOnly; this.load(); }
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

      if (this.loading) {
        LoadingView()
      } else if (this.error.length > 0) {
        Column() { ErrorBanner({ message: this.error }) }.margin(16)
      } else if (this.list.length === 0) {
        EmptyView({ text: '太棒了，暂无错题' })
      } else {
        Scroll() {
          Column({ space: 8 }) {
            ForEach(this.list, (item: WrongQuestion, index: number) => {
              this.wrongCard(item)
            }, (item: WrongQuestion, index: number) => index.toString())
            Row().height(20)
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
      .borderRadius(Tokens.RADIUS_PILL)
      .padding({ left: 14, right: 14, top: 7, bottom: 7 })
      .onClick(action)
  }

  @Builder
  wrongCard(item: WrongQuestion) {
    CardContainer() {
      Column({ space: 8 }) {
        Row({ space: 6 }) {
          TagPill({
            label: Formatters.questionTypeLabel(this.typeOf(item)),
            fg: Tokens.typeColor(this.typeOf(item)).fg,
            bg: Tokens.typeColor(this.typeOf(item)).bg
          })
          TagPill({ label: '错 ' + String(item.wrongCount ? item.wrongCount : 0) + ' 次', fg: Tokens.DANGER, bg: Tokens.DANGER_SOFT })
          Blank()
          TagPill({
            label: item.mastered === true ? '已掌握' : '待复习',
            fg: item.mastered === true ? Tokens.SUCCESS : Tokens.WARNING,
            bg: item.mastered === true ? Tokens.SUCCESS_SOFT : Tokens.WARNING_SOFT
          })
        }.width('100%')

        Row() {
          Column() {
            if (item.stem && item.stem.length > 0) {
              RichContent({ content: item.stem ? item.stem : '', fontSize: 15 })
            } else {
              Text('题目内容').fontSize(15).fontColor(Tokens.TEXT_PRIMARY)
            }
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)
          Text(this.isExpanded(item) ? '收起' : '展开')
            .fontSize(12).fontColor(Tokens.PRIMARY)
            .margin({ left: 8 })
        }
        .width('100%')
        .onClick(() => { this.toggleExpand(item); })

        if (item.lastWrongAt && item.lastWrongAt.length > 0) {
          Text('最近答错：' + (item.lastWrongAt ? item.lastWrongAt : '')).fontSize(11).fontColor(Tokens.TEXT_TERTIARY)
        }

        if (this.isExpanded(item)) {
          if (item.options && item.options.length > 0) {
            Column({ space: 6 }) {
              ForEach(item.options, (option: WrongOption, i: number) => {
                Row({ space: 9 }) {
                  Text(option.key ? option.key : '')
                    .fontSize(11).fontWeight(FontWeight.Bold)
                    .fontColor(option.correct === true ? '#FFFFFF' : Tokens.TEXT_SECONDARY)
                    .width(24).height(24).textAlign(TextAlign.Center)
                    .backgroundColor(option.correct === true ? Tokens.SUCCESS : Tokens.SURFACE)
                    .borderRadius(12)
                  Text(htmlToText(option.text ? option.text : option.content))
                    .fontSize(14).fontColor(Tokens.TEXT_PRIMARY).layoutWeight(1)
                  if (option.correct === true) {
                    Text('正确答案').fontSize(11).fontColor(Tokens.SUCCESS)
                  }
                }
                .width('100%')
                .padding(10)
                .backgroundColor(option.correct === true ? Tokens.SUCCESS_SOFT : Tokens.SURFACE_ALT)
                .borderRadius(Tokens.RADIUS_MD)
              }, (option: WrongOption, i: number) => i.toString())
            }.width('100%')
          }

          if ((item.answerText ? item.answerText : (item.expectedText ? item.expectedText : '')).length > 0) {
            Text('答案：' + (item.answerText ? item.answerText : (item.expectedText ? item.expectedText : '')))
              .fontSize(13).fontColor(Tokens.TEXT_PRIMARY)
          }

          if (item.analysis && item.analysis.length > 0) {
            Column({ space: 4 }) {
              Text('解析').fontSize(11).fontColor(Tokens.TEXT_SECONDARY)
              RichContent({ content: item.analysis ? item.analysis : '', fontSize: 13 })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding(12)
            .backgroundColor(Tokens.SURFACE_ALT)
            .borderRadius(Tokens.RADIUS_MD)
          }
        }

        Row() {
          SmallAction({
            label: item.mastered === true ? '标记待复习' : '我已掌握',
            color: item.mastered === true ? Tokens.TEXT_SECONDARY : Tokens.SUCCESS,
            bg: item.mastered === true ? Tokens.SURFACE_ALT : Tokens.SUCCESS_SOFT,
            onTap: () => { this.toggleMaster(item); }
          })
        }.width('100%')
      }.alignItems(HorizontalAlign.Start).width('100%')
    }
  }
}
