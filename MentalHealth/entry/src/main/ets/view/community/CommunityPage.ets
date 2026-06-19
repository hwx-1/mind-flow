import { router } from '@kit.ArkUI';
import { PostApi } from '../../api/Api';
import { PostVo } from '../../model/Models';
import { PostCard } from '../common/PostCard';
import { GlassLoading } from '../common/GlassLoading';
import { Ws, WsEventHandler } from '../../api/WsClient';

@Component
export struct CommunityPage {
  @StorageProp('themePrimary') themePrimary: string = '#D98E73';
  @StorageProp('themePrimaryLight') themePrimaryLight: string = '#F3ECE1';
  @State tab: number = 0; // 0 推荐 1 关注 2 最新
  @State list: PostVo[] = [];
  @State loading: boolean = false;
  @State refreshing: boolean = false;
  @State page: number = 1;
  @State hasMore: boolean = true;
  // 发帖成功后该值自增，触发 onFeedSignal 自动刷新（无需退出重进）
  @StorageProp('feedRefreshTick') @Watch('onFeedSignal') feedTick: number = 0;
  private tabs: string[] = ['recommend', 'follow', 'latest'];
  private tabLabels: string[] = ['推荐', '关注', '最新'];
  // 收到点赞/评论通知时，刷新列表以更新点赞数、评论数
  private wsHandler: WsEventHandler = (event: string, _data: object): void => {
    if (event === 'notification') {
      this.load(true);
    }
  };

  aboutToAppear(): void {
    Ws.on(this.wsHandler);
    this.load(true);
  }

  aboutToDisappear(): void {
    Ws.off(this.wsHandler);
  }

  onFeedSignal(): void { this.load(true); }

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
      Row() {
        Row({ space: 6 }) {
          Image($r('sys.media.ohos_ic_public_add'))
            .width(18)
            .height(18)
            .fillColor(Color.White)
          Text('发布')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
        .height(34)
        .padding({ left: 12, right: 14 })
        .borderRadius(17)
        .backgroundColor(this.themePrimary)
        .onClick(() => router.pushUrl({ url: 'view/community/PublishPage' }))

        Blank()

        Text('社区')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_main'))

        Blank()

        Text('搜索')
          .fontSize(13)
          .fontColor(this.themePrimary)
          .padding({ left: 12, right: 12, top: 7, bottom: 7 })
          .borderRadius(17)
          .backgroundColor(this.themePrimaryLight)
          .onClick(() => router.pushUrl({ url: 'view/community/SearchPage' }))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 8 })
      .backgroundColor($r('app.color.card_bg'))
      .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })

      Row({ space: 10 }) {
        ForEach(this.tabLabels, (label: string, i: number) => {
          Text(label)
            .fontSize(14)
            .fontWeight(this.tab === i ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.tab === i ? Color.White : $r('app.color.text_sub'))
            .height(30)
            .padding({ left: 16, right: 16 })
            .borderRadius(15)
            .backgroundColor(this.tab === i ? this.themePrimary : $r('app.color.card_bg'))
            .onClick(() => this.switchTab(i))
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 10 })
      .backgroundColor($r('app.color.card_bg'))

      Refresh({ refreshing: $$this.refreshing }) {
        List({ space: 10 }) {
          if (this.loading && this.list.length === 0) {
            ListItem() {
              Column() {
                GlassLoading({ message: '刷新社区动态' })
              }.width('100%').padding({ top: 80 }).alignItems(HorizontalAlign.Center)
            }
          }

          ForEach(this.list, (p: PostVo) => {
            ListItem() { PostCard({ post: p, onChanged: () => this.load(true) }) }
          }, (p: PostVo) => p.id.toString())

          ListItem() {
            if (this.loading && this.list.length > 0) {
              Row() {
                LoadingProgress().width(20).height(20).color(this.themePrimary)
                Text('加载中')
                  .fontSize(12)
                  .fontColor($r('app.color.text_sub'))
                  .margin({ left: 8 })
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .padding(16)
            } else {
              Text(this.hasMore ? '上拉加载更多' : '没有更多了')
                .fontSize(12).fontColor($r('app.color.text_sub'))
                .width('100%').textAlign(TextAlign.Center).padding(16)
            }
          }
        }
        .width('100%').layoutWeight(1)
        .padding({ left: 12, right: 12, top: 10 })
        .onReachEnd(() => { if (this.hasMore) this.load(false); })
      }
      .onRefreshing(() => this.load(true))
      .layoutWeight(1)
    }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
