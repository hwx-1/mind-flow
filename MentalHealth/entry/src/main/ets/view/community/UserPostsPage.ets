import { router } from '@kit.ArkUI';
import { PostApi } from '../../api/Api';
import { PostVo } from '../../model/Models';
import { PostCard } from '../common/PostCard';
import { UserHeader } from '../common/UserHeader';
import { GlassLoading } from '../common/GlassLoading';

@Entry
@Component
struct UserPostsPage {
  @State private userId: number = 0;
  @State private list: PostVo[] = [];
  @State private loading: boolean = false;
  @State private page: number = 1;
  @State private hasMore: boolean = true;

  aboutToAppear(): void {
    const p = router.getParams() as Record<string, number>;
    this.userId = p['userId'] || 0;
    this.load(true);
  }

  async load(reset: boolean): Promise<void> {
    if (this.loading || this.userId <= 0) return;
    this.loading = true;
    if (reset) {
      this.page = 1;
      this.hasMore = true;
    }
    try {
      const r = await PostApi.userPosts(this.userId, this.page, 10);
      this.list = reset ? r.list : this.list.concat(r.list);
      this.hasMore = this.list.length < r.total;
      if (this.hasMore) this.page += 1;
    } catch (e) {
    } finally {
      this.loading = false;
    }
  }

  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(22)
          .height(22)
          .fillColor($r('app.color.text_main'))
          .onClick(() => router.back())
        Text('用户主页')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_main'))
          .margin({ left: 12 })
      }
      .width('100%')
      .height(52)
      .padding({ left: 14, right: 14 })
      .backgroundColor($r('app.color.card_bg'))
      .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })

      List({ space: 10 }) {
        ListItem() {
          UserHeader({ userId: this.userId })
        }

        if (this.loading && this.list.length === 0) {
          ListItem() {
            Column() {
              GlassLoading({ message: '加载发布' })
            }
            .width('100%')
            .padding({ top: 60 })
            .alignItems(HorizontalAlign.Center)
          }
        }

        ForEach(this.list, (post: PostVo) => {
          ListItem() {
            PostCard({ post: post, onChanged: () => this.load(true) })
          }
        }, (post: PostVo) => post.id.toString())

        if (!this.loading && this.list.length === 0) {
          ListItem() {
            Text('TA 还没有发布内容')
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
      .onReachEnd(() => {
        if (this.hasMore) this.load(false);
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
