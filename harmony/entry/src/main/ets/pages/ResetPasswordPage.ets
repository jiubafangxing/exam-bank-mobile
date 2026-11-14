import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { repo } from '../common/repo/CandidateRepository';
import { Tokens } from '../common/theme/Tokens';
import { PrimaryButton, SecondaryButton, CardContainer, AuthHero } from '../components/Common';

@Entry
@Component
struct ResetPasswordPage {
  @State phone: string = '';
  @State code: string = '';
  @State password: string = '';
  @State submitting: boolean = false;

  async sendOtp(): Promise<void> {
    if (this.phone.length === 0) {
      promptAction.showToast({ message: '请输入手机号' });
      return;
    }
    try {
      await repo.sendOtp(this.phone, 'reset');
      promptAction.showToast({ message: '验证码已发送' });
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message });
    }
  }

  async reset(): Promise<void> {
    if (this.phone.length === 0 || this.code.length === 0 || this.password.length === 0) {
      promptAction.showToast({ message: '请完整填写' });
      return;
    }
    this.submitting = true;
    try {
      await repo.resetPassword(this.phone, this.code, this.password);
      promptAction.showToast({ message: '密码已重置，请登录' });
      router.replaceUrl({ url: 'pages/LoginPage' });
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message });
    } finally {
      this.submitting = false;
    }
  }

  build() {
    Scroll() {
      Column() {
        AuthHero({ title: '重置密码', subtitle: '通过手机号验证后设置新密码', glyph: '密' })

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
                .onChange((v: string) => { this.phone = v; })
              Row({ space: 10 }) {
                TextInput({ placeholder: '验证码', text: this.code })
                  .type(InputType.Number)
                  .layoutWeight(1).height(48)
                  .backgroundColor(Tokens.SURFACE_ALT)
                  .border({ width: 1, color: Tokens.BORDER })
                  .borderRadius(Tokens.RADIUS_LG - 2)
                  .padding({ left: 12, right: 12 })
                  .onChange((v: string) => { this.code = v; })
                SecondaryButton({ label: '发送验证码', onTap: () => { this.sendOtp(); } })
              }.width('100%')
              TextInput({ placeholder: '新密码', text: this.password })
                .type(InputType.Password)
                .width('100%').height(48)
                .backgroundColor(Tokens.SURFACE_ALT)
                .border({ width: 1, color: Tokens.BORDER })
                .borderRadius(Tokens.RADIUS_LG - 2)
                .padding({ left: 12, right: 12 })
                .onChange((v: string) => { this.password = v; })
              PrimaryButton({ label: '确认重置', loading: this.submitting, onTap: () => { this.reset(); } })
                .margin({ top: 6 })
              Text('返回登录').fontSize(13).fontColor(Tokens.PRIMARY)
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
