import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { repo } from '../common/repo/CandidateRepository';
import { SessionStore } from '../common/storage/SessionStore';
import { LoginResponse } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { PrimaryButton, SecondaryButton, CardContainer, AuthHero } from '../components/Common';

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
      Column() {
        AuthHero({ title: '短信登录', subtitle: '输入手机号与验证码，快速进入学习', glyph: '信' })

        Column() {
          CardContainer() {
            Column({ space: 12 }) {
              TextInput({ placeholder: '手机号', text: this.phone })
                .type(InputType.PhoneNumber)
                .width('100%').height(48)
                .backgroundColor(Tokens.SURFACE_ALT)
                .border({ width: 1, color: Tokens.BORDER })
                .borderRadius(Tokens.RADIUS_LG - 2)
                .padding({ left: 12, right: 12 })
                .onChange((value: string) => { this.phone = value; })
              Row({ space: 10 }) {
                TextInput({ placeholder: '验证码', text: this.code })
                  .type(InputType.Number)
                  .layoutWeight(1).height(48)
                  .backgroundColor(Tokens.SURFACE_ALT)
                  .border({ width: 1, color: Tokens.BORDER })
                  .borderRadius(Tokens.RADIUS_LG - 2)
                  .padding({ left: 12, right: 12 })
                  .onChange((value: string) => { this.code = value; })
                SecondaryButton({ label: '发送验证码', onTap: () => { this.sendOtp(); } })
              }.width('100%')
              PrimaryButton({ label: '登录', loading: this.submitting, onTap: () => { this.login(); } })
                .margin({ top: 6 })
              Text('密码登录').fontSize(13).fontColor(Tokens.PRIMARY)
                .onClick(() => { router.pushUrl({ url: 'pages/LoginPage' }); })
            }.alignItems(HorizontalAlign.Start).width('100%')
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 14, bottom: 24 })
      }.width('100%')
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }
}
