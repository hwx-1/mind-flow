import { router } from '@kit.ArkUI';
import { MessageApi, UserApi } from '../../api/Api';
import { NotificationVo, ChatConvVo, FriendVo } from '../../model/Models';
import { TimeUtil } from '../../utils/TimeUtil';
import { Ws, WsEventHandler, WsStatusHandler } from '../../api/WsClient';
import { GlassLoading } from '../common/GlassLoading';

@Component
export struct MessagePage {
  @StorageProp('themePrimary') themePrimary: string = '#D98E73';
  @StorageProp('themePrimaryLight') themePrimaryLight: string = '#F3ECE1';
  @State private notes: NotificationVo[] = [];
  @State private chats: ChatConvVo[] = [];
  @State private friends: FriendVo[] = [];
  @State private unread: Record<string, number> = {};
  @State private refreshing: boolean = false;
  @State private loading: boolean = false;
  @State private showNotifications: boolean = false;
  @State private searchText: string = '';
  // 聊天页已读/发送后自增此值，触发 onMsgSignal 刷新会话与未读数（子组件 onPageShow 不会触发，故用 AppStorage）
  @StorageProp('msgRefreshTick') @Watch('onMsgSignal') private msgTick: number = 0;
  // 兜底轮询定时器：仅在 WS 断开期间启用，连接恢复即停止
  private fallbackTimer: number = -1;
  private static readonly FALLBACK_INTERVAL: number = 30000;

  private wsHandler: WsEventHandler = (event: string, _data: object): void => {
    if (event === 'chat' || event === 'ack' || event === 'notification') {
      this.refresh();
    }
  };

  // WS 连上 → 停轮询并立即同步一次；WS 断开 → 启动兜底轮询
  private statusHandler: WsStatusHandler = (connected: boolean): void => {
    if (connected) {
      this.stopFallbackPolling();
      this.refresh();
    } else {
      this.startFallbackPolling();
    }
  };

  aboutToAppear(): void {
    Ws.connect();
    Ws.on(this.wsHandler);
    Ws.onStatus(this.statusHandler);
    this.refresh();
    if (!Ws.isConnected()) {
      this.startFallbackPolling();
    }
  }

  onMsgSignal(): void {
    this.refresh();
  }

  aboutToDisappear(): void {
    Ws.off(this.wsHandler);
    Ws.offStatus(this.statusHandler);
    this.stopFallbackPolling();
  }

  private startFallbackPolling(): void {
    if (this.fallbackTimer >= 0) {
      return;
    }
    this.fallbackTimer = setInterval((): void => {
      this.refresh();
    }, MessagePage.FALLBACK_INTERVAL);
  }

  private stopFallbackPolling(): void {
    if (this.fallbackTimer >= 0) {
      clearInterval(this.fallbackTimer);
      this.fallbackTimer = -1;
    }
  }

  async refresh(): Promise<void> {
    if (this.loading) {
      return;
    }
    this.loading = true;
    try {
      this.notes = await MessageApi.notifications('all');
      this.chats = await MessageApi.chats();
      this.friends = await UserApi.friends();
      this.unread = await MessageApi.unreadCount();
    } catch (e) {
    } finally {
      this.loading = false;
      this.refreshing = false;
    }
  }

  private notificationUnread(): number {
    return (this.unread['like'] || 0) + (this.unread['comment'] || 0) + (this.unread['follow'] || 0) + (this.unread['friend'] || 0);
  }

  private latestNotification(): string {
    if (this.notes.length === 0) {
      return '暂无新的互动消息';
    }
    return this.notes[0].content || '有新的互动消息';
  }

  private friendSubtitle(): string {
    if (this.friends.length === 0) {
      return '查看好友申请或添加好友';
    }
    return `${this.friends.length} 位好友`;
  }

  private noteIcon(t: string): string {
    if (t === 'like') {
      return '赞';
    }
    if (t === 'comment') {
      return '评';
    }
    if (t === 'friend') {
      return '友';
    }
    return '关';
  }

  @Builder
  FriendEntry() {
    Row({ space: 12 }) {
      Stack() {
        Text('友')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .width(48)
          .height(48)
          .textAlign(TextAlign.Center)
          .borderRadius(8)
          .backgroundColor(this.themePrimary)
      }
      .width(48)
      .height(48)

      Column({ space: 5 }) {
        Text('好友列表')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_main'))
          .width('100%')
        Text(this.friendSubtitle())
          .fontSize(13)
          .fontColor($r('app.color.text_sub'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Image($r('sys.media.ohos_ic_public_arrow_right'))
        .width(16)
        .height(16)
        .fillColor($r('app.color.text_sub'))
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.card_bg'))
    .onClick(() => router.pushUrl({ url: 'view/message/FriendListPage' }))
  }

  private markAllNotificationsRead(): void {
    MessageApi.markRead('all').then((): void => {
      this.refresh();
    });
  }

  private matchSearch(c: ChatConvVo): boolean {
    const q = this.searchText.trim().toLowerCase();
    if (!q) {
      return true;
    }
    return (c.nickname || '用户').toLowerCase().includes(q) ||
      (c.lastMessage || '').toLowerCase().includes(q);
  }

  @Builder
  Header() {
    Column({ space: 10 }) {
      Row() {
        Text('消息')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_main'))
        Blank()
        Stack() {
          Text('+')
            .fontSize(28)
            .fontColor($r('app.color.text_main'))
            .width(34)
            .height(34)
            .textAlign(TextAlign.Center)
            .borderRadius(17)
            .backgroundColor($r('app.color.bg_page'))
            .onClick(() => router.pushUrl({ url: 'view/message/AddFriendPage' }))
        }
      }
      .width('100%')

      Row({ space: 8 }) {
        Text('搜索')
          .fontSize(13)
          .fontColor($r('app.color.text_sub'))
        TextInput({ placeholder: '搜索', text: this.searchText })
          .layoutWeight(1)
          .height(36)
          .fontSize(14)
          .backgroundColor(Color.Transparent)
          .padding(0)
          .onChange((value: string) => this.searchText = value)
        if (this.searchText.length > 0) {
          Text('清除')
            .fontSize(13)
            .fontColor(this.themePrimary)
            .padding({ left: 8, right: 2, top: 6, bottom: 6 })
            .onClick(() => this.searchText = '')
        }
      }
      .width('100%')
      .height(40)
      .padding({ left: 12, right: 12 })
      .borderRadius(14)
      .backgroundColor($r('app.color.bg_page'))
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 12 })
    .backgroundColor($r('app.color.card_bg'))
    .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })
  }

  @Builder
  NotificationEntry() {
    Row({ space: 12 }) {
      Stack() {
        Text('互')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .width(48)
          .height(48)
          .textAlign(TextAlign.Center)
          .borderRadius(8)
          .backgroundColor($r('app.color.accent'))
        if (this.notificationUnread() > 0) {
          Text(this.notificationUnread() > 99 ? '99+' : this.notificationUnread().toString())
            .fontSize(10)
            .fontColor(Color.White)
            .height(18)
            .padding({ left: 6, right: 6 })
            .borderRadius(9)
            .backgroundColor($r('app.color.danger'))
            .position({ x: 34, y: -5 })
        }
      }
      .width(48)
      .height(48)

      Column({ space: 5 }) {
        Row() {
          Text('互动消息')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_main'))
            .layoutWeight(1)
          if (this.notes.length > 0) {
            Text(TimeUtil.fromNow(this.notes[0].createdAt))
              .fontSize(12)
              .fontColor($r('app.color.text_sub'))
          }
        }
        .width('100%')
        Text(this.latestNotification())
          .fontSize(13)
          .fontColor($r('app.color.text_sub'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.notificationUnread() > 0) {
        Text('已读')
          .fontSize(13)
          .fontColor(this.themePrimary)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(14)
          .backgroundColor(this.themePrimaryLight)
          .onClick(() => this.markAllNotificationsRead())
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.card_bg'))
    .onClick(() => this.showNotifications = !this.showNotifications)
  }

  @Builder
  NotificationList() {
    Column() {
      ForEach(this.notes, (n: NotificationVo) => {
        Row({ space: 10 }) {
          Text(this.noteIcon(n.type))
            .fontSize(12)
            .fontColor(Color.White)
            .width(28)
            .height(28)
            .textAlign(TextAlign.Center)
            .borderRadius(14)
            .backgroundColor(n.type === 'comment' ? $r('app.color.accent') : (n.type === 'like' ? $r('app.color.danger') : this.themePrimary))
          Column({ space: 4 }) {
            Row() {
              Text(n.nickname || '系统')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_main'))
              if (n.isRead === 0) {
                Text('')
                  .width(6)
                  .height(6)
                  .borderRadius(3)
                  .backgroundColor($r('app.color.danger'))
                  .margin({ left: 6 })
              }
            }
            Text(n.content)
              .fontSize(13)
              .fontColor($r('app.color.text_sub'))
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding({ left: 76, right: 16, top: 8, bottom: 8 })
        .backgroundColor($r('app.color.card_bg'))
        .onClick((): void => {
          MessageApi.markRead(n.type, [n.id]).then((): void => {
            this.refresh();
          });
          if (n.type === 'friend') {
            router.pushUrl({ url: 'view/message/AddFriendPage' });
          } else if (n.type === 'follow' && n.targetId) {
            router.pushUrl({ url: 'view/community/UserPostsPage', params: { userId: n.targetId } });
          } else if (n.targetId) {
            router.pushUrl({ url: 'view/community/PostDetailPage', params: { id: n.targetId } });
          }
        })
      }, (n: NotificationVo) => n.id.toString())
    }
    .width('100%')
  }

  @Builder
  ConversationRow(c: ChatConvVo) {
    Row({ space: 12 }) {
      Stack() {
        if (c.avatar) {
          Image(c.avatar)
            .width(48)
            .height(48)
          .borderRadius(14)
            .objectFit(ImageFit.Cover)
        } else {
          Text((c.nickname || '用').substring(0, 1))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .width(48)
            .height(48)
            .textAlign(TextAlign.Center)
            .borderRadius(8)
            .backgroundColor(this.themePrimary)
        }
        if (c.unreadCount && c.unreadCount > 0) {
          Text(c.unreadCount > 99 ? '99+' : c.unreadCount.toString())
            .fontSize(10)
            .fontColor(Color.White)
            .height(18)
            .padding({ left: 6, right: 6 })
            .borderRadius(9)
            .backgroundColor($r('app.color.danger'))
            .position({ x: 34, y: -5 })
        }
      }
      .width(48)
      .height(48)

      Column({ space: 5 }) {
        Row() {
          Text(c.nickname || '用户')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_main'))
            .layoutWeight(1)
          Text(TimeUtil.fromNow(c.updatedAt))
            .fontSize(12)
            .fontColor($r('app.color.text_sub'))
        }
        .width('100%')
        Text(c.lastMessage || '')
          .fontSize(13)
          .fontColor($r('app.color.text_sub'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.card_bg'))
    .onClick(() => router.pushUrl({
      url: 'view/message/ChatRoomPage',
      params: { userId: c.userId, nickname: c.nickname, avatar: c.avatar }
    }))
  }

  build() {
    Column() {
      this.Header()

      Refresh({ refreshing: $$this.refreshing }) {
        List({ space: 0 }) {
          ListItem() {
            this.NotificationEntry()
          }

          if (this.showNotifications) {
            ListItem() {
              this.NotificationList()
            }
          }

          ListItem() {
            this.FriendEntry()
          }

          ListItem() {
            Text('消息列表')
              .fontSize(12)
              .fontColor($r('app.color.text_sub'))
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 6 })
              .backgroundColor($r('app.color.bg_page'))
          }

          ForEach(this.chats, (c: ChatConvVo) => {
            if (this.matchSearch(c)) {
              ListItem() {
                this.ConversationRow(c)
              }
            }
          }, (c: ChatConvVo) => c.userId.toString())

          if (this.loading && this.chats.length === 0) {
            ListItem() {
              Column() {
                GlassLoading({ message: '同步消息' })
              }
              .width('100%')
              .padding({ top: 80 })
              .alignItems(HorizontalAlign.Center)
            }
          }

          if (!this.loading && this.chats.length === 0) {
            ListItem() {
              Text('暂无会话')
                .fontSize(13)
                .fontColor($r('app.color.text_sub'))
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding(48)
            }
          }
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 0.5, color: $r('app.color.divider'), startMargin: 76 })
      }
      .layoutWeight(1)
      .onRefreshing(() => this.refresh())
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
