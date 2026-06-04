import { router } from '@kit.ArkUI';
import { Auth } from '../../store/Auth';
import { UserApi } from '../../api/Api';
import { UserVo } from '../../model/Models';
import { ProfileStatusUtil, ProfileStatusStyle } from '../../utils/ProfileStatusUtil';

@Component
export struct MinePage {
  @StorageProp('themePrimary') themePrimary: string = '#D98E73';
  @StorageProp('themePrimaryLight') themePrimaryLight: string = '#F3ECE1';
  // 绑定到 AppStorage：编辑资料/状态保存后，此处自动刷新，无需退出重进
  @StorageLink('currentUser') user: UserVo | null = null;

  aboutToAppear(): void {
    this.refreshUser();
  }

  async refreshUser(): Promise<void> {
    try {
      const fresh = await UserApi.profile();
      await Auth.save(Auth.getToken(), Auth.getRefresh(), fresh);
    } catch (e) {
      if (this.user === null) {
        this.user = Auth.getUser();
      }
    }
  }

  private uidText(): string {
    return String(this.user?.uid ?? this.user?.id ?? '-');
  }

  private statusStyle(): ProfileStatusStyle {
    return ProfileStatusUtil.styleOf(this.user?.profileStatus);
  }

  build() {
    Column() {
      // 头部用户信息
      Stack() {
        Column() {
          Row() {
            Image(this.user?.avatar || $r('sys.media.ohos_ic_public_phone'))
              .width(70).height(70).borderRadius(35)
              .backgroundColor(this.themePrimaryLight)
            Column({ space: 4 }) {
              Text(this.user?.nickname || this.user?.username || '用户')
                .fontSize(18).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_main'))
              Text(`UID ${this.uidText()}`)
                .fontSize(12).fontColor($r('app.color.text_sub'))
              if (this.user?.profileStatus) {
                Text(this.user.profileStatus)
                  .fontSize(12)
                  .fontColor(this.statusStyle().color)
                  .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                  .borderRadius(10)
                  .backgroundColor(this.statusStyle().tint)
              }
              if (this.user?.bio) {
                Text(this.user.bio).fontSize(13).fontColor($r('app.color.text_sub'))
                  .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              }
            }.alignItems(HorizontalAlign.Start).margin({ left: 12 }).layoutWeight(1)
          }.width('100%').padding({ left: 20, right: 20, top: 30 }).onClick(() => router.pushUrl({ url: 'view/mine/ProfileEditPage' }))
        }.width('100%')
      }
      .width('100%')
      .padding({ bottom: 24 })
      .backgroundColor($r('app.color.card_bg'))
      .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })

      // 功能入口
      Column({ space: 10 }) {
        Row() {
          Image($r('sys.media.ohos_ic_public_edit')).width(20).height(20)
            .fillColor(this.themePrimary)
          Text('编辑资料').fontSize(15).margin({ left: 10 }).layoutWeight(1)
          Image($r('sys.media.ohos_ic_public_arrow_right'))
            .width(16).height(16).fillColor($r('app.color.text_sub'))
        }.width('100%').padding(16).backgroundColor($r('app.color.card_bg')).borderRadius(16).shadow({ radius: 10, color: '#0F000000', offsetX: 0, offsetY: 3 })
        .onClick(() => router.pushUrl({ url: 'view/mine/ProfileEditPage' }))

        Row() {
          Image($r('sys.media.ohos_ic_public_albums')).width(20).height(20)
            .fillColor(this.themePrimary)
          Text('我的帖子').fontSize(15).margin({ left: 10 }).layoutWeight(1)
          Image($r('sys.media.ohos_ic_public_arrow_right'))
            .width(16).height(16).fillColor($r('app.color.text_sub'))
        }.width('100%').padding(16).backgroundColor($r('app.color.card_bg')).borderRadius(16).shadow({ radius: 10, color: '#0F000000', offsetX: 0, offsetY: 3 })
        .onClick(() => router.pushUrl({ url: 'view/mine/MyPostsPage' }))

        Row() {
          Image($r('sys.media.ohos_ic_public_email')).width(20).height(20)
            .fillColor(this.themePrimary)
          Text('我的评论').fontSize(15).margin({ left: 10 }).layoutWeight(1)
          Image($r('sys.media.ohos_ic_public_arrow_right'))
            .width(16).height(16).fillColor($r('app.color.text_sub'))
        }.width('100%').padding(16).backgroundColor($r('app.color.card_bg')).borderRadius(16).shadow({ radius: 10, color: '#0F000000', offsetX: 0, offsetY: 3 })
        .onClick(() => router.pushUrl({ url: 'view/mine/MyCommentsPage' }))

        Row() {
          Image($r('sys.media.ohos_ic_public_ok')).width(20).height(20)
            .fillColor(this.themePrimary)
          Text('我的点赞').fontSize(15).margin({ left: 10 }).layoutWeight(1)
          Image($r('sys.media.ohos_ic_public_arrow_right'))
            .width(16).height(16).fillColor($r('app.color.text_sub'))
        }.width('100%').padding(16).backgroundColor($r('app.color.card_bg')).borderRadius(16).shadow({ radius: 10, color: '#0F000000', offsetX: 0, offsetY: 3 })
        .onClick(() => router.pushUrl({ url: 'view/mine/MyLikesPage' }))

        Row() {
          Image($r('sys.media.ohos_ic_public_clock')).width(20).height(20)
            .fillColor(this.themePrimary)
          Text('设置').fontSize(15).margin({ left: 10 }).layoutWeight(1)
          Image($r('sys.media.ohos_ic_public_arrow_right'))
            .width(16).height(16).fillColor($r('app.color.text_sub'))
        }.width('100%').padding(16).backgroundColor($r('app.color.card_bg')).borderRadius(16).shadow({ radius: 10, color: '#0F000000', offsetX: 0, offsetY: 3 })
        .onClick(() => router.pushUrl({ url: 'view/mine/SettingsPage' }))
      }.padding(12)
    }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
