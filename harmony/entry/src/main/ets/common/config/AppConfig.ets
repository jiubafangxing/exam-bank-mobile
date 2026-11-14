import { GeneratedConfig } from './GeneratedConfig';

/**
 * 运行配置。域名由 scripts/inject-config.sh 生成到 GeneratedConfig.ets（不入库）。
 */
export class AppConfig {
  static readonly API_BASE_URL: string = GeneratedConfig.API_BASE_URL.endsWith('/')
    ? GeneratedConfig.API_BASE_URL.slice(0, GeneratedConfig.API_BASE_URL.length - 1)
    : GeneratedConfig.API_BASE_URL;
  static readonly API_ALLOW_CLEARTEXT: boolean = GeneratedConfig.API_ALLOW_CLEARTEXT;
  static readonly CLIENT_TYPE: string = 'HARMONY';
  static readonly REGISTRATION_URL: string = GeneratedConfig.REGISTRATION_URL;

  static readonly CONNECT_TIMEOUT: number = 20000;
  static readonly READ_TIMEOUT: number = 30000;

  static readonly DEBOUNCE_SAVE_MS: number = 500;
  static readonly HEARTBEAT_MS: number = 30000;
  static readonly EVENT_THROTTLE_MS: number = 1000;
}
