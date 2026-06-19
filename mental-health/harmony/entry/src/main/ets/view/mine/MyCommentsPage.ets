import router from '@ohos.router';
import { PostApi } from '../../api/Api';
import { TimeUtil } from '../../utils/TimeUtil';

interface MyCommentRow {
  id: number;
  content: string;
  createdAt: string;
  postId?: number;
  postContent?: string;
}

@Entry
@Component
struct MyCommentsPage {
  @State list: MyCommentRow[] = [];

  aboutToAppear(): void { this.load(); }

  async load() {
    try {
      const r = await PostApi.myComments();
      this.list = r as MyCommentRow[];
    } catch (e) {}
  }

  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left')).width(24).height(24)
          .onClick(() => router.back())
        Text('我的评论').fontSize(17).fontWeight(FontWeight.Medium).margin({ left: 12 })
      }.width('100%').padding(14).backgroundColor(Color.White)

      List({ space: 10 }) {
        ForEach(this.list, (c: MyCommentRow) => {
          ListItem() {
            Column({ space: 6 }) {
              Text(c.content).fontSize(14).width('100%')
              if (c.postContent) {
                Row({ space: 4 }) {
                  Image($r('sys.media.ohos_ic_public_arrow_right'))
                    .width(12).height(12).fillColor($r('app.color.text_sub'))
                  Text(c.postContent).fontSize(12).fontColor($r('app.color.text_sub'))
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                }
                .padding(8).backgroundColor($r('app.color.bg_page')).borderRadius(6).width('100%')
              }
              Text(TimeUtil.fromNow(c.createdAt)).fontSize(11)
                .fontColor($r('app.color.text_sub')).width('100%')
            }
            .padding(14).backgroundColor(Color.White).borderRadius(10).width('100%')
            .onClick(() => {
              if (c.postId) router.pushUrl({ url: 'view/community/PostDetailPage', params: { id: c.postId } });
            })
          }
        }, (c: MyCommentRow) => c.id.toString())

        if (this.list.length === 0) {
          ListItem() {
            Text('你还没有评论过').fontSize(13)
              .fontColor($r('app.color.text_sub')).width('100%')
              .textAlign(TextAlign.Center).padding(48)
          }
        }
      }.layoutWeight(1).padding(12)
    }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
