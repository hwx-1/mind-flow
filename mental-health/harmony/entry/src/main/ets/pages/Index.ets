import { CommunityPage } from '../view/community/CommunityPage';
import { AIHomePage } from '../view/ai/AIHomePage';
import { MessagePage } from '../view/message/MessagePage';
import { MinePage } from '../view/mine/MinePage';
import { Ws } from '../api/WsClient';
import { MessageApi } from '../api/Api';

@Entry
@Component
struct Index {
  @State current: number = 0;
  @State unreadTotal: number = 0;

  aboutToAppear(): void {
    Ws.connect();
    this.loadUnread();
    Ws.on((event, _data) => {
      if (event === 'chat') this.loadUnread();
    });
  }

  aboutToDisappear(): void { Ws.close(); }

  loadUnread(): void {
    MessageApi.unreadCount().then(r => {
      let sum = 0;
      Object.keys(r).forEach(k => { sum += (r[k] || 0); });
      this.unreadTotal = sum;
    }).catch(() => {});
  }

  @Builder
  TabItem(icon: Resource, label: string, idx: number, badge?: number) {
    Column() {
      Stack() {
        Image(icon).width(26).height(26)
          .fillColor(this.current === idx ? $r('app.color.primary') : $r('app.color.text_sub'))
        if (badge !== undefined && badge > 0) {
          Text(badge > 99 ? '99+' : badge.toString())
            .fontSize(10).fontColor(Color.White)
            .backgroundColor($r('app.color.danger'))
            .borderRadius(10).padding({ left: 5, right: 5, top: 1, bottom: 1 })
            .position({ x: 18, y: -4 })
        }
      }.width(30).height(30)
      Text(label).fontSize(11).margin({ top: 2 })
        .fontColor(this.current === idx ? $r('app.color.primary') : $r('app.color.text_sub'))
    }
    .layoutWeight(1).justifyContent(FlexAlign.Center).padding({ top: 6, bottom: 6 })
    .onClick(() => this.current = idx)
  }

  build() {
    Column() {
      Tabs({ index: this.current }) {
        TabContent() { CommunityPage() }
        TabContent() { AIHomePage() }
        TabContent() { MessagePage() }
        TabContent() { MinePage() }
      }
      .barHeight(0)
      .layoutWeight(1)
      .scrollable(false)
      .onChange(i => this.current = i)

      Row() {
        this.TabItem($r('app.media.tab_community'), '社区', 0)
        this.TabItem($r('app.media.tab_ai'), 'AI', 1)
        this.TabItem($r('app.media.tab_message'), '消息', 2, this.unreadTotal)
        this.TabItem($r('app.media.tab_mine'), '我的', 3)
      }
      .width('100%').backgroundColor(Color.White)
      .border({ width: { top: 0.5 }, color: $r('app.color.divider') })
    }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
