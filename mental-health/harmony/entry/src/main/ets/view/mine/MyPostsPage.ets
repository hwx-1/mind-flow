import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { PostApi } from '../../api/Api';
import { PostVo } from '../../model/Models';
import { TimeUtil } from '../../utils/TimeUtil';

@Entry
@Component
struct MyPostsPage {
  @State list: PostVo[] = [];
  @State page: number = 1;
  @State hasMore: boolean = true;

  aboutToAppear(): void { this.load(true); }

  async load(reset: boolean) {
    if (reset) { this.page = 1; this.hasMore = true; }
    try {
      const r = await PostApi.my(this.page, 10);
      this.list = reset ? r.list : this.list.concat(r.list);
      this.hasMore = this.list.length < r.total;
      if (this.hasMore) this.page += 1;
    } catch (e) {}
  }

  async del(id: number) {
    AlertDialog.show({
      message: '确认删除此帖？',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '删除', fontColor: $r('app.color.danger'),
        action: async () => {
          try { await PostApi.del(id); this.load(true); promptAction.showToast({ message: '已删除' }); } catch (e) {}
        }
      }
    });
  }

  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left')).width(24).height(24)
          .onClick(() => router.back())
        Text('我的发布').fontSize(17).fontWeight(FontWeight.Medium).margin({ left: 12 })
      }.width('100%').padding(14).backgroundColor(Color.White)

      List({ space: 10 }) {
        ForEach(this.list, (p: PostVo) => {
          ListItem() {
            Column({ space: 6 }) {
              Text(p.content).fontSize(14).maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
              if (p.images && p.images.length > 0) {
                Row({ space: 6 }) {
                  ForEach(p.images.slice(0, 3), (u: string) => {
                    Image(u).width(60).height(60).borderRadius(6).objectFit(ImageFit.Cover)
                  })
                }
              }
              Row() {
                Text(TimeUtil.fromNow(p.createdAt)).fontSize(11).fontColor($r('app.color.text_sub'))
                Blank()
                Text(`💬 ${p.commentCount}  ❤️ ${p.likeCount}`)
                  .fontSize(11).fontColor($r('app.color.text_sub'))
              }.width('100%')
            }
            .padding(14).backgroundColor(Color.White).borderRadius(10).width('100%')
            .onClick(() => router.pushUrl({ url: 'view/community/PostDetailPage', params: { id: p.id } }))
          }
          .swipeAction({
            end: {
              builder: () => {
                Text('删除').fontColor(Color.White).fontSize(14)
                  .width(72).height('100%').textAlign(TextAlign.Center)
                  .backgroundColor($r('app.color.danger'))
                  .onClick(() => this.del(p.id))
              }
            }
          })
        }, (p: PostVo) => p.id.toString())

        if (this.list.length === 0) {
          ListItem() {
            Text('你还没有发布过任何内容').fontSize(13)
              .fontColor($r('app.color.text_sub')).width('100%')
              .textAlign(TextAlign.Center).padding(48)
          }
        }
      }
      .layoutWeight(1).padding(12)
      .onReachEnd(() => { if (this.hasMore) this.load(false); })
    }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
