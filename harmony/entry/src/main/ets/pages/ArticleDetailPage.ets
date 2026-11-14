import router from '@ohos.router';
import { repo } from '../common/repo/CandidateRepository';
import { Article, ExamRouteParams } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { CardContainer, LoadingView, ErrorBanner } from '../components/Common';
import { RichContent } from '../components/RichContent';

@Entry
@Component
struct ArticleDetailPage {
  @State article: Article = {};
  @State loading: boolean = true;
  @State error: string = '';

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    const params = router.getParams() as ExamRouteParams;
    try {
      this.article = await repo.article(params && params.articleId ? params.articleId : '');
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
        ErrorBanner({ message: this.error }).margin(16)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            Text(this.article.title ? this.article.title : '').fontSize(20).fontWeight(FontWeight.Bold).width('100%')
            if (this.article.createdAt) {
              Text(this.article.createdAt).fontSize(12).fontColor(Tokens.TEXT_SECONDARY).width('100%')
            }
            CardContainer() {
              RichContent({ content: this.article.content ? this.article.content : (this.article.summary ? this.article.summary : '暂无内容'), fontSize: 15 })
            }
          }.padding(16)
        }.layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }
}
