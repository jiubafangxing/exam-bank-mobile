import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { BusinessError } from '@ohos.base';
import { SessionStore } from '../common/storage/SessionStore';

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.init(windowStage);
  }

  private async init(windowStage: window.WindowStage): Promise<void> {
    await SessionStore.init(this.context);
    const page = SessionStore.isLoggedIn() ? 'pages/Index' : 'pages/LoginPage';
    windowStage.loadContent(page, (err: BusinessError) => {
      if (err && err.code) {
        console.error('loadContent failed: ' + err.code);
      }
    });
  }
}
