import promptAction from '@ohos.promptAction';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import { repo } from '../common/repo/CandidateRepository';
import { FaceStatus, FaceLog } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { CardContainer, LoadingView, ErrorBanner, KeyValueRow, SectionTitle } from '../components/Common';

@Entry
@Component
struct FacePage {
  @State status: FaceStatus = {};
  @State logs: FaceLog[] = [];
  @State photoUrl: string = '';
  @State verifyPhotoUrl: string = '';
  @State examId: string = '';
  @State liveness: string = 'PASS';
  @State loading: boolean = true;
  @State uploading: boolean = false;
  @State error: string = '';

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    try {
      this.status = await repo.faceStatus();
      this.logs = await repo.faceLogs();
      this.error = '';
    } catch (e) {
      this.error = (e as Error).message;
    } finally {
      this.loading = false;
    }
  }

  private async pickImage(): Promise<ArrayBuffer | undefined> {
    const photoPicker = new picker.PhotoViewPicker();
    const result = await photoPicker.select({
      maxSelectNumber: 1,
      MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE
    });
    if (!result.photoUris || result.photoUris.length === 0) return undefined;
    const uri = result.photoUris[0];
    const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
    const stat = fs.fstatSync(file.fd);
    const buffer = new ArrayBuffer(stat.size);
    fs.readSync(file.fd, buffer);
    fs.closeSync(file);
    return buffer;
  }

  private async pickAndUpload(assign: (url: string) => void): Promise<void> {
    this.uploading = true;
    try {
      const data = await this.pickImage();
      if (!data) return;
      const resp = await repo.faceUpload(data, 'face.jpg');
      assign(resp.url ? resp.url : '');
      promptAction.showToast({ message: '照片已上传' });
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message });
    } finally {
      this.uploading = false;
    }
  }

  async collect(): Promise<void> {
    if (this.photoUrl.length === 0) {
      promptAction.showToast({ message: '请先上传照片' });
      return;
    }
    try {
      await repo.faceCollect(this.photoUrl);
      promptAction.showToast({ message: '已提交，等待审核' });
      await this.load();
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message });
    }
  }

  async verify(): Promise<void> {
    try {
      await repo.faceVerify(
        this.verifyPhotoUrl.length > 0 ? this.verifyPhotoUrl : undefined,
        this.examId.length > 0 ? this.examId : undefined,
        this.liveness
      );
      promptAction.showToast({ message: '已核验' });
      await this.load();
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message });
    }
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        if (this.loading) {
          LoadingView()
        } else if (this.error.length > 0) {
          ErrorBanner({ message: this.error })
        } else {
          CardContainer() {
            Column() {
              KeyValueRow({ label: '照片状态', value: this.status.photo ? (this.status.photo.status ? this.status.photo.status : '-') : (this.status.collected === true ? '已采集' : '未采集') })
              KeyValueRow({ label: '最近核验', value: this.status.latestVerify ? (this.status.latestVerify.result ? this.status.latestVerify.result : '-') : (this.status.verified === true ? 'PASS' : '无') })
              KeyValueRow({ label: '是否必需', value: this.status.required === true ? '是' : '否' })
              if (this.status.livenessRequired === true) {
                KeyValueRow({ label: '活体检测', value: '需完成' })
              }
              if (this.status.message && this.status.message.length > 0) {
                Text(this.status.message).fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
              }
            }.width('100%')
          }

          CardContainer() {
            Column({ space: 8 }) {
              Text('照片采集').fontSize(14).fontWeight(FontWeight.Medium).width('100%')
              Row({ space: 12 }) {
                Button(this.uploading ? '上传中…' : '拍照/选择照片')
                  .height(42).backgroundColor(Tokens.SURFACE).fontColor(Tokens.PRIMARY)
                  .enabled(!this.uploading)
                  .onClick(() => { this.pickAndUpload((url: string) => { this.photoUrl = url; }); })
                Button('提交采集').height(42).backgroundColor(Tokens.PRIMARY)
                  .onClick(() => { this.collect(); })
              }
              if (this.photoUrl.length > 0) {
                Image(this.photoUrl).width('100%').height(160).borderRadius(10).objectFit(ImageFit.Cover)
              }
            }.alignItems(HorizontalAlign.Start).width('100%')
          }

          CardContainer() {
            Column({ space: 8 }) {
              Text('考前核验').fontSize(14).fontWeight(FontWeight.Medium).width('100%')
              TextInput({ placeholder: '考试 ID（可选）', text: this.examId })
                .width('100%').height(42).backgroundColor(Tokens.SURFACE_ALT).borderRadius(8)
                .onChange((v: string) => { this.examId = v; })
              Button(this.uploading ? '上传中…' : '现场拍照/选择照片')
                .height(42).backgroundColor(Tokens.SURFACE).fontColor(Tokens.PRIMARY)
                .enabled(!this.uploading)
                .onClick(() => { this.pickAndUpload((url: string) => { this.verifyPhotoUrl = url; }); })
              if (this.verifyPhotoUrl.length > 0) {
                Image(this.verifyPhotoUrl).width('100%').height(160).borderRadius(10).objectFit(ImageFit.Cover)
              }
              Row({ space: 8 }) {
                Text('活体检测').fontSize(13).fontColor(Tokens.TEXT_SECONDARY)
                Text('检测通过')
                  .fontSize(12)
                  .fontColor(this.liveness === 'PASS' ? '#FFFFFF' : Tokens.TEXT_SECONDARY)
                  .backgroundColor(this.liveness === 'PASS' ? Tokens.PRIMARY : Tokens.SURFACE)
                  .borderRadius(999).padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .onClick(() => { this.liveness = 'PASS'; })
                Text('未通过')
                  .fontSize(12)
                  .fontColor(this.liveness === 'FAIL' ? '#FFFFFF' : Tokens.TEXT_SECONDARY)
                  .backgroundColor(this.liveness === 'FAIL' ? Tokens.PRIMARY : Tokens.SURFACE)
                  .borderRadius(999).padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .onClick(() => { this.liveness = 'FAIL'; })
              }
              Button('开始核验')
                .width('100%').height(44).borderRadius(999).backgroundColor(Tokens.SUCCESS)
                .onClick(() => { this.verify(); })
            }.alignItems(HorizontalAlign.Start).width('100%')
          }

          SectionTitle({ title: '核验记录' })
          CardContainer() {
            Column() {
              ForEach(this.logs, (log: FaceLog) => {
                Row() {
                  Column({ space: 2 }) {
                    Text(log.result ? log.result : '-').fontSize(13)
                    Text((log.verifiedAt ? log.verifiedAt : (log.createdAt ? log.createdAt : '')) +
                      (log.livenessStatus ? ' · 活体 ' + log.livenessStatus : ''))
                      .fontSize(11).fontColor(Tokens.TEXT_SECONDARY)
                  }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                  Text(log.similarity !== undefined ? String(log.similarity) + '%' : '-')
                    .fontSize(13).fontColor(Tokens.PRIMARY)
                }.width('100%').padding({ top: 4, bottom: 4 })
              }, (log: FaceLog, i: number) => i.toString())
            }.width('100%')
          }
        }
      }.padding(16)
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }
}
