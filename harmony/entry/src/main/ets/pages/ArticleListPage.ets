import router from '@ohos.router';
import { repo } from '../common/repo/CandidateRepository';
import { Article } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { CardContainer, LoadingView, ErrorBanner } from '../components/Common';

@Entry
@Component
struct ArticleListPage {
  @State list: Article[] = [];
  @State loading: boolean = true;
  @State error: string = '';

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    try {
      this.list = await repo.articles();
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
            ForEach(this.list, (article: Article) => {
              CardContainer() {
                Row({ space: 12 }) {
                  if (article.coverUrl) {
                    Image(article.coverUrl).width(64).height(64).borderRadius(10).objectFit(ImageFit.Cover)
                  }
                  Column({ space: 4 }) {
                    Text(article.title ? article.title : '').fontSize(15).fontWeight(FontWeight.Medium).maxLines(2)
                    if (article.summary) {
                      Text(article.summary).fontSize(12).fontColor(Tokens.TEXT_SECONDARY).maxLines(2)
                    }
                  }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                }.width('100%')
              }
              .onClick(() => {
                router.pushUrl({ url: 'pages/ArticleDetailPage', params: { articleId: article.id } });
              })
            }, (article: Article, index: number) => index.toString())
          }.padding(16)
        }.layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }
}
