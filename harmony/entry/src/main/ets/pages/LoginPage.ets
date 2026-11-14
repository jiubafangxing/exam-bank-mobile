import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { repo } from '../common/repo/CandidateRepository';
import { SessionStore } from '../common/storage/SessionStore';
import { LoginResponse } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { PrimaryButton } from '../components/Common';

@Entry
@Component
struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State submitting: boolean = false;
  @State smsEnabled: boolean = false;

  aboutToAppear(): void {
    this.loadMeta();
  }

  async loadMeta(): Promise<void> {
    try {
      const meta = await repo.meta();
      this.smsEnabled = meta.smsEnabled === true;
    } catch (e) {
      // 忽略 meta 失败，仍可账号登录
    }
  }

  async login(): Promise<void> {
    if (this.username.length === 0 || this.password.length === 0) {
      promptAction.showToast({ message: '请输入账号和密码' });
      return;
    }
    this.submitting = true;
    try {
      const resp: LoginResponse = await repo.login(this.username, this.password);
      if (!resp.token || !resp.user) {
        throw new Error('登录失败');
      }
      await SessionStore.save(resp.token, JSON.stringify(resp.user));
      if (resp.requiresTenantSelection === true && !resp.tenantId) {
        router.pushUrl({ url: 'pages/TenantPage' });
      } else {
        router.replaceUrl({ url: 'pages/Index' });
      }
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message });
    } finally {
      this.submitting = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Column({ space: 6 }) {
          Text('在线考试').fontSize(26).fontWeight(FontWeight.Bold).fontColor(Tokens.TEXT_PRIMARY)
          Text('登录后参加考试、练习与学习').fontSize(14).fontColor(Tokens.TEXT_SECONDARY)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ top: 48, bottom: 24 })

        Text('账号').fontSize(13).fontColor(Tokens.TEXT_SECONDARY).width('100%')
        TextInput({ placeholder: '请输入账号', text: this.username })
          .width('100%').height(46).backgroundColor(Tokens.SURFACE).borderRadius(10)
          .onChange((value: string) => { this.username = value; })

        Text('密码').fontSize(13).fontColor(Tokens.TEXT_SECONDARY).width('100%')
        TextInput({ placeholder: '请输入密码', text: this.password })
          .type(InputType.Password)
          .width('100%').height(46).backgroundColor(Tokens.SURFACE).borderRadius(10)
          .onChange((value: string) => { this.password = value; })

        PrimaryButton({ label: '登录', loading: this.submitting, onTap: () => { this.login(); } })
          .margin({ top: 8 })

        Row() {
          if (this.smsEnabled) {
            Text('短信登录').fontSize(13).fontColor(Tokens.PRIMARY)
              .onClick(() => { router.pushUrl({ url: 'pages/SmsLoginPage' }); })
          }
          Blank()
          Text('注册账号').fontSize(13).fontColor(Tokens.PRIMARY)
            .onClick(() => { router.pushUrl({ url: 'pages/RegisterPage' }); })
          Blank()
          Text('忘记密码').fontSize(13).fontColor(Tokens.PRIMARY)
            .onClick(() => { router.pushUrl({ url: 'pages/ResetPasswordPage' }); })
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 24, right: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Tokens.BACKGROUND)
  }
}
