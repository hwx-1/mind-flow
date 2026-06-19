import http from '@ohos.net.http';
import { Const } from '../constants/Const';
import { Auth } from '../store/Auth';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';

export interface ApiResult<T> {
  code: number;
  msg: string;
  data: T;
}

class HttpClient {
  private build(method: http.RequestMethod, url: string, body?: object, extraHeader?: Record<string, string>): Promise<http.HttpResponse> {
    const req = http.createHttp();
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    const token = Auth.getToken();
    if (token) headers['Authorization'] = `Bearer ${token}`;
    if (extraHeader) Object.assign(headers, extraHeader);

    return req.request(
      url.startsWith('http') ? url : `${Const.BASE_URL}${url}`,
      {
        method,
        header: headers,
        connectTimeout: 15000,
        readTimeout: 60000,
        extraData: body ? JSON.stringify(body) : undefined
      }
    );
  }

  private async exec<T>(method: http.RequestMethod, url: string, body?: object): Promise<T> {
    try {
      const res = await this.build(method, url, body);
      if (res.responseCode === 401) {
        await Auth.clear();
        promptAction.showToast({ message: '登录已过期' });
        router.replaceUrl({ url: 'view/auth/LoginPage' });
        throw new Error('unauthorized');
      }
      const text = res.result as string;
      const json = JSON.parse(text) as ApiResult<T>;
      if (json.code !== 0) {
        promptAction.showToast({ message: json.msg || '请求失败' });
        throw new Error(json.msg);
      }
      return json.data;
    } catch (e) {
      console.error('http', url, JSON.stringify(e));
      throw e as Error;
    }
  }

  get<T>(url: string): Promise<T>           { return this.exec<T>(http.RequestMethod.GET, url); }
  post<T>(url: string, body?: object): Promise<T>   { return this.exec<T>(http.RequestMethod.POST, url, body); }
  put<T>(url: string, body?: object): Promise<T>    { return this.exec<T>(http.RequestMethod.PUT, url, body); }
  del<T>(url: string): Promise<T>           { return this.exec<T>(http.RequestMethod.DELETE, url); }

  /** SSE 流式：用 onDataReceive 拼帧 */
  sse(url: string, body: object, onDelta: (s: string) => void, onDone: () => void, onError: (e: Error) => void): http.HttpRequest {
    const req = http.createHttp();
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream'
    };
    const token = Auth.getToken();
    if (token) headers['Authorization'] = `Bearer ${token}`;

    let buffer = '';
    req.on('dataReceive', (chunk: ArrayBuffer) => {
      const text = new TextDecoder('utf-8').decode(new Uint8Array(chunk));
      buffer += text;
      // 按 \n\n 切帧
      let idx: number;
      while ((idx = buffer.indexOf('\n\n')) !== -1) {
        const frame = buffer.substring(0, idx);
        buffer = buffer.substring(idx + 2);
        for (const line of frame.split('\n')) {
          if (!line.startsWith('data:')) continue;
          const payload = line.substring(5).trim();
          if (!payload) continue;
          if (payload === '[DONE]') { onDone(); return; }
          try {
            const obj = JSON.parse(payload) as Record<string, string>;
            const delta = obj.delta;
            if (delta) onDelta(delta);
          } catch (_) {}
        }
      }
    });
    req.on('dataEnd', () => onDone());

    req.requestInStream(`${Const.BASE_URL}${url}`, {
      method: http.RequestMethod.POST,
      header: headers,
      connectTimeout: 15000,
      readTimeout: 120000,
      extraData: JSON.stringify(body)
    }).catch((e: Error) => onError(e));
    return req;
  }
}

export const Http = new HttpClient();
