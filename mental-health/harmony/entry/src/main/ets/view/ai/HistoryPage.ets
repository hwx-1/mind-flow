import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AiApi } from '../../api/Api';
import { AiSessionVo } from '../../model/Models';
import { TimeUtil } from '../../utils/TimeUtil';

@Entry
@Component
struct HistoryPage {
  @State list: AiSessionVo[] = [];
  @State filter: string = ''; // '' / mental / study / general

  aboutToAppear(): void { this.load(); }

  async load() {
    try { this.list = await AiApi.sessions(this.filter || undefined); } catch (e) {}
  }

  async del(id: number) {
    AlertDialog.show({
      message: '确定删除该会话？',
      primaryButton: {
        value: '取消', action: () => {}
      },
      secondaryButton: {
        value: '删除', fontColor: $r('app.color.danger'),
        action: async () => {
          try { await AiApi.deleteSession(id); this.load(); promptAction.showToast({ message: '已删除' }); } catch (e) {}
        }
      }
    });
  }

  emoji(b: string): string {
    if (b === 'mental') return '💗';
    if (b === 'study') return '📚';
    return '✨';
  }

  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left')).width(24).height(24)
          .onClick(() => router.back())
        Text('历史会话').fontSize(17).fontWeight(FontWeight.Medium).margin({ left: 12 })
      }.width('100%').padding(14).backgroundColor(Color.White)

      Row({ space: 10 }) {
        ForEach(
          [{ k: '',       l: '全部' }, { k: 'mental', l: '心理' }, { k: 'study', l: '学习' }, { k: 'general', l: '综合' }],
          (it: Record<string, string>) => {
            Text(it.l)
              .fontSize(13)
              .fontColor(this.filter === it.k ? Color.White : $r('app.color.text_sub'))
              .backgroundColor(this.filter === it.k ? $r('app.color.primary') : $r('app.color.bg_page'))
              .padding({ left: 14, right: 14, top: 6, bottom: 6 })
              .borderRadius(14)
              .onClick(() => { this.filter = it.k; this.load(); })
          }
        )
      }.padding(12).width('100%').backgroundColor(Color.White)

      List({ space: 8 }) {
        ForEach(this.list, (s: AiSessionVo) => {
          ListItem() {
            Row({ space: 12 }) {
              Text(this.emoji(s.business)).fontSize(24)
              Column() {
                Text(s.title).fontSize(15).fontWeight(FontWeight.Medium)
                Text(s.lastMsg || '暂无消息').fontSize(12).fontColor($r('app.color.text_sub'))
                  .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 4 })
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              Text(TimeUtil.fromNow(s.updatedAt)).fontSize(11).fontColor($r('app.color.text_sub'))
            }.width('100%').padding(14).backgroundColor(Color.White).borderRadius(10)
              .onClick(() => router.pushUrl({ url: 'view/ai/ChatPage', params: { sessionId: s.id, business: s.business, title: s.title } }))
          }
          .swipeAction({
            end: {
              builder: () => {
                Text('删除').fontColor(Color.White).fontSize(14)
                  .width(72).height('100%').textAlign(TextAlign.Center)
                  .backgroundColor($r('app.color.danger'))
                  .onClick(() => this.del(s.id))
              }
            }
          })
        }, (s: AiSessionVo) => s.id.toString())

        if (this.list.length === 0) {
          ListItem() {
            Text('暂无历史会话').fontSize(13).fontColor($r('app.color.text_sub'))
              .width('100%').textAlign(TextAlign.Center).padding(40)
          }
        }
      }.layoutWeight(1).padding(12)
    }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
