import router from '@ohos.router';
import { PostApi } from '../../api/Api';
import { PostVo } from '../../model/Models';
import { TimeUtil } from '../../utils/TimeUtil';

@Component
export struct PostCard {
  @ObjectLink post: PostVo;

  async toggleLike(e: ClickEvent) {
    e.preventDefault?.();
    try {
      const r = await PostApi.like(this.post.id);
      this.post.liked = r.liked;
      this.post.likeCount += r.liked ? 1 : -1;
    } catch (e) {}
  }

  @Builder
  ImageGrid(images: string[]) {
    if (images.length === 1) {
      Image(images[0])
        .width('70%').aspectRatio(1.2)
        .borderRadius(8).objectFit(ImageFit.Cover)
        .margin({ top: 8 })
    } else {
      Grid() {
        ForEach(images.slice(0, 9), (url: string) => {
          GridItem() {
            Image(url).width('100%').aspectRatio(1).borderRadius(6).objectFit(ImageFit.Cover)
          }
        })
      }
      .columnsTemplate(images.length === 2 || images.length === 4 ? '1fr 1fr' : '1fr 1fr 1fr')
      .columnsGap(4).rowsGap(4).margin({ top: 8 })
      .width('100%')
      .height(images.length <= 3 ? 110 : (images.length <= 6 ? 220 : 330))
    }
  }

  build() {
    Column() {
      // 头像 + 昵称
      Row({ space: 10 }) {
        Image(this.post.avatar || $r('app.media.icon'))
          .width(40).height(40).borderRadius(20).objectFit(ImageFit.Cover)
        Column() {
          Text(this.post.nickname || '匿名用户').fontSize(14).fontWeight(FontWeight.Medium)
          Text(TimeUtil.fromNow(this.post.createdAt))
            .fontSize(11).fontColor($r('app.color.text_sub')).margin({ top: 2 })
        }.alignItems(HorizontalAlign.Start)
      }.width('100%')

      Text(this.post.content)
        .fontSize(15).fontColor($r('app.color.text_main'))
        .margin({ top: 8 }).width('100%')
        .maxLines(6).textOverflow({ overflow: TextOverflow.Ellipsis })

      if (this.post.images && this.post.images.length > 0) this.ImageGrid(this.post.images)

      if (this.post.video) {
        Stack() {
          Image(this.post.video + '?vframe/jpg/offset/1').width('100%').aspectRatio(1.6)
            .borderRadius(8).objectFit(ImageFit.Cover).backgroundColor(Color.Black)
          Image($r('sys.media.ohos_ic_public_play')).width(48).height(48).fillColor(Color.White)
        }.margin({ top: 8 })
      }

      if (this.post.topic) {
        Text(`# ${this.post.topic}`)
          .fontSize(12).fontColor($r('app.color.primary'))
          .margin({ top: 6 })
      }

      Row() {
        Row({ space: 4 }) {
          Image($r('sys.media.ohos_ic_public_comments'))
            .width(18).height(18).fillColor($r('app.color.text_sub'))
          Text(this.post.commentCount.toString()).fontSize(13).fontColor($r('app.color.text_sub'))
        }.layoutWeight(1)
        Row({ space: 4 }) {
          Image(this.post.liked ? $r('sys.media.ohos_ic_public_thumbsup_filled') : $r('sys.media.ohos_ic_public_thumbsup'))
            .width(18).height(18)
            .fillColor(this.post.liked ? $r('app.color.danger') : $r('app.color.text_sub'))
          Text(this.post.likeCount.toString())
            .fontSize(13).fontColor(this.post.liked ? $r('app.color.danger') : $r('app.color.text_sub'))
        }.onClick(e => this.toggleLike(e))
      }.width('100%').padding({ top: 10 })
    }
    .padding(14).backgroundColor(Color.White).borderRadius(12).width('100%')
    .onClick(() => router.pushUrl({ url: 'view/community/PostDetailPage', params: { id: this.post.id } }))
  }
}
