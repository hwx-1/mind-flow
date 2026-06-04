import router from '@ohos.router';
import { PostApi } from '../../api/Api';
import { PostVo } from '../../model/Models';
import { PostCard } from '../common/PostCard';

@Component
export struct CommunityPage {
  @State tab: number = 0; // 0 推荐 1 关注 2 最新
  @State list: PostVo[] = [];
  @State loading: boolean = false;
  @State refreshing: boolean = false;
  @State page: number = 1;
  @State hasMore: boolean = true;
  private tabs: string[] = ['recommend', 'follow', 'latest'];
  private tabLabels: string[] = ['推荐', '关注', '最新'];

  aboutToAppear(): void { this.load(true); }

  async load(reset: boolean): Promise<void> {
    if (this.loading) return;
    this.loading = true;
    if (reset) { this.page = 1; this.hasMore = true; }
    try {
      const r = await PostApi.list(this.tabs[this.tab], this.page, 10);
      this.list = reset ? r.list : this.list.concat(r.list);
      this.hasMore = this.list.length < r.total;
      if (this.hasMore) this.page += 1;
    } catch (e) {} finally {
      this.loading = false;
      this.refreshing = false;
    }
  }

  switchTab(i: number): void {
    if (this.tab === i) return;
    this.tab = i;
    this.load(true);
  }

  build() {
    Column() {
      // 顶部栏
      Row() {
        ForEach(this.tabLabels, (label: string, i: number) => {
          Text(label)
            .fontSize(this.tab === i ? 18 : 15)
            .fontWeight(this.tab === i ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.tab === i ? $r('app.color.text_main') : $r('app.color.text_sub'))
            .margin({ right: 18 })
            .onClick(() => this.switchTab(i))
        })
        Blank()
        Image($r('sys.media.ohos_ic_public_add'))
          .width(28).height(28)
          .onClick(() => router.pushUrl({ url: 'view/community/PublishPage' }))
      }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 10 })
        .backgroundColor(Color.White)

      // 列表
      Refresh({ refreshing: $$this.refreshing }) {
        List({ space: 10 }) {
          ForEach(this.list, (p: PostVo) => {
            ListItem() { PostCard({ post: p }) }
          }, (p: PostVo) => p.id.toString())

          ListItem() {
            Text(this.hasMore ? (this.loading ? '加载中…' : '上拉加载更多') : '— 没有更多了 —')
              .fontSize(12).fontColor($r('app.color.text_sub'))
              .width('100%').textAlign(TextAlign.Center).padding(16)
          }
        }
        .width('100%').layoutWeight(1)
        .padding({ left: 12, right: 12, top: 10 })
        .onReachEnd(() => { if (this.hasMore) this.load(false); })
      }
      .onRefreshing(() => this.load(true))
      .layoutWeight(1)
    }.width('100%').height('100%')
  }
}
