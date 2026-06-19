import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { PostApi } from '../../api/Api';
import { PostVo, CommentVo } from '../../model/Models';
import { TimeUtil } from '../../utils/TimeUtil';

@Entry
@Component
struct PostDetailPage {
  @State post: PostVo | null = null;
  @State comments: CommentVo[] = [];
  @State input: string = '';
  @State sending: boolean = false;
  private postId: number = 0;

  aboutToAppear(): void {
    const p = router.getParams() as Record<string, number>;
    this.postId = p['id'];
    this.load();
  }

  async load() {
    try {
      this.post = await PostApi.detail(this.postId);
      this.comments = await PostApi.comments(this.postId);
    } catch (e) {}
  }

  async like() {
    if (!this.post) return;
    const r = await PostApi.like(this.post.id);
    this.post.liked = r.liked;
    this.post.likeCount += r.liked ? 1 : -1;
    this.post = { ...this.post };
  }

  async collect() {
    if (!this.post) return;
    const r = await PostApi.collect(this.post.id);
    this.post.collected = r.collected;
    this.post = { ...this.post };
    promptAction.showToast({ message: r.collected ? '已收藏' : '已取消收藏' });
  }

  async submitComment() {
    if (!this.input.trim() || !this.post) return;
    this.sending = true;
    try {
      await PostApi.comment(this.post.id, this.input.trim());
      this.input = '';
      this.comments = await PostApi.comments(this.postId);
      this.post.commentCount += 1;
      this.post = { ...this.post };
    } catch (e) {} finally { this.sending = false; }
  }

  build() {
    Column() {
      // 顶栏
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left')).width(24).height(24)
          .onClick(() => router.back())
        Text('帖子详情').fontSize(17).fontWeight(FontWeight.Medium).margin({ left: 12 })
      }.width('100%').padding(14).backgroundColor(Color.White)

      if (!this.post) {
        Column() { LoadingProgress().width(40).height(40) }
          .layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            Row({ space: 10 }) {
              Image(this.post!.avatar).width(44).height(44).borderRadius(22)
              Column() {
                Text(this.post!.nickname).fontSize(15).fontWeight(FontWeight.Medium)
                Text(TimeUtil.fromNow(this.post!.createdAt)).fontSize(12).fontColor($r('app.color.text_sub'))
              }.alignItems(HorizontalAlign.Start)
            }.width('100%')

            Text(this.post!.content).fontSize(16).width('100%').lineHeight(24)

            if (this.post!.images && this.post!.images.length > 0) {
              ForEach(this.post!.images, (url: string) => {
                Image(url).width('100%').objectFit(ImageFit.Contain).borderRadius(8)
              })
            }

            Divider().color($r('app.color.divider'))

            Text(`评论 (${this.post!.commentCount})`).fontSize(15).fontWeight(FontWeight.Medium).width('100%')

            ForEach(this.comments, (c: CommentVo) => {
              Row({ space: 10 }) {
                Image(c.avatar || $r('app.media.icon')).width(34).height(34).borderRadius(17)
                Column() {
                  Text(c.nickname || '匿名').fontSize(13).fontWeight(FontWeight.Medium)
                  Text(c.content).fontSize(14).margin({ top: 4 }).width('100%')
                  Text(TimeUtil.fromNow(c.createdAt)).fontSize(11).fontColor($r('app.color.text_sub'))
                    .margin({ top: 4 })
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              }.width('100%').padding({ top: 8, bottom: 8 })
            }, (c: CommentVo) => c.id.toString())

            if (this.comments.length === 0) {
              Text('还没有评论，来抢沙发吧').fontSize(13)
                .fontColor($r('app.color.text_sub')).margin({ top: 20 })
            }
          }.padding(14)
        }.layoutWeight(1).backgroundColor(Color.White)

        // 底部操作栏
        Row({ space: 12 }) {
          TextInput({ placeholder: '说点什么…', text: this.input })
            .layoutWeight(1).height(38).fontSize(14)
            .backgroundColor($r('app.color.bg_page'))
            .borderRadius(19).padding({ left: 14, right: 14 })
            .onChange(v => this.input = v)

          Column() {
            Image(this.post!.liked ? $r('sys.media.ohos_ic_public_thumbsup_filled') : $r('sys.media.ohos_ic_public_thumbsup'))
              .width(22).height(22)
              .fillColor(this.post!.liked ? $r('app.color.danger') : $r('app.color.text_sub'))
          }.onClick(() => this.like())

          Column() {
            Image(this.post!.collected ? $r('sys.media.ohos_ic_public_favor_filled') : $r('sys.media.ohos_ic_public_favor'))
              .width(22).height(22)
              .fillColor(this.post!.collected ? $r('app.color.primary') : $r('app.color.text_sub'))
          }.onClick(() => this.collect())

          if (this.input.length > 0) {
            Button(this.sending ? '...' : '发送').fontSize(13).height(34)
              .backgroundColor($r('app.color.primary'))
              .enabled(!this.sending)
              .onClick(() => this.submitComment())
          }
        }.width('100%').padding(10).backgroundColor(Color.White)
          .border({ width: { top: 0.5 }, color: $r('app.color.divider') })
      }
    }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
