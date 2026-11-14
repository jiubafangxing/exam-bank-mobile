import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { repo } from '../common/repo/CandidateRepository';
import { SessionStore } from '../common/storage/SessionStore';
import { LoginResponse } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { PrimaryButton, CardContainer, AuthHero } from '../components/Common';

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
      Column() {
        AuthHero({ title: '在线考试', subtitle: '登录后参加考试、练习与学习', glyph: '考' })

        Column() {
          CardContainer() {
            Column({ space: 12 }) {
              Text('账号登录').fontSize(17).fontWeight(FontWeight.Bold).fontColor(Tokens.TEXT_PRIMARY)
              TextInput({ placeholder: '请输入账号', text: this.username })
                .width('100%').height(48)
                .backgroundColor(Tokens.SURFACE_ALT)
                .border({ width: 1, color: Tokens.BORDER })
                .borderRadius(Tokens.RADIUS_LG - 2)
                .padding({ left: 12, right: 12 })
                .onChange((value: string) => { this.username = value; })
              TextInput({ placeholder: '请输入密码', text: this.password })
                .type(InputType.Password)
                .width('100%').height(48)
                .backgroundColor(Tokens.SURFACE_ALT)
                .border({ width: 1, color: Tokens.BORDER })
                .borderRadius(Tokens.RADIUS_LG - 2)
                .padding({ left: 12, right: 12 })
                .onChange((value: string) => { this.password = value; })
              PrimaryButton({ label: '登录', loading: this.submitting, onTap: () => { this.login(); } })
                .margin({ top: 6 })
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
              }.width('100%').margin({ top: 4 })
            }.width('100%')
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 14, bottom: 24 })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Tokens.BACKGROUND)
  }
}
