import promptAction from '@ohos.promptAction';
import common from '@ohos.app.ability.common';
import { repo } from '../common/repo/CandidateRepository';
import { SessionStore } from '../common/storage/SessionStore';
import { DeviceAuthView } from '../common/model/Models';
import { Tokens } from '../common/theme/Tokens';
import { CardContainer, LoadingView, ErrorBanner, KeyValueRow } from '../components/Common';

@Entry
@Component
struct DevicePage {
  @State deviceId: string = '';
  @State status: DeviceAuthView = {};
  @State loading: boolean = true;
  @State error: string = '';

  aboutToAppear(): void {
    this.init();
  }

  async init(): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;
    this.deviceId = await SessionStore.deviceId(context);
    await this.load();
  }

  async load(): Promise<void> {
    try {
      this.status = await repo.deviceAuth();
      this.error = '';
    } catch (e) {
      this.error = (e as Error).message;
    } finally {
      this.loading = false;
    }
  }

  async bind(): Promise<void> {
    try {
      await repo.bindDevice(this.deviceId, 'HarmonyOS 设备', 'HARMONY');
      promptAction.showToast({ message: '已绑定' });
      this.load();
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message });
    }
  }

  async unbind(): Promise<void> {
    try {
      await repo.unbindDevice(this.deviceId);
      promptAction.showToast({ message: '已解绑' });
      this.load();
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
              KeyValueRow({ label: '授权状态', value: this.status.authorized === true ? '已授权' : '未授权' })
              if (this.status.deviceName) {
                KeyValueRow({ label: '设备', value: this.status.deviceName })
              }
              if (this.status.message) {
                Text(this.status.message).fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
              }
            }.width('100%')
          }
          CardContainer() {
            Column({ space: 8 }) {
              Text('本机设备 ID').fontSize(12).fontColor(Tokens.TEXT_SECONDARY)
              Text(this.deviceId).fontSize(12).fontColor(Tokens.TEXT_PRIMARY)
              Row({ space: 12 }) {
                Button('绑定本机').height(44).backgroundColor(Tokens.SURFACE).fontColor(Tokens.PRIMARY).onClick(() => { this.bind(); })
                Button('解绑').height(44).backgroundColor(Tokens.SURFACE).fontColor(Tokens.PRIMARY).onClick(() => { this.unbind(); })
              }
            }.alignItems(HorizontalAlign.Start).width('100%')
          }
        }
      }.padding(16)
    }
    .width('100%').height('100%').backgroundColor(Tokens.BACKGROUND)
  }
}
