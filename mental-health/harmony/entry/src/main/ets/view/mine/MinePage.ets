import router from '@ohos.router';
import { Auth } from '../../store/Auth';
import { UserApi } from '../../api/Api';
import { UserVo } from '../../model/Models';

interface MenuRow { icon: Resource; label: string; route: string; }

@Component
export struct MinePage {
  @State user: UserVo | null = null;

  aboutToAppear(): void { this.refresh(); }
  onPageShow(): void { this.refresh(); }

  async refresh() {
    this.user = Auth.getUser();
    try {
      const fresh = await UserApi.profile();
      this.user = fresh;
    } catch (e) {}
  }

  private menus: MenuRow[] = [
    { icon: $r('sys.media.ohos_ic_public_edit'),    label: '资料编辑', route: 'view/mine/ProfileEditPage' },
    { icon: $r('sys.media.ohos_ic_public_albums'),  label: '我的发布', route: 'view/mine/MyPostsPage' },
    { icon: $r('sys.media.ohos_ic_public_comments'),label: '我的评论', route: 'view/mine/MyCommentsPage' },
    { icon: $r('sys.media.ohos_ic_public_settings'),label: '设置',     route: 'view/mine/SettingsPage' }
  ];

  build() {
    Scroll() {
      Column() {
        // 顶部资料卡
        Row({ space: 14 }) {
          Image(this.user?.avatar || $r('app.media.icon'))
            .width(64).height(64).borderRadius(32).objectFit(ImageFit.Cover)
          Column() {
            Text(this.user?.nickname || this.user?.username || '点击登录')
              .fontSize(18).fontWeight(FontWeight.Bold)
            Text(this.user?.bio || '这个人很懒，什么也没写')
              .fontSize(12).fontColor($r('app.color.text_sub'))
              .margin({ top: 6 }).maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        }
        .width('100%').padding({ left: 16, right: 16, top: 26, bottom: 22 })
        .backgroundColor($r('app.color.primary_light'))

        // 菜单
        Column({ space: 0 }) {
          ForEach(this.menus, (m: MenuRow) => {
            Row({ space: 12 }) {
              Image(m.icon).width(22).height(22).fillColor($r('app.color.primary'))
              Text(m.label).fontSize(15).layoutWeight(1)
              Image($r('sys.media.ohos_ic_public_arrow_right'))
                .width(16).height(16).fillColor($r('app.color.text_sub'))
            }
            .width('100%').padding(16).backgroundColor(Color.White)
            .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })
            .onClick(() => router.pushUrl({ url: m.route }))
          })
        }.margin({ top: 12 })
      }
    }.layoutWeight(1).backgroundColor($r('app.color.bg_page'))
  }
}
