import router from '@ohos.router';
import { MessageApi } from '../../api/Api';
import { ChatMsgVo } from '../../model/Models';
import { Auth } from '../../store/Auth';
import { Ws, WsEventHandler } from '../../api/WsClient';
import { TimeUtil } from '../../utils/TimeUtil';

@Entry
@Component
struct ChatRoomPage {
  @State messages: ChatMsgVo[] = [];
  @State input: string = '';
  @State title: string = '聊天';
  private otherId: number = 0;
  private myId: number = 0;
  private scroller: Scroller = new Scroller();
  private wsHandler: WsEventHandler = (event, data) => {
    if (event !== 'chat' && event !== 'ack') return;
    const m = data as ChatMsgVo;
    // 只关心当前会话
    if (m.fromUser === this.otherId || m.toUser === this.otherId) {
      this.messages.push(m);
      this.messages = this.messages.slice();
      this.scrollEnd();
    }
  };

  async aboutToAppear() {
    const p = router.getParams() as Record<string, object>;
    this.otherId = p['userId'] as number;
    this.title = (p['nickname'] as string) || '聊天';
    this.myId = Auth.getUser()?.id || 0;
    Ws.on(this.wsHandler);
    try {
      this.messages = await MessageApi.chatWith(this.otherId);
      this.scrollEnd();
    } catch (e) {}
  }

  aboutToDisappear(): void { Ws.off(this.wsHandler); }

  scrollEnd() { setTimeout(() => this.scroller.scrollEdge(Edge.Bottom), 50); }

  send() {
    const text = this.input.trim();
    if (!text) return;
    this.input = '';
    Ws.send('chat', { toUserId: this.otherId, content: text, type: 'text' });
    // 立即在 UI 显示自己的消息（ack 会再返一条；用本地时间戳做去重也可）
    const local: ChatMsgVo = {
      id: -Date.now(),
      fromUser: this.myId,
      toUser: this.otherId,
      content: text,
      type: 'text',
      createdAt: new Date().toISOString()
    };
    this.messages.push(local);
    this.messages = this.messages.slice();
    this.scrollEnd();
  }

  @Builder
  Bubble(m: ChatMsgVo) {
    if (m.fromUser === this.myId) {
      Row() {
        Blank()
        Text(m.content).fontSize(15).fontColor(Color.White).padding(10)
          .backgroundColor($r('app.color.primary'))
          .borderRadius({ topLeft: 12, topRight: 4, bottomLeft: 12, bottomRight: 12 })
          .constraintSize({ maxWidth: '74%' })
      }.width('100%').padding({ left: 50 })
    } else {
      Row() {
        Text(m.content).fontSize(15).fontColor($r('app.color.text_main')).padding(10)
          .backgroundColor(Color.White)
          .borderRadius({ topLeft: 4, topRight: 12, bottomLeft: 12, bottomRight: 12 })
          .constraintSize({ maxWidth: '74%' })
        Blank()
      }.width('100%').padding({ right: 50 })
    }
  }

  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left')).width(24).height(24)
          .onClick(() => router.back())
        Text(this.title).fontSize(17).fontWeight(FontWeight.Medium).margin({ left: 12 })
      }.width('100%').padding(14).backgroundColor(Color.White)

      List({ space: 10, scroller: this.scroller }) {
        ForEach(this.messages, (m: ChatMsgVo) => {
          ListItem() { this.Bubble(m) }
        }, (m: ChatMsgVo) => m.id.toString())
      }.layoutWeight(1).padding(14)

      Row({ space: 8 }) {
        TextInput({ placeholder: '输入消息…', text: this.input })
          .layoutWeight(1).height(40)
          .backgroundColor($r('app.color.bg_page')).borderRadius(20)
          .padding({ left: 14, right: 14 })
          .onChange(v => this.input = v)
          .onSubmit(() => this.send())
        Button('发送').height(40)
          .backgroundColor($r('app.color.primary'))
          .enabled(this.input.length > 0)
          .onClick(() => this.send())
      }.width('100%').padding(10).backgroundColor(Color.White)
        .border({ width: { top: 0.5 }, color: $r('app.color.divider') })
    }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
