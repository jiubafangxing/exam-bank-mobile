import http from '@ohos.net.http';
import router from '@ohos.router';
import util from '@ohos.util';
import { AppConfig } from '../config/AppConfig';
import { SessionStore } from '../storage/SessionStore';
import { Envelope } from '../model/Models';

export class ApiError extends Error {
  code: number;
  status: number;

  constructor(code: number, message: string, status: number = 0) {
    super(message);
    this.code = code;
    this.status = status;
  }
}

/**
 * 统一网络客户端：baseUrl + Bearer + X-Client-Type + 信封解包 + 401 处理。
 */
export class ApiClient {

  get(path: string, query?: Map<string, string>): Promise<Object> {
    return this.execute(http.RequestMethod.GET, path, query);
  }

  post(path: string, body?: string, headers?: Map<string, string>): Promise<Object> {
    return this.execute(http.RequestMethod.POST, path, undefined, body, headers);
  }

  put(path: string, body?: string): Promise<Object> {
    return this.execute(http.RequestMethod.PUT, path, undefined, body);
  }

  delete(path: string, query?: Map<string, string>): Promise<Object> {
    return this.execute(http.RequestMethod.DELETE, path, query);
  }

  async getRaw(path: string, query?: Map<string, string>): Promise<Object> {
    return await this.get(path, query);
  }

  async postMultipart(path: string, data: ArrayBuffer, filename: string = 'face.jpg'): Promise<Object> {
    if (!AppConfig.API_BASE_URL) throw new ApiError(-3, '服务地址未配置');
    const boundary = '----ExamBoundary' + Date.now();
    const head = '--' + boundary + '\r\nContent-Disposition: form-data; name="file"; filename="' + filename + '"\r\nContent-Type: image/jpeg\r\n\r\n';
    const tail = '\r\n--' + boundary + '--\r\n';
    const encoder = new util.TextEncoder();
    const headBytes = encoder.encodeInto(head);
    const tailBytes = encoder.encodeInto(tail);
    const fileBytes = new Uint8Array(data);
    const out = new Uint8Array(headBytes.length + fileBytes.length + tailBytes.length);
    out.set(headBytes, 0);
    out.set(fileBytes, headBytes.length);
    out.set(tailBytes, headBytes.length + fileBytes.length);

    const header: Record<string, string> = {
      'Accept': 'application/json',
      'X-Client-Type': AppConfig.CLIENT_TYPE,
      'Content-Type': 'multipart/form-data; boundary=' + boundary
    };
    if (SessionStore.token.length > 0) {
      header['Authorization'] = 'Bearer ' + SessionStore.token;
    }
    const request = http.createHttp();
    try {
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: header,
        extraData: out.buffer,
        connectTimeout: AppConfig.CONNECT_TIMEOUT,
        readTimeout: AppConfig.READ_TIMEOUT,
        expectDataType: http.HttpDataType.STRING
      };
      const response = await request.request(AppConfig.API_BASE_URL + path, options);
      if (response.responseCode === 401) {
        await SessionStore.clear();
        throw new ApiError(401, '登录已过期，请重新登录', 401);
      }
      const raw: string = typeof response.result === 'string' ? response.result as string : JSON.stringify(response.result);
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new ApiError(response.responseCode, '上传失败(' + response.responseCode + ')', response.responseCode);
      }
      return this.unwrap(raw);
    } finally {
      request.destroy();
    }
  }

  private async execute(
    method: http.RequestMethod,
    path: string,
    query?: Map<string, string>,
    body?: string,
    headers?: Map<string, string>
  ): Promise<Object> {
    if (!AppConfig.API_BASE_URL) {
      throw new ApiError(-3, '服务地址未配置');
    }
    let url = AppConfig.API_BASE_URL + path;
    if (query && query.size > 0) {
      const parts: string[] = [];
      query.forEach((value: string, key: string) => {
        parts.push(encodeURIComponent(key) + '=' + encodeURIComponent(value));
      });
      url += (url.indexOf('?') >= 0 ? '&' : '?') + parts.join('&');
    }

    const header: Record<string, string> = {
      'Accept': 'application/json',
      'X-Client-Type': AppConfig.CLIENT_TYPE
    };
    if (SessionStore.token.length > 0) {
      header['Authorization'] = 'Bearer ' + SessionStore.token;
    }
    if (body) {
      header['Content-Type'] = 'application/json; charset=utf-8';
    }
    if (headers) {
      headers.forEach((value: string, key: string) => {
        header[key] = value;
      });
    }

    const request = http.createHttp();
    try {
      const options: http.HttpRequestOptions = {
        method: method,
        header: header,
        connectTimeout: AppConfig.CONNECT_TIMEOUT,
        readTimeout: AppConfig.READ_TIMEOUT,
        expectDataType: http.HttpDataType.STRING
      };
      if (body) {
        options.extraData = body;
      }
      const response = await request.request(url, options);

      if (response.responseCode === 401) {
        await SessionStore.clear();
        try {
          router.replaceUrl({ url: 'pages/LoginPage' });
        } catch (e) {
          // 无 UI 上下文时忽略导航，由调用方处理
        }
        throw new ApiError(401, '登录已过期，请重新登录', 401);
      }

      const raw: string = typeof response.result === 'string'
        ? response.result as string
        : JSON.stringify(response.result);

      if (response.responseCode < 200 || response.responseCode >= 300) {
        let message = '请求失败(' + response.responseCode + ')';
        try {
          const errObj = JSON.parse(raw) as Envelope;
          if (errObj.message) message = errObj.message;
        } catch (e) {
          // ignore
        }
        throw new ApiError(response.responseCode, message, response.responseCode);
      }
      return this.unwrap(raw);
    } finally {
      request.destroy();
    }
  }

  private unwrap(raw: string): Object {
    if (!raw || raw.length === 0) {
      return JSON.parse('{}') as Object;
    }
    const obj = JSON.parse(raw) as Envelope;
    if (obj.code !== undefined && obj.code !== null) {
      if (obj.code !== 0) {
        throw new ApiError(obj.code, obj.message ? obj.message : '请求失败');
      }
      return obj.data ? obj.data : JSON.parse('{}') as Object;
    }
    return obj as Object;
  }
}
