import promptAction from '@ohos.promptAction';
import { repo } from '../common/repo/CandidateRepository';
import { WrongQuestion } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { Formatters } from '../common/util/Formatters';
import { CardContainer, TagPill, LoadingView, ErrorBanner } from '../components/Common';

@Entry
@Component
struct WrongPage {
  @State includeMastered: boolean = false;
  @State list: WrongQuestion[] = [];
  @State loading: boolean = true;
  @State error: string = '';

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    this.loading = true;
    try {
      this.list = await repo.wrongQuestions(this.includeMastered);
      this.error = '';
    } catch (e) {
      this.error = (e as Error).message;
    } finally {
      this.loading = false;
    }
  }

  async toggle(item: WrongQuestion): Promise<void> {
    try {
      if (item.mastered === true) {
        await repo.unmasterWrong(item.id ? item.id : '');
      } else {
        await repo.masterWrong(item.id ? item.id : '');
      }
      this.load();
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message });
    }
  }

  build() {
    Column() {
      Row() {
        Text('包含已掌握').fontSize(13).fontColor(Tokens.TEXT_SECONDARY)
        Toggle({ type: ToggleType.Switch, isOn: this.includeMastered })
          .onChange((on: boolean) => { this.includeMastered = on; this.load(); })
      }.width('100%').padding(16)

      if (this.loading) {
        LoadingView()
      } else if (this.error.length > 0) {
        ErrorBanner({ message: this.error }).margin(16)
      } else {
        Scroll() {
          Column({ space: 8 }) {
            ForEach(this.list, (item: WrongQuestion) => {
              CardContainer() {
                Column({ space: 6 }) {
                  Row({ space: 8 }) {
                    TagPill({ label: Formatters.questionTypeLabel(item.questionType) })
                    Text('错 ' + String(item.wrongCount ? item.wrongCount : 0) + ' 次').fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
                    Blank()
                    Text(item.mastered === true ? '取消掌握' : '标记掌握')
                      .fontSize(12)
                      .fontColor(item.mastered === true ? Tokens.TEXT_SECONDARY : Tokens.PRIMARY)
                      .onClick(() => { this.toggle(item); })
                  }.width('100%')
                  Text(item.stem ? item.stem : '题目内容').fontSize(15).maxLines(3)
                  if (item.mastered === true) {
                    TagPill({ label: '已掌握', fg: Tokens.SUCCESS, bg: Tokens.SUCCESS_SOFT })
                  }
                }.alignItems(HorizontalAlign.Start).width('100%')
              }
            }, (item: WrongQuestion, index: number) => index.toString())
          }.padding({ left: 16, right: 16, bottom: 16 })
        }.layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }
}
