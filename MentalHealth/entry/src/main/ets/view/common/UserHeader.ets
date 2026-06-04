import { promptAction, router } from '@kit.ArkUI';
import { UserApi } from '../../api/Api';
import { UserVo } from '../../model/Models';
import { Auth } from '../../store/Auth';
import { ProfileStatusUtil, ProfileStatusStyle } from '../../utils/ProfileStatusUtil';

@Component
export struct UserHeader {
  @StorageProp('themePrimary') themePrimary: string = '#D98E73';
  @StorageProp('themePrimaryLight') themePrimaryLight: string = '#F3ECE1';
  @Prop userId: number;
  @State private user: UserVo | null = null;
  @State private loading: boolean = false;

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    if (this.loading || !this.userId) return;
    this.loading = true;
    try {
      this.user = await UserApi.profileOf(this.userId);
    } catch (e) {
    } finally {
      this.loading = false;
    }
  }

  private isMine(): boolean {
    return Auth.getUser()?.id === this.userId;
  }

  private uidText(): string {
    return String(this.user?.uid ?? this.user?.id ?? '-');
  }

  private statusStyle(): ProfileStatusStyle {
    return ProfileStatusUtil.styleOf(this.user?.profileStatus);
  }

  async toggleFollow(): Promise<void> {
    if (!this.user || this.isMine()) return;
    try {
      const r = await UserApi.follow(this.user.id);
      this.user.followed = r.followed;
      this.user.followerCount = Math.max(0, (this.user.followerCount || 0) + (r.followed ? 1 : -1));
      const current = this.user;
      this.user = null;
      this.user = current;
    } catch (e) {}
  }

  async requestFriend(): Promise<void> {
    if (!this.user || this.isMine()) return;
    try {
      await UserApi.requestFriend(this.user.id, '请求添加你为好友');
      promptAction.showToast({ message: '好友申请已发送' });
      await this.load();
    } catch (e) {}
  }

  build() {
    if (this.user) {
      Column({ space: 12 }) {
        Row({ space: 12 }) {
          if (this.user.avatar) {
            Image(this.user.avatar)
              .width(58)
              .height(58)
              .borderRadius(29)
              .objectFit(ImageFit.Cover)
          } else {
            Text((this.user.nickname || this.user.username || '用').substring(0, 1))
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .width(58)
              .height(58)
              .textAlign(TextAlign.Center)
              .borderRadius(29)
              .backgroundColor(this.themePrimary)
          }

          Column({ space: 5 }) {
            Row({ space: 8 }) {
              Text(this.user.nickname || this.user.username || '用户')
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_main'))
              if (this.user.profileStatus) {
                Text(this.user.profileStatus)
                  .fontSize(11)
                  .fontColor(this.statusStyle().color)
                  .padding({ left: 7, right: 7, top: 2, bottom: 2 })
                  .borderRadius(9)
                  .backgroundColor(this.statusStyle().tint)
              }
            }
            Text(`UID ${this.uidText()}  关注 ${this.user.followingCount || 0}  粉丝 ${this.user.followerCount || 0}`)
              .fontSize(12)
              .fontColor($r('app.color.text_sub'))
            if (this.user.bio) {
              Text(this.user.bio)
                .fontSize(12)
                .fontColor($r('app.color.text_sub'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')

        if (!this.isMine()) {
          Row({ space: 8 }) {
            Text(this.user.followed ? '已关注' : '关注')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.user.followed ? $r('app.color.text_sub') : Color.White)
              .height(34)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .borderRadius(17)
              .backgroundColor(this.user.followed ? $r('app.color.bg_page') : this.themePrimary)
              .onClick(() => this.toggleFollow())
            Text(this.user.friend ? '发消息' : (this.user.friendRequestStatus === 0 ? '等待同意' : '加好友'))
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.themePrimary)
              .height(34)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .borderRadius(17)
              .backgroundColor(this.themePrimaryLight)
              .onClick(() => {
                if (this.user?.friend) {
                  router.pushUrl({
                    url: 'view/message/ChatRoomPage',
                    params: { userId: this.user.id, nickname: this.user.nickname, avatar: this.user.avatar }
                  });
                } else if (this.user?.friendRequestStatus !== 0) {
                  this.requestFriend();
                }
              })
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding(14)
      .backgroundColor($r('app.color.card_bg'))
    }
  }
}
