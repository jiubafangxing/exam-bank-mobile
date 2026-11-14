import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import util from '@ohos.util';

/**
 * 会话存储。令牌与用户信息存 preferences；绝不持久化登录密码。
 * 启动时由 EntryAbility 调用 init() 完成加载。
 */
export class SessionStore {
  private static prefs: preferences.Preferences | null = null;
  static token: string = '';
  static userJson: string = '';

  static async init(context: common.Context): Promise<void> {
    if (SessionStore.prefs) return;
    SessionStore.prefs = await preferences.getPreferences(context, 'exam_mobile');
    SessionStore.token = String(await SessionStore.prefs.get('token', ''));
    SessionStore.userJson = String(await SessionStore.prefs.get('user', ''));
  }

  static isLoggedIn(): boolean {
    return SessionStore.token.length > 0;
  }

  static async save(token: string, userJson: string): Promise<void> {
    SessionStore.token = token;
    SessionStore.userJson = userJson;
    if (SessionStore.prefs) {
      await SessionStore.prefs.put('token', token);
      await SessionStore.prefs.put('user', userJson);
      await SessionStore.prefs.flush();
    }
  }

  static async clear(): Promise<void> {
    SessionStore.token = '';
    SessionStore.userJson = '';
    if (SessionStore.prefs) {
      await SessionStore.prefs.delete('token');
      await SessionStore.prefs.delete('user');
      await SessionStore.prefs.flush();
    }
  }

  static async deviceId(context: common.Context): Promise<string> {
    const prefs = SessionStore.prefs ? SessionStore.prefs : await preferences.getPreferences(context, 'exam_mobile');
    let id = String(await prefs.get('device_id', ''));
    if (!id) {
      id = util.generateRandomUUID(true).replace(/-/g, '');
      await prefs.put('device_id', id);
      await prefs.flush();
    }
    return id;
  }
}
