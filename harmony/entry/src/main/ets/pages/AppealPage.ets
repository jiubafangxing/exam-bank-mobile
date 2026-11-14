import promptAction from '@ohos.promptAction';
import { repo } from '../common/repo/CandidateRepository';
import { AppealItem } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { CardContainer, TagPill, LoadingView, ErrorBanner } from '../components/Common';

@Entry
@Component
struct AppealPage {
  @State list: AppealItem[] = [];
  @State examId: string = '';
  @State reason: string = '';
  @State loading: boolean = true;
  @State error: string = '';

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    try {
      this.list = await repo.appeals();
      this.error = '';
    } catch (e) {
      this.error = (e as Error).message;
    } finally {
      this.loading = false;
    }
  }

  async submit(): Promise<void> {
    if (this.examId.length === 0 || this.reason.length === 0) {
      promptAction.showToast({ message: '请填写完整' });
      return;
    }
    try {
      await repo.createAppeal(this.examId, this.reason);
      promptAction.showToast({ message: '已提交' });
      this.examId = '';
      this.reason = '';
      this.load();
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message });
    }
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        CardContainer() {
          Column({ space: 8 }) {
            Text('发起申诉').fontSize(15).fontWeight(FontWeight.Medium)
            TextInput({ placeholder: '考试 ID', text: this.examId })
              .width('100%').height(44).backgroundColor(Tokens.SURFACE_ALT).borderRadius(8)
              .onChange((v: string) => { this.examId = v; })
            TextInput({ placeholder: '申诉理由', text: this.reason })
              .width('100%').height(44).backgroundColor(Tokens.SURFACE_ALT).borderRadius(8)
              .onChange((v: string) => { this.reason = v; })
            Button('提交').width('100%').height(44).borderRadius(999).backgroundColor(Tokens.PRIMARY)
              .onClick(() => { this.submit(); })
          }.alignItems(HorizontalAlign.Start).width('100%')
        }

        if (this.loading) {
          LoadingView()
        } else if (this.error.length > 0) {
          ErrorBanner({ message: this.error })
        } else {
          ForEach(this.list, (appeal: AppealItem) => {
            CardContainer() {
              Column({ space: 4 }) {
                Row() {
                  Text(appeal.examName ? appeal.examName : (appeal.examId ? appeal.examId : '考试')).fontSize(15).layoutWeight(1)
                  TagPill({ label: appeal.status ? appeal.status : '' })
                }.width('100%')
                if (appeal.reason) {
                  Text(appeal.reason).fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
                }
                if (appeal.reply) {
                  Text('回复：' + appeal.reply).fontSize(12).fontColor(Tokens.SUCCESS)
                }
              }.alignItems(HorizontalAlign.Start).width('100%')
            }
          }, (appeal: AppealItem, index: number) => index.toString())
        }
      }.padding(16)
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }
}
