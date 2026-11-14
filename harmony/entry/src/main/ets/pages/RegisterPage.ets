import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { repo } from '../common/repo/CandidateRepository';
import { SessionStore } from '../common/storage/SessionStore';
import { LoginResponse } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { PrimaryButton, CardContainer, AuthHero } from '../components/Common';

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
    if (this.phone.length > 0 && this.phone.length !== 11) {
      promptAction.showToast({ message: '请输入正确手机号' });
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
      Column() {
        AuthHero({ title: '创建账号', subtitle: '注册后即可参加考试与在线练习', glyph: '注' })

        Column() {
          CardContainer() {
            Column({ space: 12 }) {
              TextInput({ placeholder: '账号', text: this.username })
                .width('100%').height(48)
                .backgroundColor(Tokens.SURFACE_ALT)
                .border({ width: 1, color: Tokens.BORDER })
                .borderRadius(Tokens.RADIUS_LG - 2)
                .padding({ left: 12, right: 12 })
                .onChange((v: string) => { this.username = v; })
              TextInput({ placeholder: '密码', text: this.password })
                .type(InputType.Password)
                .width('100%').height(48)
                .backgroundColor(Tokens.SURFACE_ALT)
                .border({ width: 1, color: Tokens.BORDER })
                .borderRadius(Tokens.RADIUS_LG - 2)
                .padding({ left: 12, right: 12 })
                .onChange((v: string) => { this.password = v; })
              TextInput({ placeholder: '姓名', text: this.realName })
                .width('100%').height(48)
                .backgroundColor(Tokens.SURFACE_ALT)
                .border({ width: 1, color: Tokens.BORDER })
                .borderRadius(Tokens.RADIUS_LG - 2)
                .padding({ left: 12, right: 12 })
                .onChange((v: string) => { this.realName = v; })
              TextInput({ placeholder: '手机号', text: this.phone })
                .type(InputType.PhoneNumber)
                .width('100%').height(48)
                .backgroundColor(Tokens.SURFACE_ALT)
                .border({ width: 1, color: Tokens.BORDER })
                .borderRadius(Tokens.RADIUS_LG - 2)
                .padding({ left: 12, right: 12 })
                .onChange((v: string) => { this.phone = v; })
              PrimaryButton({ label: '注册', loading: this.submitting, onTap: () => { this.register(); } })
                .margin({ top: 6 })
              Text('已有账号？去登录').fontSize(13).fontColor(Tokens.PRIMARY)
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
