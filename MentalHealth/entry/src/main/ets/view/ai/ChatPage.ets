import { promptAction, router } from '@kit.ArkUI';
import { AiApi } from '../../api/Api';
import { Http } from '../../api/HttpClient';
import { AiMessageVo, ChatReq } from '../../model/Models';
import { Const } from '../../constants/Const';

interface ChatMsg {
  role: string;
  content: string;
}

interface ChatRouteParams {
  sessionId?: number;
  business?: string;
  title?: string;
}

@Entry
@Component
struct ChatPage {
  @StorageProp('themePrimary') themePrimary: string = '#D98E73';
  @StorageProp('themePrimaryLight') themePrimaryLight: string = '#F3ECE1';
  @State private messages: ChatMsg[] = [];
  @State private input: string = '';
  @State private streaming: boolean = false;
  @State private title: string = 'AI 助手';

  private sessionId: number = 0;
  private business: string = 'general';
  private readonly listScroller: Scroller = new Scroller();
  private cancelStream: (() => void) | null = null;
  private streamingIndex: number = -1;
  private pendingDelta: string = '';
  private flushTimer: number | null = null;

  async aboutToAppear(): Promise<void> {
    const params = router.getParams() as ChatRouteParams;
    if (params) {
      this.sessionId = params.sessionId ?? 0;
      this.business = params.business ?? 'general';
      this.title = params.title ?? 'AI 助手';
    }
    await this.loadHistory();
  }

  aboutToDisappear(): void {
    this.stopStream();
    // 通知 AI 首页刷新最近会话列表
    const tick = AppStorage.get<number>(Const.AI_REFRESH_KEY) ?? 0;
    AppStorage.setOrCreate<number>(Const.AI_REFRESH_KEY, tick + 1);
  }

  async loadHistory(): Promise<void> {
    try {
      const list = await AiApi.messages(this.sessionId);
      this.messages = list.map((item: AiMessageVo): ChatMsg => {
        return { role: item.role, content: item.content };
      });
      if (this.messages.length === 0) {
        this.messages = [{ role: 'assistant', content: this.welcome() }];
      }
      this.scrollEnd(80);
    } catch (e) {
      const err = e as Error;
      console.error(`loadHistory fail ${err.message || 'unknown error'}`);
    }
  }

  private welcome(): string {
    if (this.business === 'mental') {
      return '你好，我在这里。你可以慢慢说，我会先认真听完。';
    }
    if (this.business === 'study') {
      return '说说今天的学习目标，我帮你拆成可以马上开始的小步骤。';
    }
    return '你好，有什么想聊的？';
  }

  private scrollEnd(delay: number = 40): void {
    setTimeout((): void => {
      this.listScroller.scrollEdge(Edge.Bottom);
    }, delay);
  }

  private flushDelta(): void {
    if (this.streamingIndex < 0 || this.pendingDelta.length === 0) {
      this.flushTimer = null;
      return;
    }
    this.messages[this.streamingIndex].content += this.pendingDelta;
    this.pendingDelta = '';
    this.messages = this.messages.slice();
    this.flushTimer = null;
    this.scrollEnd(20);
  }

  private scheduleFlush(): void {
    if (this.flushTimer !== null) {
      return;
    }
    this.flushTimer = setTimeout((): void => {
      this.flushDelta();
    }, 50);
  }

  private stopStream(): void {
    if (this.cancelStream) {
      this.cancelStream();
      this.cancelStream = null;
    }
    if (this.flushTimer !== null) {
      clearTimeout(this.flushTimer);
      this.flushTimer = null;
    }
    this.flushDelta();
    this.streaming = false;
    this.streamingIndex = -1;
  }

  send(): void {
    if (this.streaming) {
      return;
    }
    const text = this.input.trim();
    if (!text) {
      return;
    }

    this.input = '';
    this.messages = this.messages.concat([
      { role: 'user', content: text },
      { role: 'assistant', content: '' }
    ]);
    this.streamingIndex = this.messages.length - 1;
    this.streaming = true;
    this.scrollEnd();

    const reqBody: ChatReq = { sessionId: this.sessionId, content: text };
    this.cancelStream = Http.sse(
      '/ai/chat',
      reqBody,
      (delta: string): void => {
        this.pendingDelta += delta;
        this.scheduleFlush();
      },
      (): void => {
        this.flushDelta();
        if (this.streamingIndex >= 0 && !this.messages[this.streamingIndex].content) {
          this.messages[this.streamingIndex].content = '暂时没有收到回复，请稍后再试。';
          this.messages = this.messages.slice();
        }
        this.streaming = false;
        this.streamingIndex = -1;
        this.cancelStream = null;
        this.scrollEnd();
      },
      (e: Error): void => {
        this.flushDelta();
        if (this.streamingIndex >= 0) {
          this.messages[this.streamingIndex].content = `出错了：${e.message}`;
          this.messages = this.messages.slice();
        }
        this.streaming = false;
        this.streamingIndex = -1;
        this.cancelStream = null;
        promptAction.showToast({ message: 'AI 回复失败' });
      }
    );
  }

  @Builder
  NavBar() {
    Row() {
      Image($r('sys.media.ohos_ic_public_arrow_left'))
        .width(24)
        .height(24)
        .fillColor($r('app.color.text_main'))
        .onClick((): void => router.back())
      Column({ space: 2 }) {
        Text(this.title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_main'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.streaming ? '正在生成回复' : '在线')
          .fontSize(11)
          .fontColor(this.streaming ? this.themePrimary : $r('app.color.text_sub'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      if (this.streaming) {
        Text('停止')
          .fontSize(13)
          .fontColor(this.themePrimary)
          .height(30)
          .padding({ left: 12, right: 12 })
          .borderRadius(15)
          .backgroundColor(this.themePrimaryLight)
          .onClick(() => this.stopStream())
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.card_bg'))
    .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })
  }

  @Builder
  Bubble(message: ChatMsg, index: number) {
    if (message.role === 'user') {
      Row() {
        Blank()
        Text(message.content)
          .fontSize(15)
          .fontColor(Color.White)
          .lineHeight(22)
          .padding({ left: 13, right: 13, top: 10, bottom: 10 })
          .backgroundColor(this.themePrimary)
          .borderRadius({ topLeft: 16, topRight: 4, bottomLeft: 16, bottomRight: 16 })
          .constraintSize({ maxWidth: '78%' })
      }
      .width('100%')
      .padding({ left: 54 })
    } else {
      Row({ space: 8 }) {
        Text('AI')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.accent'))
          .width(30)
          .height(30)
          .borderRadius(15)
          .textAlign(TextAlign.Center)
        Text(message.content || (this.streaming && index === this.streamingIndex ? '思考中...' : ''))
          .fontSize(15)
          .fontColor($r('app.color.text_main'))
          .lineHeight(23)
          .padding({ left: 13, right: 13, top: 10, bottom: 10 })
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius({ topLeft: 4, topRight: 16, bottomLeft: 16, bottomRight: 16 })
          .constraintSize({ maxWidth: '78%' })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .padding({ right: 54 })
    }
  }

  @Builder
  Composer() {
    Row({ space: 8 }) {
      TextInput({ placeholder: this.streaming ? 'AI 正在回复...' : '输入消息', text: this.input })
        .layoutWeight(1)
        .height(40)
        .fontSize(15)
        .backgroundColor($r('app.color.bg_page'))
        .borderRadius(20)
        .padding({ left: 14, right: 14 })
        .enabled(!this.streaming)
        .onChange((value: string): void => {
          this.input = value;
        })
        .onSubmit((): void => this.send())
      Text(this.streaming ? '停止' : '发送')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .height(40)
        .padding({ left: 16, right: 16 })
        .borderRadius(20)
        .backgroundColor(this.streaming || this.input.trim().length > 0 ? this.themePrimary : '#66D98E73')
        .onClick((): void => {
          if (this.streaming) {
            this.stopStream();
          } else {
            this.send();
          }
        })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor($r('app.color.card_bg'))
    .border({ width: { top: 0.5 }, color: $r('app.color.divider') })
  }

  build() {
    Column() {
      this.NavBar()

      List({ space: 14, scroller: this.listScroller }) {
        ForEach(
          this.messages,
          (message: ChatMsg, index: number) => {
            ListItem() {
              this.Bubble(message, index)
            }
          },
          (_message: ChatMsg, index: number) => index.toString()
        )
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 12, right: 12, top: 14, bottom: 14 })
      .backgroundColor($r('app.color.bg_page'))
      .cachedCount(8)

      this.Composer()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
