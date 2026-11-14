import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { repo } from '../common/repo/CandidateRepository';
import { SessionStore } from '../common/storage/SessionStore';
import { LoginResponse } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { PrimaryButton } from '../components/Common';

@Entry
@Component
struct SmsLoginPage {
  @State phone: string = '';
  @State code: string = '';
  @State submitting: boolean = false;

  async sendOtp(): Promise<void> {
    if (this.phone.length === 0) {
      promptAction.showToast({ message: '请输入手机号' });
      return;
    }
    try {
      await repo.sendOtp(this.phone, 'login');
      promptAction.showToast({ message: '验证码已发送' });
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message });
    }
  }

  async login(): Promise<void> {
    if (this.phone.length === 0 || this.code.length === 0) {
      promptAction.showToast({ message: '请输入手机号和验证码' });
      return;
    }
    this.submitting = true;
    try {
      const resp: LoginResponse = await repo.smsLogin(this.phone, this.code);
      if (!resp.token || !resp.user) throw new Error('登录失败');
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
        Text('短信登录').fontSize(26).fontWeight(FontWeight.Bold).width('100%').padding({ top: 48 })
        Text('输入手机号与验证码').fontSize(14).fontColor(Tokens.TEXT_SECONDARY).width('100%')

        TextInput({ placeholder: '手机号', text: this.phone })
          .type(InputType.PhoneNumber).width('100%').height(46).backgroundColor(Tokens.SURFACE).borderRadius(10)
          .onChange((value: string) => { this.phone = value; })

        Row({ space: 12 }) {
          TextInput({ placeholder: '验证码', text: this.code })
            .type(InputType.Number).layoutWeight(1).height(46).backgroundColor(Tokens.SURFACE).borderRadius(10)
            .onChange((value: string) => { this.code = value; })
          Button('发送验证码').height(44).fontSize(13)
            .backgroundColor(Tokens.SURFACE).fontColor(Tokens.PRIMARY)
            .onClick(() => { this.sendOtp(); })
        }.width('100%')

        PrimaryButton({ label: '登录', loading: this.submitting, onTap: () => { this.login(); } })
          .margin({ top: 8 })
      }
      .width('100%')
      .padding({ left: 24, right: 24 })
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }
}
