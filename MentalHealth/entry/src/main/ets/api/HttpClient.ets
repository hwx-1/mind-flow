import { promptAction, router } from '@kit.ArkUI';
import { util } from '@kit.ArkTS';
import { rcp } from '@kit.RemoteCommunicationKit';
import { http } from '@kit.NetworkKit';
import { Const } from '../constants/Const';
import { Auth } from '../store/Auth';

type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE';

export interface ApiResult<T> {
  code: number;
  msg: string;
  data: T;
}

interface SseDelta {
  delta?: string;
  content?: string;
  text?: string;
  message?: string;
}

interface ErrorLike {
  code?: number;
  message?: string;
  name?: string;
}

/**
 * 网络层基于 Remote Communication Kit（RCP，API 12+ 官方推荐）实现。
 * - 普通 JSON 请求走共享 rcp.Session（复用连接）。
 * - SSE 流式仍使用 NetworkKit 的 http.requestInStream（RCP 面向请求/响应，不适合 SSE）。
 */
class HttpClient {
  private static readonly CONNECT_TIMEOUT: number = 30000;
  private static readonly READ_TIMEOUT: number = 90000;
  private session: rcp.Session | null = null;
  private lastToastAt: number = 0;

  private getSession(): rcp.Session {
    if (this.session === null) {
      const config: rcp.SessionConfiguration = {
        requestConfiguration: {
          transfer: {
            timeout: {
              connectMs: HttpClient.CONNECT_TIMEOUT,
              transferMs: HttpClient.READ_TIMEOUT
            }
          }
        }
      };
      this.session = rcp.createSession(config);
    }
    return this.session;
  }

  private showToastThrottled(message: string): void {
    const now = Date.now();
    if (now - this.lastToastAt < 5000) {
      return;
    }
    this.lastToastAt = now;
    promptAction.showToast({ message });
  }

  private buildJsonHeaders(): rcp.RequestHeaders {
    const headers: rcp.RequestHeaders = {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    };
    const token = Auth.getToken();
    if (token.length > 0) {
      headers['Authorization'] = `Bearer ${token}`;
    }
    return headers;
  }

  private retryCount(method: HttpMethod): number {
    return method === 'GET' ? 2 : 0;
  }

  private retryDelay(attempt: number): number {
    return 400 * Math.pow(2, attempt);
  }

  private sleep(ms: number): Promise<void> {
    return new Promise<void>((resolve) => {
      setTimeout((): void => resolve(), ms);
    });
  }

  private async execOnce<T>(method: HttpMethod, fullUrl: string, body?: object): Promise<T> {
    const headers = this.buildJsonHeaders();
    const content: rcp.RequestContent | undefined = body !== undefined ? JSON.stringify(body) : undefined;
    const request = new rcp.Request(fullUrl, method, headers, content);

    const response = await this.getSession().fetch(request);
    const status = response.statusCode;
    const text = response.toString() ?? '';

    if (status === 401) {
      await Auth.clear();
      this.showToastThrottled('登录已过期');
      router.replaceUrl({ url: 'view/auth/LoginPage' });
      throw new Error('unauthorized');
    }
    if (status < 200 || status >= 300) {
      throw new Error(`http_${status}: ${text}`);
    }
    if (text.trim().length === 0) {
      throw new Error('empty response');
    }

    const json = JSON.parse(text) as ApiResult<T>;
    if (json.code !== 0) {
      this.showToastThrottled(json.msg || '请求失败');
      throw new Error('business_error');
    }
    return json.data;
  }

  private async exec<T>(method: HttpMethod, url: string, body?: object): Promise<T> {
    const fullUrl = url.startsWith('http') ? url : `${Const.BASE_URL}${url}`;
    const maxRetry = this.retryCount(method);
    let lastError: Error | null = null;

    for (let attempt = 0; attempt <= maxRetry; attempt++) {
      try {
        return await this.execOnce<T>(method, fullUrl, body);
      } catch (e) {
        const err = e as Error;
        lastError = err;
        const message = err.message || '';
        console.error(`http ${method} ${url} fail attempt=${attempt + 1}/${maxRetry + 1} ${HttpClient.describeError(e)}`);
        if (message === 'unauthorized' || message === 'business_error' || message.startsWith('http_')) {
          throw err;
        }
        if (attempt < maxRetry) {
          await this.sleep(this.retryDelay(attempt));
        }
      }
    }

    this.showToastThrottled('网络开小差了，请稍后重试');
    throw lastError || new Error('network_error');
  }

  get<T>(url: string): Promise<T> {
    return this.exec<T>('GET', url);
  }

  post<T>(url: string, body?: object): Promise<T> {
    return this.exec<T>('POST', url, body);
  }

  put<T>(url: string, body?: object): Promise<T> {
    return this.exec<T>('PUT', url, body);
  }

  del<T>(url: string): Promise<T> {
    return this.exec<T>('DELETE', url);
  }

  private emitSsePayload(payload: string, onDelta: (s: string) => void): boolean {
    if (payload === '[DONE]') {
      return true;
    }
    try {
      const obj = JSON.parse(payload) as SseDelta;
      const delta = obj.delta || obj.content || obj.text || obj.message;
      if (delta) {
        onDelta(delta);
      }
    } catch (_) {
      onDelta(payload);
    }
    return false;
  }

  /**
   * SSE 流式响应。RCP 面向「请求-响应」语义，不适合服务端推送流，
   * 因此流式场景按官方推荐使用 NetworkKit 的 http.requestInStream + dataReceive。
   */
  sse(
    url: string,
    body: object,
    onDelta: (s: string) => void,
    onDone: () => void,
    onError: (e: Error) => void
  ): () => void {
    const fullUrl = url.startsWith('http') ? url : `${Const.BASE_URL}${url}`;
    const headers = this.buildJsonHeaders();
    headers['Accept'] = 'text/event-stream';

    let buffer = '';
    let finished = false;
    const decoder = util.TextDecoder.create('utf-8');
    const request = http.createHttp();

    const processFrame = (frame: string): boolean => {
      const lines = frame.split('\n');
      let payload = '';
      for (let i = 0; i < lines.length; i++) {
        const line = lines[i].trim();
        if (line.startsWith('data:')) {
          payload += line.substring(5).trim();
        }
      }
      if (payload.length === 0) {
        return false;
      }
      return this.emitSsePayload(payload, onDelta);
    };

    const processBuffer = (): void => {
      buffer = buffer.replace(/\r\n/g, '\n');
      let index = buffer.indexOf('\n\n');
      while (index !== -1) {
        const frame = buffer.substring(0, index);
        buffer = buffer.substring(index + 2);
        if (processFrame(frame)) {
          if (!finished) {
            finished = true;
            onDone();
          }
          return;
        }
        index = buffer.indexOf('\n\n');
      }
    };

    request.on('dataReceive', (data: ArrayBuffer): void => {
      if (finished) {
        return;
      }
      buffer += decoder.decodeToString(new Uint8Array(data));
      processBuffer();
    });

    request.on('dataEnd', (): void => {
      if (!finished) {
        if (buffer.trim().length > 0) {
          processFrame(buffer.trim());
          buffer = '';
        }
        finished = true;
        onDone();
      }
      request.destroy();
    });

    request.requestInStream(fullUrl, {
      method: http.RequestMethod.POST,
      header: headers,
      extraData: JSON.stringify(body),
      connectTimeout: HttpClient.CONNECT_TIMEOUT,
      readTimeout: 120000,
      usingCache: false
    }).then((code: number): void => {
      if (code < 200 || code >= 300) {
        if (!finished) {
          finished = true;
          onError(new Error(`SSE HTTP ${code}`));
        }
        request.destroy();
      }
    }).catch((e: Error): void => {
      if (!finished) {
        finished = true;
        console.error(`sse error ${HttpClient.describeError(e)}`);
        onError(e);
      }
      request.destroy();
    });

    return (): void => {
      finished = true;
      request.destroy();
    };
  }

  private static describeError(error: Error): string {
    const parts: string[] = [];
    if (error.name) {
      parts.push(`name=${error.name}`);
    }
    const maybeError = error as ErrorLike;
    if (typeof maybeError.code === 'number') {
      parts.push(`code=${maybeError.code}`);
    }
    if (error.message) {
      parts.push(`message=${error.message}`);
    }
    if (parts.length > 0) {
      return parts.join(' ');
    }
    return JSON.stringify(error);
  }
}

export const Http = new HttpClient();
