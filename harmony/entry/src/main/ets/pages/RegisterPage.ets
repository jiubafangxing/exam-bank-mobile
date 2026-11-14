import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { repo } from '../common/repo/CandidateRepository';
import { SessionStore } from '../common/storage/SessionStore';
import { LoginResponse } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { PrimaryButton } from '../components/Common';

@Entry
@Component
struct RegisterPage {
  @State username: string = '';
  @State password: string = '';
  @State realName: string = '';
  @State phone: string = '';
  @State submitting: boolean = false;

  async register(): Promise<void> {
    if (this.username.length === 0 || this.password.length === 0) {
      promptAction.showToast({ message: '请输入账号和密码' });
      return;
    }
    this.submitting = true;
    try {
      const resp: LoginResponse = await repo.register(this.username, this.password, this.realName, this.phone);
      if (!resp.token || !resp.user) throw new Error('注册失败');
      await SessionStore.save(resp.token, JSON.stringify(resp.user));
      router.replaceUrl({ url: 'pages/Index' });
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message });
    } finally {
      this.submitting = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Text('创建账号').fontSize(26).fontWeight(FontWeight.Bold).width('100%').padding({ top: 48 })
        Text('注册后即可参加考试').fontSize(14).fontColor(Tokens.TEXT_SECONDARY).width('100%')

        TextInput({ placeholder: '账号', text: this.username }).width('100%').height(46).backgroundColor(Tokens.SURFACE).borderRadius(10)
          .onChange((v: string) => { this.username = v; })
        TextInput({ placeholder: '密码', text: this.password }).type(InputType.Password).width('100%').height(46).backgroundColor(Tokens.SURFACE).borderRadius(10)
          .onChange((v: string) => { this.password = v; })
        TextInput({ placeholder: '姓名', text: this.realName }).width('100%').height(46).backgroundColor(Tokens.SURFACE).borderRadius(10)
          .onChange((v: string) => { this.realName = v; })
        TextInput({ placeholder: '手机号', text: this.phone }).type(InputType.PhoneNumber).width('100%').height(46).backgroundColor(Tokens.SURFACE).borderRadius(10)
          .onChange((v: string) => { this.phone = v; })

        PrimaryButton({ label: '注册', loading: this.submitting, onTap: () => { this.register(); } })
          .margin({ top: 8 })
      }
      .width('100%')
      .padding({ left: 24, right: 24 })
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }
}
