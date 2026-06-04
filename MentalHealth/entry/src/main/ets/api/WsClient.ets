import { webSocket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Const } from '../constants/Const';
import { Auth } from '../store/Auth';

export type WsEventHandler = (event: string, data: object) => void;
export type WsStatusHandler = (connected: boolean) => void;

interface WsEnvelope {
  event?: string;
  data?: object;
  action?: string;
}

/**
 * WebSocket 客户端：单例，负责实时消息（聊天 / 点赞 / 评论通知）。
 * 关键能力：断线后指数退避自动重连，保证长连接稳定；
 * 对外暴露连接状态变化，页面据此决定是否启用兜底轮询。
 */
class WsClient {
  private ws: webSocket.WebSocket | null = null;
  private handlers: Set<WsEventHandler> = new Set();
  private statusHandlers: Set<WsStatusHandler> = new Set();
  private connected: boolean = false;
  private heartbeatTimer: number = -1;
  private reconnectTimer: number = -1;
  private reconnectAttempts: number = 0;
  private manualClosed: boolean = false;
  private static readonly MAX_RECONNECT_DELAY: number = 30000;
  private static readonly BASE_RECONNECT_DELAY: number = 1000;

  on(h: WsEventHandler): void { this.handlers.add(h); }
  off(h: WsEventHandler): void { this.handlers.delete(h); }
  onStatus(h: WsStatusHandler): void { this.statusHandlers.add(h); }
  offStatus(h: WsStatusHandler): void { this.statusHandlers.delete(h); }
  isConnected(): boolean { return this.connected; }

  connect(): void {
    const token = Auth.getToken();
    if (token.length === 0 || this.connected || this.ws !== null) {
      return;
    }
    this.manualClosed = false;
    this.ws = webSocket.createWebSocket();

    this.ws.on('open', (): void => {
      this.connected = true;
      this.reconnectAttempts = 0;
      this.startHeartbeat();
      this.notifyStatus();
    });

    this.ws.on('message', (_err: BusinessError, data: string | ArrayBuffer): void => {
      if (typeof data !== 'string') {
        return;
      }
      try {
        const obj = JSON.parse(data) as WsEnvelope;
        if (obj.event) {
          const event = obj.event as string;
          const payload = obj.data ?? ({} as Record<string, Object>);
          this.handlers.forEach((h: WsEventHandler): void => h(event, payload));
        }
      } catch (e) {
        // 忽略非法负载
      }
    });

    this.ws.on('close', (): void => { this.handleDrop(); });
    this.ws.on('error', (_e: BusinessError): void => { this.handleDrop(); });

    this.ws.connect(`${Const.WS_URL}?token=${token}`, (err: BusinessError): void => {
      if (err) {
        console.error(`ws connect error: ${JSON.stringify(err)}`);
        this.handleDrop();
      }
    });
  }

  send(action: string, payload: object): void {
    if (this.ws === null || !this.connected) {
      return;
    }
    const msg: Record<string, Object> = { 'action': action };
    const payloadObj = payload as Record<string, Object>;
    const keys = Object.keys(payloadObj);
    for (let i = 0; i < keys.length; i++) {
      msg[keys[i]] = payloadObj[keys[i]];
    }
    this.ws.send(JSON.stringify(msg));
  }

  /** 主动关闭（如退出登录 / 应用退出），关闭后不再自动重连。 */
  close(): void {
    this.manualClosed = true;
    this.clearReconnect();
    this.teardownSocket();
    this.setDisconnected();
  }

  private startHeartbeat(): void {
    this.stopHeartbeat();
    this.heartbeatTimer = setInterval((): void => {
      if (this.ws !== null && this.connected) {
        const ping: Record<string, string> = { 'action': 'ping' };
        this.ws.send(JSON.stringify(ping));
      }
    }, 30000);
  }

  private stopHeartbeat(): void {
    if (this.heartbeatTimer >= 0) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = -1;
    }
  }

  /** 连接断开（非主动关闭）后触发：清理并安排重连。 */
  private handleDrop(): void {
    const wasConnected = this.connected;
    this.teardownSocket();
    this.setDisconnected();
    if (wasConnected) {
      this.notifyStatus();
    }
    if (!this.manualClosed) {
      this.scheduleReconnect();
    }
  }

  private scheduleReconnect(): void {
    if (this.reconnectTimer >= 0) {
      return;
    }
    if (Auth.getToken().length === 0) {
      return;
    }
    const delay = Math.min(
      WsClient.BASE_RECONNECT_DELAY * Math.pow(2, this.reconnectAttempts),
      WsClient.MAX_RECONNECT_DELAY
    );
    this.reconnectAttempts += 1;
    this.reconnectTimer = setTimeout((): void => {
      this.reconnectTimer = -1;
      this.connect();
    }, delay);
  }

  private clearReconnect(): void {
    if (this.reconnectTimer >= 0) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = -1;
    }
    this.reconnectAttempts = 0;
  }

  private teardownSocket(): void {
    this.stopHeartbeat();
    if (this.ws !== null) {
      try {
        this.ws.close();
      } catch (e) {
        // 忽略关闭异常
      }
      this.ws = null;
    }
  }

  private setDisconnected(): void {
    this.connected = false;
  }

  private notifyStatus(): void {
    const state = this.connected;
    this.statusHandlers.forEach((h: WsStatusHandler): void => h(state));
  }
}

export const Ws = new WsClient();
