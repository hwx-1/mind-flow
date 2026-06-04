import { CommunityPage } from '../view/community/CommunityPage';
import { AIHomePage } from '../view/ai/AIHomePage';
import { MessagePage } from '../view/message/MessagePage';
import { MinePage } from '../view/mine/MinePage';
import { Ws } from '../api/WsClient';
import { MessageApi, AnnouncementApi } from '../api/Api';
import { LaunchSplash } from '../view/common/LaunchSplash';
import { AnnouncementVo } from '../model/Models';
import { AnnouncementStore } from '../store/AnnouncementStore';
import { AnnouncementDialog } from '../view/common/AnnouncementDialog';

@Entry
@Component
struct Index {
  @StorageProp('themePrimary') themePrimary: string = '#D98E73';
  @State current: number = 0;
  @State unreadTotal: number = 0;
  @State showSplash: boolean = true;
  private annController: CustomDialogController | null = null;

  private onWsEvent = (event: string, _data: object): void => {
    if (event === 'chat' || event === 'notification') {
      this.loadUnread();
    }
  };

  aboutToAppear(): void {
    Ws.connect();
    Ws.on(this.onWsEvent);
    this.loadUnread();
    setTimeout(() => this.dismissSplash(), 1800);
    // 闪屏结束后再弹公告，避免被遮挡
    setTimeout(() => this.loadAnnouncement(), 2000);
  }

  private loadAnnouncement(): void {
    AnnouncementApi.latest().then((a: AnnouncementVo | null): void => {
      if (a !== null && a.content !== undefined && a.content.length > 0
        && AnnouncementStore.shouldShow(a.id)) {
        this.showAnnouncement(a);
      }
    }).catch((): void => {});
  }

  private showAnnouncement(a: AnnouncementVo): void {
    const id: number = a.id;
    this.annController = new CustomDialogController({
      builder: AnnouncementDialog({
        title: (a.title !== undefined && a.title.length > 0) ? a.title : '公告',
        content: a.content,
        onNeverDay: (): void => AnnouncementStore.dismissForDay(id)
      }),
      autoCancel: false,
      customStyle: true,
      alignment: DialogAlignment.Center
    });
    this.annController.open();
  }

  aboutToDisappear(): void {
    Ws.off(this.onWsEvent);
    Ws.close();
  }

  loadUnread(): void {
    MessageApi.unreadCount().then(r => {
      let sum = 0;
      Object.keys(r).forEach(k => { sum += (r[k] || 0); });
      this.unreadTotal = sum;
    }).catch(() => {});
  }

  dismissSplash(): void {
    if (!this.showSplash) {
      return;
    }
    this.showSplash = false;
  }

  @Builder
  TabItem(icon: Resource, label: string, idx: number, badge?: number) {
    Column() {
      Stack() {
        Image(icon).width(26).height(26)
          .fillColor(this.current === idx ? this.themePrimary : $r('app.color.text_sub'))
        if (badge !== undefined && badge > 0) {
          Text(badge > 99 ? '99+' : badge.toString())
            .fontSize(10).fontColor(Color.White)
            .backgroundColor($r('app.color.danger'))
            .borderRadius(10).padding({ left: 5, right: 5, top: 1, bottom: 1 })
            .position({ x: 18, y: -4 })
        }
      }.width(30).height(30)
      Text(label)
        .fontSize(11)
        .margin({ top: 2 })
        .fontColor(this.current === idx ? this.themePrimary : $r('app.color.text_sub'))
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .padding({ top: 6, bottom: 6 })
    .scale({ x: this.current === idx ? 1.04 : 1, y: this.current === idx ? 1.04 : 1 })
    .animation({ duration: 220, curve: Curve.Friction })
    .onClick(() => {
      animateTo({ duration: 240, curve: Curve.Friction }, () => {
        this.current = idx;
      });
    })
  }

  build() {
    Stack() {
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
        .animationDuration(260)
        .onChange(i => this.current = i)

        Row() {
          this.TabItem($r('sys.media.ohos_ic_public_albums'), '社区', 0)
          this.TabItem($r('sys.media.ohos_ic_public_email'), 'AI', 1)
          this.TabItem($r('sys.media.ohos_ic_public_email'), '消息', 2, this.unreadTotal)
          this.TabItem($r('sys.media.ohos_ic_public_phone'), '我的', 3)
        }
        .width('100%')
        .backgroundColor($r('app.color.card_bg'))
        .border({ width: { top: 0.5 }, color: $r('app.color.divider') })
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.bg_page'))

      if (this.showSplash) {
        LaunchSplash({ onSkip: () => this.dismissSplash() })
          .zIndex(99)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
