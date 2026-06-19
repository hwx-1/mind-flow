import webSocket from '@ohos.net.webSocket';
import { Const } from '../constants/Const';
import { Auth } from '../store/Auth';

export type WsEventHandler = (event: string, data: object) => void;

class WsClient {
  private ws: webSocket.WebSocket | null = null;
  private handlers: Set<WsEventHandler> = new Set();
  private connected: boolean = false;
  private timer: number = -1;

  on(h: WsEventHandler): void { this.handlers.add(h); }
  off(h: WsEventHandler): void { this.handlers.delete(h); }

  connect(): void {
    const token = Auth.getToken();
    if (!token || this.connected) return;
    this.ws = webSocket.createWebSocket();

    this.ws.on('open', () => {
      this.connected = true;
      this.timer = setInterval(() => {
        if (this.ws) this.ws.send(JSON.stringify({ action: 'ping' }));
      }, 30000);
    });
    this.ws.on('message', (_err, data: string | ArrayBuffer) => {
      if (typeof data !== 'string') return;
      try {
        const obj = JSON.parse(data) as Record<string, object>;
        const event = obj['event'] as string;
        this.handlers.forEach(h => h(event, obj['data'] as object));
      } catch (e) {}
    });
    this.ws.on('close', () => { this.cleanup(); });
    this.ws.on('error', (_e) => { this.cleanup(); });

    this.ws.connect(`${Const.WS_URL}?token=${token}`, (err) => {
      if (err) console.error('ws connect', JSON.stringify(err));
    });
  }

  send(action: string, payload: object): void {
    if (!this.ws || !this.connected) return;
    const msg: Record<string, object> = { action: action as object };
    Object.assign(msg, payload);
    this.ws.send(JSON.stringify(msg));
  }

  close(): void {
    if (this.ws) { try { this.ws.close(); } catch (e) {} }
    this.cleanup();
  }

  private cleanup(): void {
    this.connected = false;
    if (this.timer >= 0) { clearInterval(this.timer); this.timer = -1; }
    this.ws = null;
  }
}

export const Ws = new WsClient();
