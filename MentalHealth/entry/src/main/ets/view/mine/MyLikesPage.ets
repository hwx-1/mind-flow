import { router } from '@kit.ArkUI';
import { PostApi } from '../../api/Api';
import { PostVo } from '../../model/Models';
import { GlassLoading } from '../common/GlassLoading';
import { PostCard } from '../common/PostCard';

@Entry
@Component
struct MyLikesPage {
  @State private list: PostVo[] = [];
  @State private loading: boolean = false;
  @State private page: number = 1;
  @State private hasMore: boolean = true;

  aboutToAppear(): void {
    this.load(true);
  }

  onPageShow(): void {
    this.load(true);
  }

  async load(reset: boolean): Promise<void> {
    if (this.loading) {
      return;
    }
    this.loading = true;
    if (reset) {
      this.page = 1;
      this.hasMore = true;
    }

    try {
      const result = await PostApi.myLikes(this.page, 10);
      this.list = reset ? result.list : this.list.concat(result.list);
      this.hasMore = this.list.length < result.total;
      if (this.hasMore) {
        this.page += 1;
      }
    } catch (e) {
      if (reset) {
        this.list = [];
      }
    } finally {
      this.loading = false;
    }
  }

  @Builder
  NavBar() {
    Row() {
      Image($r('sys.media.ohos_ic_public_arrow_left'))
        .width(24)
        .height(24)
        .fillColor($r('app.color.text_main'))
        .onClick(() => router.back())
      Text('我的点赞')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_main'))
        .margin({ left: 12 })
      Blank()
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.card_bg'))
    .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })
  }

  build() {
    Column() {
      this.NavBar()

      if (this.loading && this.list.length === 0) {
        Column() {
          GlassLoading({ message: '正在加载点赞' })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 8 }) {
          ForEach(this.list, (post: PostVo) => {
            ListItem() {
              PostCard({ post: post, onChanged: () => this.load(true) })
            }
          }, (post: PostVo) => post.id.toString())

          if (this.list.length === 0) {
            ListItem() {
              Text('还没有点赞内容')
                .fontSize(13)
                .fontColor($r('app.color.text_sub'))
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding(48)
            }
          }

          if (this.list.length > 0) {
            ListItem() {
              Text(this.hasMore ? (this.loading ? '加载中' : '上拉加载更多') : '没有更多了')
                .fontSize(12)
                .fontColor($r('app.color.text_sub'))
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding(14)
            }
          }
        }
        .layoutWeight(1)
        .padding({ left: 8, right: 8, top: 8 })
        .onReachEnd(() => {
          if (this.hasMore) {
            this.load(false);
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
