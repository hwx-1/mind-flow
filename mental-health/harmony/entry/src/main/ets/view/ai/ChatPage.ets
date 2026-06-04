import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AiApi } from '../../api/Api';
import { Http } from '../../api/HttpClient';
import { AiMessageVo } from '../../model/Models';

interface ChatMsg { role: string; content: string; }

@Entry
@Component
struct ChatPage {
  @State messages: ChatMsg[] = [];
  @State input: string = '';
  @State streaming: boolean = false;
  @State title: string = 'AI 助手';
  private sessionId: number = 0;
  private business: string = 'general';
  private listScroller: Scroller = new Scroller();
  private currentReq: object | null = null;

  async aboutToAppear() {
    const p = router.getParams() as Record<string, object>;
    this.sessionId = p['sessionId'] as number;
    this.business = p['business'] as string || 'general';
    this.title = (p['title'] as string) || 'AI 助手';
    await this.loadHistory();
  }

  async loadHistory() {
    try {
      const list = await AiApi.messages(this.sessionId);
      this.messages = list.map((m: AiMessageVo) => {
        const msg: ChatMsg = { role: m.role, content: m.content };
        return msg;
      });
      if (this.messages.length === 0) {
        this.messages = [{ role: 'assistant', content: this.welcome() }];
      }
      this.scrollEnd();
    } catch (e) {}
  }

  welcome(): string {
    if (this.business === 'mental') return '你好呀～我在这里。今天发生了什么，想和我聊聊吗？';
    if (this.business === 'study')  return '嗨！今天想攻克什么？告诉我目标，我们一起拆解。';
    return '你好呀～有什么想聊的？';
  }

  scrollEnd() {
    setTimeout(() => this.listScroller.scrollEdge(Edge.Bottom), 60);
  }

  send() {
    if (this.streaming) return;
    const text = this.input.trim();
    if (!text) return;
    this.input = '';

    this.messages.push({ role: 'user', content: text });
    const assistantIdx = this.messages.length;
    this.messages.push({ role: 'assistant', content: '' });
    this.messages = this.messages.slice();
    this.streaming = true;
    this.scrollEnd();

    Http.sse('/ai/chat',
      { sessionId: this.sessionId, content: text },
      (delta) => {
        this.messages[assistantIdx].content += delta;
        this.messages = this.messages.slice();
        this.scrollEnd();
      },
      () => {
        this.streaming = false;
        if (!this.messages[assistantIdx].content) {
          this.messages[assistantIdx].content = '（无响应，请稍后再试）';
          this.messages = this.messages.slice();
        }
      },
      (e) => {
        this.streaming = false;
        this.messages[assistantIdx].content = `出错了：${e.message}`;
        this.messages = this.messages.slice();
        promptAction.showToast({ message: '请求失败' });
      }
    );
  }

  @Builder
  Bubble(m: ChatMsg) {
    if (m.role === 'user') {
      Row() {
        Blank()
        Text(m.content).fontSize(15).fontColor(Color.White).padding(12)
          .backgroundColor($r('app.color.primary')).borderRadius({ topLeft: 14, topRight: 4, bottomLeft: 14, bottomRight: 14 })
          .constraintSize({ maxWidth: '78%' })
      }.width('100%').padding({ left: 50 })
    } else {
      Row() {
        Text('AI').fontSize(11).fontColor(Color.White).backgroundColor($r('app.color.primary'))
          .width(30).height(30).borderRadius(15).textAlign(TextAlign.Center)
        Text(m.content || '思考中…')
          .fontSize(15).fontColor($r('app.color.text_main')).padding(12)
          .backgroundColor(Color.White)
          .borderRadius({ topLeft: 4, topRight: 14, bottomLeft: 14, bottomRight: 14 })
          .margin({ left: 8 })
          .constraintSize({ maxWidth: '78%' })
      }.width('100%').alignItems(VerticalAlign.Top).padding({ right: 50 })
    }
  }

  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left')).width(24).height(24)
          .onClick(() => router.back())
        Text(this.title).fontSize(17).fontWeight(FontWeight.Medium).layoutWeight(1).margin({ left: 12 })
      }.width('100%').padding(14).backgroundColor(Color.White)

      List({ space: 14, scroller: this.listScroller }) {
        ForEach(this.messages, (m: ChatMsg, i: number) => {
          ListItem() { this.Bubble(m) }
        }, (m: ChatMsg, i: number) => i.toString())
      }
      .layoutWeight(1).width('100%').padding(14)

      Row({ space: 8 }) {
        TextInput({ placeholder: this.streaming ? '回复中…' : '输入消息', text: this.input })
          .layoutWeight(1).height(40)
          .backgroundColor($r('app.color.bg_page')).borderRadius(20)
          .padding({ left: 14, right: 14 })
          .enabled(!this.streaming)
          .onChange(v => this.input = v)
          .onSubmit(() => this.send())
        Button(this.streaming ? '...' : '发送').height(40)
          .backgroundColor($r('app.color.primary'))
          .enabled(!this.streaming && this.input.length > 0)
          .onClick(() => this.send())
      }.width('100%').padding(10).backgroundColor(Color.White)
        .border({ width: { top: 0.5 }, color: $r('app.color.divider') })
    }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
