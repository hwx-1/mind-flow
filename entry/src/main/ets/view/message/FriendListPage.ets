import { router } from '@kit.ArkUI';
import { UserApi } from '../../api/Api';
import { FriendVo } from '../../model/Models';
import { ProfileStatusUtil } from '../../utils/ProfileStatusUtil';
import { GlassLoading } from '../common/GlassLoading';

@Entry
@Component
struct FriendListPage {
  @StorageProp('themePrimary') themePrimary: string = '#D98E73';
  @State private friends: FriendVo[] = [];
  @State private loading: boolean = false;
  @State private searchText: string = '';

  aboutToAppear(): void {
    this.loadFriends();
  }

  onPageShow(): void {
    this.loadFriends();
  }

  async loadFriends(): Promise<void> {
    if (this.loading) {
      return;
    }
    this.loading = true;
    try {
      this.friends = await UserApi.friends();
    } catch (e) {
      const err = e as Error;
      console.error(`load friends failed: ${err.message || 'unknown error'}`);
    } finally {
      this.loading = false;
    }
  }

  private displayName(friend: FriendVo): string {
    return friend.nickname || friend.username || '用户';
  }

  private uidText(friend: FriendVo): string {
    return String(friend.uid ?? friend.id);
  }

  private matchSearch(friend: FriendVo): boolean {
    const q = this.searchText.trim().toLowerCase();
    if (!q) {
      return true;
    }
    return this.displayName(friend).toLowerCase().includes(q) ||
      this.uidText(friend).toLowerCase().includes(q);
  }

  private statusText(friend: FriendVo): string {
    const status = friend.profileStatus || '在线';
    return `${friend.online ? '在线' : '离线'} · ${status}`;
  }

  private openChat(friend: FriendVo): void {
    router.pushUrl({
      url: 'view/message/ChatRoomPage',
      params: {
        userId: friend.id,
        nickname: this.displayName(friend),
        avatar: friend.avatar || ''
      }
    });
  }

  @Builder
  Avatar(friend: FriendVo) {
    if (friend.avatar) {
      Image(friend.avatar)
        .width(46)
        .height(46)
        .borderRadius(23)
        .objectFit(ImageFit.Cover)
    } else {
      Text(this.displayName(friend).substring(0, 1))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .width(46)
        .height(46)
        .textAlign(TextAlign.Center)
        .borderRadius(23)
        .backgroundColor(this.themePrimary)
    }
  }

  @Builder
  FriendRow(friend: FriendVo) {
    Row({ space: 12 }) {
      Stack() {
        this.Avatar(friend)
        Text('')
          .width(10)
          .height(10)
          .borderRadius(5)
          .backgroundColor(friend.online ? '#FF7D9268' : '#FFCFC7BC')
          .border({ width: 2, color: $r('app.color.card_bg') })
          .position({ x: 35, y: 35 })
      }
      .width(46)
      .height(46)

      Column({ space: 5 }) {
        Text(this.displayName(friend))
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_main'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 6 }) {
          Text(this.statusText(friend))
            .fontSize(12)
            .fontColor(ProfileStatusUtil.styleOf(friend.profileStatus).color)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(10)
            .backgroundColor(ProfileStatusUtil.styleOf(friend.profileStatus).tint)
          Text(`UID ${this.uidText(friend)}`)
            .fontSize(12)
            .fontColor($r('app.color.text_sub'))
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('发消息')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .height(32)
        .padding({ left: 14, right: 14 })
        .borderRadius(16)
        .backgroundColor(this.themePrimary)
        .onClick(() => this.openChat(friend))
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.card_bg'))
  }

  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24)
          .height(24)
          .fillColor($r('app.color.text_main'))
          .onClick(() => router.back())
        Text('好友列表')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_main'))
          .margin({ left: 12 })
          .layoutWeight(1)
        Text('添加')
          .fontSize(13)
          .fontColor(this.themePrimary)
          .padding({ left: 10, right: 4, top: 6, bottom: 6 })
          .onClick(() => router.pushUrl({ url: 'view/message/AddFriendPage' }))
      }
      .width('100%')
      .height(54)
      .padding({ left: 14, right: 14 })
      .backgroundColor($r('app.color.card_bg'))
      .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })

      Row({ space: 8 }) {
        Text('搜索')
          .fontSize(13)
          .fontColor($r('app.color.text_sub'))
        TextInput({ placeholder: '搜索好友或 UID', text: this.searchText })
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
      .margin({ left: 14, right: 14, top: 12, bottom: 8 })
      .padding({ left: 12, right: 12 })
      .borderRadius(14)
      .backgroundColor($r('app.color.card_bg'))

      List({ space: 0 }) {
        ForEach(this.friends, (friend: FriendVo) => {
          if (this.matchSearch(friend)) {
            ListItem() {
              this.FriendRow(friend)
            }
          }
        }, (friend: FriendVo) => friend.id.toString())

        if (this.loading && this.friends.length === 0) {
          ListItem() {
            Column() {
              GlassLoading({ message: '同步好友' })
            }
            .width('100%')
            .padding({ top: 80 })
            .alignItems(HorizontalAlign.Center)
          }
        }

        if (!this.loading && this.friends.length === 0) {
          ListItem() {
            Column({ space: 12 }) {
              Text('还没有好友')
                .fontSize(15)
                .fontColor($r('app.color.text_main'))
              Text('通过 UID 添加好友，对方同意后会出现在这里')
                .fontSize(13)
                .fontColor($r('app.color.text_sub'))
              Text('去添加')
                .fontSize(14)
                .fontColor(Color.White)
                .height(36)
                .padding({ left: 18, right: 18 })
                .borderRadius(18)
                .backgroundColor(this.themePrimary)
                .onClick(() => router.pushUrl({ url: 'view/message/AddFriendPage' }))
            }
            .width('100%')
            .padding({ top: 80 })
          }
        }
      }
      .layoutWeight(1)
      .width('100%')
      .divider({ strokeWidth: 0.5, color: $r('app.color.divider'), startMargin: 74 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
