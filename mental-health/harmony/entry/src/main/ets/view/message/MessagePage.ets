import router from '@ohos.router';
import { MessageApi } from '../../api/Api';
import { NotificationVo, ChatConvVo } from '../../model/Models';
import { TimeUtil } from '../../utils/TimeUtil';

@Component
export struct MessagePage {
  @State tab: number = 0;
  @State notes: NotificationVo[] = [];
  @State chats: ChatConvVo[] = [];
  @State unread: Record<string, number> = {};

  aboutToAppear(): void { this.refresh(); }
  onPageShow(): void { this.refresh(); }

  async refresh() {
    try {
      this.notes = await MessageApi.notifications('all');
      this.chats = await MessageApi.chats();
      this.unread = await MessageApi.unreadCount();
    } catch (e) {}
  }

  noteIcon(t: string): string {
    if (t === 'like') return '❤️';
    if (t === 'comment') return '💬';
    return '👤';
  }

  build() {
    Column() {
      Row() {
        Text('消息').fontSize(20).fontWeight(FontWeight.Bold)
      }.width('100%').padding(16).backgroundColor(Color.White)

      Row() {
        ForEach(['通知', '私信'], (l: string, i: number) => {
          Column() {
            Text(l).fontSize(15)
              .fontWeight(this.tab === i ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.tab === i ? $r('app.color.primary') : $r('app.color.text_sub'))
            Divider().color($r('app.color.primary'))
              .strokeWidth(2).width(24).margin({ top: 6 })
              .opacity(this.tab === i ? 1 : 0)
          }.layoutWeight(1).onClick(() => this.tab = i)
        })
      }.width('100%').backgroundColor(Color.White).padding({ top: 6 })

      if (this.tab === 0) {
        List({ space: 0 }) {
          ForEach(this.notes, (n: NotificationVo) => {
            ListItem() {
              Row({ space: 12 }) {
                Text(this.noteIcon(n.type)).fontSize(24)
                Column() {
                  Row() {
                    Text(n.nickname || '系统').fontSize(14).fontWeight(FontWeight.Medium)
                    if (n.isRead === 0) {
                      Text(' ').width(6).height(6)
                        .backgroundColor($r('app.color.danger')).borderRadius(3)
                        .margin({ left: 4 })
                    }
                  }
                  Text(n.content).fontSize(13).fontColor($r('app.color.text_sub'))
                    .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 2 })
                  Text(TimeUtil.fromNow(n.createdAt)).fontSize(11)
                    .fontColor($r('app.color.text_sub')).margin({ top: 4 })
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              }
              .width('100%').padding(14).backgroundColor(Color.White)
              .onClick(() => {
                if (n.targetId) router.pushUrl({ url: 'view/community/PostDetailPage', params: { id: n.targetId } });
                MessageApi.markRead(n.type, [n.id]).then(() => this.refresh());
              })
            }
          }, (n: NotificationVo) => n.id.toString())

          if (this.notes.length === 0) {
            ListItem() {
              Text('暂无通知').fontSize(13).fontColor($r('app.color.text_sub'))
                .width('100%').textAlign(TextAlign.Center).padding(48)
            }
          }
        }.layoutWeight(1).divider({ strokeWidth: 0.5, color: $r('app.color.divider') })
      } else {
        List({ space: 0 }) {
          ForEach(this.chats, (c: ChatConvVo) => {
            ListItem() {
              Row({ space: 12 }) {
                Image(c.avatar || $r('app.media.icon')).width(46).height(46).borderRadius(23)
                Column() {
                  Row() {
                    Text(c.nickname || '用户').fontSize(15).fontWeight(FontWeight.Medium).layoutWeight(1)
                    Text(TimeUtil.fromNow(c.updatedAt)).fontSize(11).fontColor($r('app.color.text_sub'))
                  }.width('100%')
                  Row() {
                    Text(c.lastMessage || '').fontSize(13).fontColor($r('app.color.text_sub'))
                      .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
                    if (c.unreadCount && c.unreadCount > 0) {
                      Text(c.unreadCount > 99 ? '99+' : c.unreadCount.toString())
                        .fontSize(10).fontColor(Color.White)
                        .backgroundColor($r('app.color.danger')).borderRadius(10)
                        .padding({ left: 6, right: 6, top: 1, bottom: 1 })
                    }
                  }.width('100%').margin({ top: 4 })
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              }
              .width('100%').padding(12).backgroundColor(Color.White)
              .onClick(() => router.pushUrl({ url: 'view/message/ChatRoomPage', params: { userId: c.userId, nickname: c.nickname } }))
            }
          }, (c: ChatConvVo) => c.userId.toString())

          if (this.chats.length === 0) {
            ListItem() {
              Text('暂无私信').fontSize(13).fontColor($r('app.color.text_sub'))
                .width('100%').textAlign(TextAlign.Center).padding(48)
            }
          }
        }.layoutWeight(1).divider({ strokeWidth: 0.5, color: $r('app.color.divider') })
      }
    }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
