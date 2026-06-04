import router from '@ohos.router';
import { AiApi } from '../../api/Api';
import { AiSessionVo } from '../../model/Models';
import { Const } from '../../constants/Const';
import { TimeUtil } from '../../utils/TimeUtil';

interface BizCard {
  business: string;
  title: string;
  subtitle: string;
  emoji: string;
  bg: string;
}

@Component
export struct AIHomePage {
  @State recent: AiSessionVo[] = [];
  private cards: BizCard[] = [
    { business: Const.BIZ_MENTAL,  title: '心理咨询', subtitle: '温柔倾听，专业陪伴', emoji: '💗', bg: '#FFFCE7F3' },
    { business: Const.BIZ_STUDY,   title: '学习辅导', subtitle: '高效学习的小教练', emoji: '📚', bg: '#FFDBEAFE' },
    { business: Const.BIZ_GENERAL, title: '综合聊天', subtitle: '随便聊，什么都可以', emoji: '✨', bg: '#FFFEF3C7' }
  ];

  aboutToAppear(): void { this.load(); }

  async load() {
    try {
      const r = await AiApi.sessions();
      this.recent = r.slice(0, 5);
    } catch (e) {}
  }

  async startNew(business: string) {
    try {
      const s = await AiApi.createSession(business);
      router.pushUrl({ url: 'view/ai/ChatPage', params: { sessionId: s.id, business: s.business, title: s.title } });
    } catch (e) {}
  }

  build() {
    Column() {
      Row() {
        Text('AI 咨询').fontSize(20).fontWeight(FontWeight.Bold)
        Blank()
        Image($r('sys.media.ohos_ic_public_clock')).width(24).height(24)
          .onClick(() => router.pushUrl({ url: 'view/ai/HistoryPage' }))
      }.width('100%').padding(16).backgroundColor(Color.White)

      Scroll() {
        Column({ space: 14 }) {
          Text('选择业务方向').fontSize(14).fontColor($r('app.color.text_sub'))
            .width('100%').margin({ top: 6 })

          ForEach(this.cards, (c: BizCard) => {
            Row({ space: 14 }) {
              Text(c.emoji).fontSize(36)
              Column() {
                Text(c.title).fontSize(17).fontWeight(FontWeight.Bold)
                Text(c.subtitle).fontSize(12).fontColor($r('app.color.text_sub')).margin({ top: 4 })
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              Image($r('sys.media.ohos_ic_public_arrow_right')).width(20).height(20).fillColor($r('app.color.text_sub'))
            }
            .width('100%').padding(18).backgroundColor(c.bg).borderRadius(14)
            .onClick(() => this.startNew(c.business))
          })

          if (this.recent.length > 0) {
            Text('最近会话').fontSize(14).fontColor($r('app.color.text_sub'))
              .width('100%').margin({ top: 12 })

            ForEach(this.recent, (s: AiSessionVo) => {
              Row({ space: 10 }) {
                Text(this.bizEmoji(s.business)).fontSize(24)
                Column() {
                  Text(s.title).fontSize(14).fontWeight(FontWeight.Medium)
                  Text(s.lastMsg || '暂无消息').fontSize(12).fontColor($r('app.color.text_sub'))
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 4 })
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                Text(TimeUtil.fromNow(s.updatedAt)).fontSize(11).fontColor($r('app.color.text_sub'))
              }
              .width('100%').padding(14).backgroundColor(Color.White).borderRadius(10)
              .onClick(() => router.pushUrl({ url: 'view/ai/ChatPage', params: { sessionId: s.id, business: s.business, title: s.title } }))
            }, (s: AiSessionVo) => s.id.toString())
          }
        }.padding(14)
      }.layoutWeight(1)
    }.width('100%').height('100%')
  }

  bizEmoji(b: string): string {
    if (b === 'mental') return '💗';
    if (b === 'study') return '📚';
    return '✨';
  }
}
