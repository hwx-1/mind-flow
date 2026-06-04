import type { ApiResult } from '@/types';
import { useAuth } from '@/store/auth';

// 生产: location.origin + /api  开发: vite proxy 把 /api 转到 xsnbb.xyz
const BASE = '/api';

export class ApiError extends Error {
  code: number;
  constructor(code: number, msg: string) {
    super(msg);
    this.code = code;
  }
}

async function request<T>(method: string, path: string, body?: unknown): Promise<T> {
  const token = useAuth.getState().token;
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const resp = await fetch(BASE + path, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });

  if (resp.status === 401) {
    useAuth.getState().clear();
    throw new ApiError(401, '登录已过期,请重新登录');
  }

  const json = (await resp.json()) as ApiResult<T>;
  if (json.code !== 0) {
    throw new ApiError(json.code, json.msg || '请求失败');
  }
  return json.data;
}

export const http = {
  get: <T>(path: string) => request<T>('GET', path),
  post: <T>(path: string, body?: unknown) => request<T>('POST', path, body),
  put: <T>(path: string, body?: unknown) => request<T>('PUT', path, body),
  del: <T>(path: string) => request<T>('DELETE', path),
};

// 上传文件
export async function uploadFile(path: string, file: File): Promise<{ url: string }> {
  const token = useAuth.getState().token;
  const form = new FormData();
  form.append('file', file);
  const headers: Record<string, string> = {};
  if (token) headers['Authorization'] = `Bearer ${token}`;
  const resp = await fetch(BASE + path, { method: 'POST', headers, body: form });
  const json = (await resp.json()) as ApiResult<{ url: string }>;
  if (json.code !== 0) throw new ApiError(json.code, json.msg);
  return json.data;
}

/**
 * SSE 流式请求 (用于 AI 对话)
 * 用 fetch + ReadableStream 自己解析,因为 EventSource 不支持自定义 header
 */
export async function sse(
  path: string,
  body: unknown,
  onDelta: (text: string) => void,
  onDone: () => void,
  onError: (e: Error) => void
): Promise<() => void> {
  const token = useAuth.getState().token;
  const ctrl = new AbortController();
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    Accept: 'text/event-stream',
  };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  fetch(BASE + path, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
    signal: ctrl.signal,
  })
    .then(async (resp) => {
      if (!resp.ok || !resp.body) {
        throw new Error(`HTTP ${resp.status}`);
      }
      const reader = resp.body.getReader();
      const decoder = new TextDecoder('utf-8');
      let buffer = '';
      let finished = false;

      while (!finished) {
        const { done, value } = await reader.read();
        if (done) break;
        buffer += decoder.decode(value, { stream: true });
        let idx;
        while ((idx = buffer.indexOf('\n\n')) !== -1) {
          const frame = buffer.slice(0, idx);
          buffer = buffer.slice(idx + 2);
          for (const line of frame.split('\n')) {
            if (!line.startsWith('data:')) continue;
            const payload = line.slice(5).trim();
            if (!payload) continue;
            if (payload === '[DONE]') {
              finished = true;
              onDone();
              return;
            }
            try {
              const obj = JSON.parse(payload) as { delta?: string };
              if (obj.delta) onDelta(obj.delta);
            } catch {
              /* 单帧解析失败不中断流 */
            }
          }
        }
      }
      if (!finished) onDone();
    })
    .catch((e) => {
      if ((e as Error).name === 'AbortError') return;
      onError(e as Error);
    });

  return () => ctrl.abort();
}
