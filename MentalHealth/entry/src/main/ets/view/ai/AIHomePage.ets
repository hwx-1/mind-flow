import { router } from '@kit.ArkUI';
import { AiApi } from '../../api/Api';
import { Const } from '../../constants/Const';
import { AiSessionVo } from '../../model/Models';
import { TimeUtil } from '../../utils/TimeUtil';

interface BizCard {
  business: string;
  title: string;
  subtitle: string;
  emoji: string;
  tint: string;
}

@Component
export struct AIHomePage {
  @StorageProp('themePrimary') themePrimary: string = '#D98E73';
  @State private recent: AiSessionVo[] = [];
  // 对话页返回后自增此值，触发刷新最近会话（Tab 子组件 onPageShow 不触发）
  @StorageProp('aiRefreshTick') @Watch('onAiSignal') private aiTick: number = 0;

  private readonly cards: BizCard[] = [
    { business: Const.BIZ_MENTAL, title: '心理咨询', subtitle: '先倾听，再一起梳理', emoji: '心', tint: '#FFF3ECE1' },
    { business: Const.BIZ_STUDY, title: '学习辅导', subtitle: '拆目标、理步骤、提效率', emoji: '学', tint: '#FFEAF0E4' },
    { business: Const.BIZ_GENERAL, title: '综合聊天', subtitle: '灵感、计划、表达都可以', emoji: '聊', tint: '#FFFFF4D6' }
  ];

  aboutToAppear(): void {
    this.load();
  }

  onAiSignal(): void {
    this.load();
  }

  async load(): Promise<void> {
    try {
      const sessions = await AiApi.sessions();
      this.recent = sessions.slice(0, 5);
    } catch (e) {}
  }

  async startNew(business: string): Promise<void> {
    try {
      const session = await AiApi.createSession(business);
      router.pushUrl({
        url: 'view/ai/ChatPage',
        params: { sessionId: session.id, business: session.business, title: session.title }
      });
    } catch (e) {}
  }

  private bizMark(business: string): string {
    if (business === Const.BIZ_MENTAL) {
      return '心';
    }
    if (business === Const.BIZ_STUDY) {
      return '学';
    }
    return '聊';
  }

  @Builder
  Header() {
    Row() {
      Text('AI 咨询')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_main'))
      Blank()
      Image($r('sys.media.ohos_ic_public_clock'))
        .width(23)
        .height(23)
        .fillColor($r('app.color.text_main'))
        .onClick(() => router.pushUrl({ url: 'view/ai/HistoryPage' }))
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.card_bg'))
    .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })
  }

  @Builder
  BizItem(card: BizCard) {
    Row({ space: 12 }) {
      Text(card.emoji)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themePrimary)
        .width(42)
        .height(42)
        .textAlign(TextAlign.Center)
        .borderRadius(21)
        .backgroundColor(card.tint)
      Column({ space: 4 }) {
        Text(card.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_main'))
        Text(card.subtitle)
          .fontSize(12)
          .fontColor($r('app.color.text_sub'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Image($r('sys.media.ohos_ic_public_arrow_right'))
        .width(16)
        .height(16)
        .fillColor($r('app.color.text_sub'))
    }
    .width('100%')
    .height(72)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.card_bg'))
    .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })
    .onClick(() => this.startNew(card.business))
  }

  @Builder
  RecentItem(session: AiSessionVo) {
    Row({ space: 12 }) {
      Text(this.bizMark(session.business))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .width(34)
        .height(34)
        .textAlign(TextAlign.Center)
        .borderRadius(17)
        .backgroundColor($r('app.color.accent'))
      Column({ space: 4 }) {
        Text(session.title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_main'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(session.lastMsg || '暂无消息')
          .fontSize(12)
          .fontColor($r('app.color.text_sub'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text(TimeUtil.fromNow(session.updatedAt))
        .fontSize(11)
        .fontColor($r('app.color.text_sub'))
    }
    .width('100%')
    .height(62)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.card_bg'))
    .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })
    .onClick(() => router.pushUrl({
      url: 'view/ai/ChatPage',
      params: { sessionId: session.id, business: session.business, title: session.title }
    }))
  }

  build() {
    Column() {
      this.Header()

      Scroll() {
        Column({ space: 8 }) {
          Column() {
            Text('选择业务方向')
              .fontSize(13)
              .fontColor($r('app.color.text_sub'))
              .width('100%')
              .padding({ left: 16, right: 16, top: 14, bottom: 8 })
            ForEach(this.cards, (card: BizCard) => {
              this.BizItem(card)
            }, (card: BizCard) => card.business)
          }
          .width('100%')
          .backgroundColor($r('app.color.card_bg'))

          if (this.recent.length > 0) {
            Column() {
              Text('最近会话')
                .fontSize(13)
                .fontColor($r('app.color.text_sub'))
                .width('100%')
                .padding({ left: 16, right: 16, top: 14, bottom: 8 })
              ForEach(this.recent, (session: AiSessionVo) => {
                this.RecentItem(session)
              }, (session: AiSessionVo) => session.id.toString())
            }
            .width('100%')
            .backgroundColor($r('app.color.card_bg'))
          }
        }
        .width('100%')
        .padding({ bottom: 16 })
      }
      .layoutWeight(1)
      .backgroundColor($r('app.color.bg_page'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
