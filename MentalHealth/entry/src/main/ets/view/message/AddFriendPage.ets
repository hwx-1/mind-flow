import { promptAction, router } from '@kit.ArkUI';
import { UserApi } from '../../api/Api';
import { FriendRequestVo } from '../../model/Models';
import { TimeUtil } from '../../utils/TimeUtil';

@Entry
@Component
struct AddFriendPage {
  @StorageProp('themePrimary') themePrimary: string = '#D98E73';
  @State private uid: string = '';
  @State private message: string = '请求添加你为好友';
  @State private requests: FriendRequestVo[] = [];
  @State private loading: boolean = false;

  aboutToAppear(): void {
    this.loadRequests();
  }

  async loadRequests(): Promise<void> {
    try {
      this.requests = await UserApi.friendRequests();
    } catch (e) {}
  }

  async sendRequest(): Promise<void> {
    if (!this.uid.trim() || this.loading) return;
    this.loading = true;
    try {
      await UserApi.requestFriendByUid(this.uid.trim(), this.message.trim() || '请求添加你为好友');
      promptAction.showToast({ message: '申请已发送' });
      this.uid = '';
      this.message = '请求添加你为好友';
    } catch (e) {
    } finally {
      this.loading = false;
    }
  }

  async accept(id: number): Promise<void> {
    try {
      await UserApi.acceptFriend(id);
      promptAction.showToast({ message: '已同意' });
      await this.loadRequests();
    } catch (e) {}
  }

  @Builder
  RequestRow(req: FriendRequestVo) {
    Row({ space: 10 }) {
      Image(req.avatar || $r('app.media.icon'))
        .width(42)
        .height(42)
        .borderRadius(21)
        .objectFit(ImageFit.Cover)
      Column({ space: 4 }) {
        Text(req.nickname || '用户')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_main'))
        Text(`UID ${String(req.uid ?? req.fromUser)} · ${req.message || '请求添加你为好友'}`)
          .fontSize(12)
          .fontColor($r('app.color.text_sub'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(TimeUtil.fromNow(req.createdAt))
          .fontSize(11)
          .fontColor($r('app.color.text_sub'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text('同意')
        .fontSize(12)
        .fontColor(Color.White)
        .height(30)
        .padding({ left: 14, right: 14 })
        .borderRadius(15)
        .backgroundColor(this.themePrimary)
        .onClick(() => this.accept(req.id))
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.card_bg'))
  }

  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(22)
          .height(22)
          .onClick(() => router.back())
        Text('添加好友')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_main'))
          .margin({ left: 12 })
      }
      .width('100%')
      .height(52)
      .padding({ left: 14, right: 14 })
      .backgroundColor($r('app.color.card_bg'))

      Column({ space: 10 }) {
        TextInput({ placeholder: '输入对方 UID', text: this.uid })
          .height(42)
          .fontSize(14)
          .backgroundColor($r('app.color.bg_page'))
          .borderRadius(21)
          .padding({ left: 14, right: 14 })
          .onChange((value: string) => this.uid = value)
        TextInput({ placeholder: '验证消息', text: this.message })
          .height(42)
          .fontSize(14)
          .backgroundColor($r('app.color.bg_page'))
          .borderRadius(21)
          .padding({ left: 14, right: 14 })
          .onChange((value: string) => this.message = value)
        Text(this.loading ? '发送中' : '发送好友申请')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .width('100%')
          .height(40)
          .textAlign(TextAlign.Center)
          .borderRadius(20)
          .backgroundColor(this.themePrimary)
          .onClick(() => this.sendRequest())
      }
      .width('100%')
      .padding(14)
      .backgroundColor($r('app.color.card_bg'))

      Text('好友申请')
        .fontSize(12)
        .fontColor($r('app.color.text_sub'))
        .width('100%')
        .padding({ left: 14, top: 14, bottom: 6 })

      List({ space: 8 }) {
        ForEach(this.requests, (req: FriendRequestVo) => {
          ListItem() {
            this.RequestRow(req)
          }
        }, (req: FriendRequestVo) => req.id.toString())

        if (this.requests.length === 0) {
          ListItem() {
            Text('暂无待处理申请')
              .fontSize(13)
              .fontColor($r('app.color.text_sub'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(48)
          }
        }
      }
      .layoutWeight(1)
      .padding({ left: 10, right: 10 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
