import { repo } from '../common/repo/CandidateRepository';
import { Teacher } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { CardContainer, LoadingView, ErrorBanner } from '../components/Common';

@Entry
@Component
struct TeacherPage {
  @State list: Teacher[] = [];
  @State loading: boolean = true;
  @State error: string = '';

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    try {
      this.list = await repo.showcaseTeachers();
      this.error = '';
    } catch (e) {
      this.error = (e as Error).message;
    } finally {
      this.loading = false;
    }
  }

  build() {
    Column() {
      if (this.loading) {
        LoadingView()
      } else if (this.error.length > 0) {
        Column() { ErrorBanner({ message: this.error }) }.margin(16)
      } else {
        Scroll() {
          Column({ space: 8 }) {
            ForEach(this.list, (teacher: Teacher) => {
              CardContainer() {
                Row({ space: 14 }) {
                  if (teacher.avatarUrl) {
                    Image(teacher.avatarUrl).width(56).height(56).borderRadius(28).objectFit(ImageFit.Cover)
                  } else {
                    Text((teacher.name ? teacher.name : '?').substring(0, 1))
                      .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
                      .width(56).height(56).textAlign(TextAlign.Center)
                      .backgroundColor(Tokens.PRIMARY).borderRadius(28)
                  }
                  Column({ space: 4 }) {
                    Text(teacher.name ? teacher.name : '').fontSize(16).fontWeight(FontWeight.Medium)
                    if (teacher.title) {
                      Text(teacher.title).fontSize(12).fontColor(Tokens.PRIMARY)
                    }
                    if (teacher.intro) {
                      Text(teacher.intro).fontSize(12).fontColor(Tokens.TEXT_SECONDARY).maxLines(3)
                    }
                  }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                }.width('100%')
              }
            }, (teacher: Teacher, index: number) => index.toString())
          }.padding(16)
        }.layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }
}
