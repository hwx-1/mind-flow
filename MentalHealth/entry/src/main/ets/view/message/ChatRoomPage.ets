import { promptAction, router } from '@kit.ArkUI';
import { MessageApi } from '../../api/Api';
import { ChatMsgVo, WsChatPayload } from '../../model/Models';
import { Auth } from '../../store/Auth';
import { Ws, WsEventHandler } from '../../api/WsClient';
import { TimeUtil } from '../../utils/TimeUtil';
import { EmojiBar } from '../common/EmojiBar';
import { Const } from '../../constants/Const';

@Entry
@Component
struct ChatRoomPage {
  @StorageProp('themePrimary') themePrimary: string = '#D98E73';
  @State private messages: ChatMsgVo[] = [];
  @State private input: string = '';
  @State private title: string = '聊天';
  @State private otherAvatar: string = '';
  @State private sending: boolean = false;
  @State private syncing: boolean = false;
  private otherId: number = 0;
  private myId: number = 0;
  private scroller: Scroller = new Scroller();
  private wsHandler: WsEventHandler = (event: string, data: object): void => {
    if (event === 'error') {
      const err = data as Record<string, string>;
      promptAction.showToast({ message: err['message'] || '发送失败' });
      return;
    }
    if (event !== 'chat' && event !== 'ack') {
      return;
    }
    const m = data as ChatMsgVo;
    if (m.fromUser === this.otherId || m.toUser === this.otherId) {
      this.loadMessages();
    }
  };

  async aboutToAppear(): Promise<void> {
    const p = router.getParams() as Record<string, number | string | object>;
    this.otherId = p['userId'] as number;
    this.title = (p['nickname'] as string) || '聊天';
    this.otherAvatar = (p['avatar'] as string) || '';
    this.myId = Auth.getUser()?.id || 0;
    Ws.connect();
    Ws.on(this.wsHandler);
    await this.loadMessages();
  }

  aboutToDisappear(): void {
    Ws.off(this.wsHandler);
    // 通知消息页刷新会话列表与未读数（消息页是 Tab 子组件，onPageShow 不触发）
    const tick = AppStorage.get<number>(Const.MSG_REFRESH_KEY) ?? 0;
    AppStorage.setOrCreate<number>(Const.MSG_REFRESH_KEY, tick + 1);
  }

  private scrollEnd(): void {
    setTimeout((): void => {
      this.scroller.scrollEdge(Edge.Bottom);
    }, 50);
  }

  private shouldShowTime(index: number): boolean {
    if (index === 0) {
      return true;
    }
    const prev = new Date(this.messages[index - 1].createdAt).getTime();
    const current = new Date(this.messages[index].createdAt).getTime();
    return current - prev > 5 * 60 * 1000;
  }

  async loadMessages(): Promise<void> {
    if (this.syncing || this.otherId <= 0) {
      return;
    }
    this.syncing = true;
    try {
      this.messages = await MessageApi.chatWith(this.otherId);
      this.scrollEnd();
    } catch (e) {
    } finally {
      this.syncing = false;
    }
  }

  async send(): Promise<void> {
    const text = this.input.trim();
    if (!text || this.sending) {
      return;
    }
    this.input = '';
    this.sending = true;
    try {
      const payload: WsChatPayload = {
        toUserId: this.otherId,
        content: text,
        type: 'text'
      };
      if (Ws.isConnected()) {
        Ws.send('chat', payload as object);
      } else {
        await MessageApi.send(this.otherId, text, 'text');
        await this.loadMessages();
      }
    } catch (e) {
      this.input = text;
      promptAction.showToast({ message: '发送失败' });
    } finally {
      this.sending = false;
    }
  }

  @Builder
  Avatar(name: string, isMine: boolean) {
    if (isMine && Auth.getUser()?.avatar) {
      Image(Auth.getUser()?.avatar)
        .width(36)
        .height(36)
        .borderRadius(6)
        .objectFit(ImageFit.Cover)
    } else if (!isMine && this.otherAvatar) {
      Image(this.otherAvatar)
        .width(36)
        .height(36)
        .borderRadius(6)
        .objectFit(ImageFit.Cover)
    } else {
          Text((name || '用').substring(0, 1))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .borderRadius(6)
        .backgroundColor(isMine ? this.themePrimary : $r('app.color.clay'))
    }
  }

  @Builder
  Bubble(m: ChatMsgVo, index: number) {
    Column({ space: 8 }) {
      if (this.shouldShowTime(index)) {
        Text(TimeUtil.fromNow(m.createdAt))
          .fontSize(11)
          .fontColor(Color.White)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(8)
          .backgroundColor('#33000000')
      }

      if (m.fromUser === this.myId) {
        Row({ space: 8 }) {
          Blank()
          Text(m.content)
            .fontSize(15)
            .fontColor($r('app.color.text_main'))
            .lineHeight(22)
            .padding({ left: 12, right: 12, top: 9, bottom: 9 })
            .backgroundColor(this.themePrimary)
            .borderRadius({ topLeft: 8, topRight: 2, bottomLeft: 8, bottomRight: 8 })
            .constraintSize({ maxWidth: '70%' })
          this.Avatar(Auth.getUser()?.nickname || Auth.getUser()?.username || '我', true)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      } else {
        Row({ space: 8 }) {
          this.Avatar(this.title, false)
          Text(m.content)
            .fontSize(15)
            .fontColor($r('app.color.text_main'))
            .lineHeight(22)
            .padding({ left: 12, right: 12, top: 9, bottom: 9 })
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius({ topLeft: 2, topRight: 8, bottomLeft: 8, bottomRight: 8 })
            .constraintSize({ maxWidth: '70%' })
          Blank()
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24)
          .height(24)
          .fillColor($r('app.color.text_main'))
          .onClick(() => router.back())
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_main'))
          .margin({ left: 12 })
          .layoutWeight(1)
        if (this.syncing) {
          Text('同步中')
            .fontSize(12)
            .fontColor($r('app.color.text_sub'))
            .margin({ right: 10 })
        }
          Text('刷新')
          .fontSize(13)
          .fontColor(this.themePrimary)
          .padding({ left: 8, right: 4, top: 6, bottom: 6 })
          .onClick(() => {
            this.loadMessages();
          })
      }
      .width('100%')
      .height(54)
      .padding({ left: 14, right: 14 })
      .backgroundColor($r('app.color.card_bg'))
      .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })

      List({ space: 12, scroller: this.scroller }) {
        ForEach(this.messages, (m: ChatMsgVo, index: number) => {
          ListItem() {
            this.Bubble(m, index)
          }
        }, (m: ChatMsgVo) => m.id.toString())

        if (this.messages.length === 0 && !this.syncing) {
          ListItem() {
            Text('开始聊天吧')
              .fontSize(13)
              .fontColor($r('app.color.text_sub'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(48)
          }
        }
      }
      .layoutWeight(1)
      .padding({ left: 12, right: 12, top: 14, bottom: 10 })

      Column() {
        EmojiBar({ onPick: (value: string) => this.input += value })
        Row({ space: 8 }) {
          TextInput({ placeholder: '输入消息', text: this.input })
            .layoutWeight(1)
            .height(40)
            .fontSize(14)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(6)
            .padding({ left: 12, right: 12 })
            .onChange((value: string) => this.input = value)
            .onSubmit(() => this.send())
          Text(this.sending ? '...' : '发送')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.input.trim().length > 0 ? Color.White : $r('app.color.text_sub'))
            .height(40)
            .padding({ left: 16, right: 16 })
            .borderRadius(20)
            .backgroundColor(this.input.trim().length > 0 ? this.themePrimary : $r('app.color.divider'))
            .onClick(() => this.send())
        }
        .width('100%')
        .padding({ left: 10, right: 10, bottom: 10 })
      }
      .width('100%')
      .backgroundColor($r('app.color.bg_page'))
      .border({ width: { top: 0.5 }, color: $r('app.color.divider') })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
