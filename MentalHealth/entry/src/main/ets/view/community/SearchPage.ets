import { router } from '@kit.ArkUI';
import { PostApi, UserApi } from '../../api/Api';
import { PostVo, UserVo } from '../../model/Models';
import { PostCard } from '../common/PostCard';

@Entry
@Component
struct SearchPage {
  @StorageProp('themePrimary') themePrimary: string = '#D98E73';
  @State private keyword: string = '';
  @State private users: UserVo[] = [];
  @State private posts: PostVo[] = [];
  @State private searching: boolean = false;

  async search(): Promise<void> {
    const q = this.keyword.trim();
    if (!q || this.searching) return;
    this.searching = true;
    try {
      this.users = await UserApi.search(q);
      const r = await PostApi.search(q, 1, 20);
      this.posts = r.list;
    } catch (e) {
    } finally {
      this.searching = false;
    }
  }

  @Builder
  UserRow(user: UserVo) {
    Row({ space: 10 }) {
      Image(user.avatar || $r('app.media.icon'))
        .width(42)
        .height(42)
        .borderRadius(21)
        .objectFit(ImageFit.Cover)
      Column({ space: 4 }) {
        Text(user.nickname || user.username || '用户')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_main'))
        Text(`UID ${String(user.uid ?? user.id)}`)
          .fontSize(11)
          .fontColor($r('app.color.text_sub'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text(user.followed ? '已关注' : '关注')
        .fontSize(12)
        .fontColor(user.followed ? $r('app.color.text_sub') : Color.White)
        .height(30)
        .padding({ left: 14, right: 14 })
        .borderRadius(15)
        .backgroundColor(user.followed ? $r('app.color.bg_page') : this.themePrimary)
        .onClick(async () => {
          const r = await UserApi.follow(user.id);
          user.followed = r.followed;
          this.users = this.users.slice();
        })
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.card_bg'))
    .onClick(() => router.pushUrl({ url: 'view/community/UserPostsPage', params: { userId: user.id } }))
  }

  build() {
    Column() {
      Row({ space: 10 }) {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(22)
          .height(22)
          .onClick(() => router.back())
        TextInput({ placeholder: '搜索用户、帖子内容或 UID', text: this.keyword })
          .layoutWeight(1)
          .height(38)
          .fontSize(14)
          .backgroundColor($r('app.color.bg_page'))
          .borderRadius(19)
          .padding({ left: 14, right: 14 })
          .onChange((value: string) => this.keyword = value)
          .onSubmit(() => this.search())
        Text('搜索')
          .fontSize(13)
          .fontColor(Color.White)
          .height(34)
          .padding({ left: 16, right: 16 })
          .borderRadius(17)
          .backgroundColor(this.themePrimary)
          .onClick(() => this.search())
      }
      .width('100%')
      .padding(12)
      .backgroundColor($r('app.color.card_bg'))

      List({ space: 8 }) {
        if (this.users.length > 0) {
          ListItem() {
            Text('用户')
              .fontSize(12)
              .fontColor($r('app.color.text_sub'))
              .padding({ left: 4, top: 8, bottom: 2 })
          }
        }
        ForEach(this.users, (user: UserVo) => {
          ListItem() {
            this.UserRow(user)
          }
        }, (user: UserVo) => user.id.toString())

        if (this.posts.length > 0) {
          ListItem() {
            Text('帖子')
              .fontSize(12)
              .fontColor($r('app.color.text_sub'))
              .padding({ left: 4, top: 8, bottom: 2 })
          }
        }
        ForEach(this.posts, (post: PostVo) => {
          ListItem() {
            PostCard({ post: post, onChanged: () => this.search() })
          }
        }, (post: PostVo) => post.id.toString())

        if (!this.searching && this.keyword.trim().length > 0 && this.users.length === 0 && this.posts.length === 0) {
          ListItem() {
            Text('没有找到相关内容')
              .fontSize(13)
              .fontColor($r('app.color.text_sub'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(48)
          }
        }
      }
      .layoutWeight(1)
      .padding({ left: 10, right: 10, top: 10 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
