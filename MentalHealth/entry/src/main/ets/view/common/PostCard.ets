import { router } from '@kit.ArkUI';
import { PostApi } from '../../api/Api';
import { PostVo } from '../../model/Models';
import { TimeUtil } from '../../utils/TimeUtil';
import { PostImageGrid } from './PostImageGrid';

@Component
export struct PostCard {
  @StorageProp('themePrimary') themePrimary: string = '#D98E73';
  @Prop post: PostVo;
  @State likeScale: number = 1;
  onChanged: () => void = () => {};

  async toggleLike(e: ClickEvent) {
    animateTo({ duration: 220, curve: Curve.Friction }, () => {
      this.likeScale = 1.28;
    });
    setTimeout(() => {
      animateTo({ duration: 260, curve: Curve.Friction }, () => {
        this.likeScale = 1;
      });
    }, 120);
    try {
      const r = await PostApi.like(this.post.id);
      const fresh = await PostApi.detail(this.post.id);
      this.post.liked = fresh.liked;
      this.post.likeCount = fresh.likeCount;
      this.post.commentCount = fresh.commentCount;
      this.post.collected = fresh.collected;
      if (r.liked !== fresh.liked) {
        this.post.liked = r.liked;
      }
      this.onChanged();
    } catch (e) {}
  }

  build() {
    Column() {
      Row({ space: 10 }) {
        if (this.post.avatar) {
          Image(this.post.avatar)
            .width(42).height(42).borderRadius(21).objectFit(ImageFit.Cover)
            .onClick(() => router.pushUrl({ url: 'view/community/UserPostsPage', params: { userId: this.post.userId } }))
        } else {
          Text((this.post.nickname || '匿').substring(0, 1))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .width(42)
            .height(42)
            .textAlign(TextAlign.Center)
            .borderRadius(21)
            .backgroundColor(this.themePrimary)
            .onClick(() => router.pushUrl({ url: 'view/community/UserPostsPage', params: { userId: this.post.userId } }))
        }
        Column() {
          Text(this.post.nickname || '匿名用户').fontSize(13).fontWeight(FontWeight.Medium)
            .onClick(() => router.pushUrl({ url: 'view/community/UserPostsPage', params: { userId: this.post.userId } }))
          Text(TimeUtil.fromNow(this.post.createdAt))
            .fontSize(11).fontColor($r('app.color.text_sub')).margin({ top: 2 })
        }.alignItems(HorizontalAlign.Start)
      }.width('100%')

      Text(this.post.content)
        .fontSize(14).fontColor($r('app.color.text_main'))
        .margin({ top: 8 }).width('100%')
        .maxLines(6).textOverflow({ overflow: TextOverflow.Ellipsis })

      if (this.post.locationLabel) {
        Text(this.post.locationLabel)
          .fontSize(11)
          .fontColor($r('app.color.text_sub'))
          .margin({ top: 6 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      if (this.post.images && this.post.images.length > 0) {
        PostImageGrid({ images: this.post.images })
      }

      if (this.post.video) {
        Stack() {
          Text('视频')
            .fontSize(13)
            .fontColor('#CCFFFFFF')
            .width('100%')
            .height('100%')
            .textAlign(TextAlign.Center)
          Image($r('sys.media.ohos_ic_public_play')).width(48).height(48).fillColor(Color.White)
        }
        .width('100%')
        .aspectRatio(1.6)
        .borderRadius(8)
        .backgroundColor(Color.Black)
        .margin({ top: 8 })
      }

      if (this.post.topic) {
        Text(`# ${this.post.topic}`)
          .fontSize(12).fontColor(this.themePrimary)
          .margin({ top: 6 })
      }

      Row() {
        Row({ space: 4 }) {
          Image($r('sys.media.ohos_ic_public_email'))
            .width(18).height(18).fillColor($r('app.color.text_sub'))
          Text(this.post.commentCount.toString()).fontSize(13).fontColor($r('app.color.text_sub'))
        }
        .layoutWeight(1)
        .onClick(() => router.pushUrl({ url: 'view/community/PostDetailPage', params: { id: this.post.id, focusComment: 1 } }))
        Row({ space: 4 }) {
          Image($r('sys.media.ohos_ic_public_ok'))
            .width(18).height(18)
            .fillColor(this.post.liked ? $r('app.color.danger') : $r('app.color.text_sub'))
            .scale({ x: this.likeScale, y: this.likeScale })
          Text(this.post.likeCount.toString())
            .fontSize(13).fontColor(this.post.liked ? $r('app.color.danger') : $r('app.color.text_sub'))
        }.onClick(e => this.toggleLike(e))
      }.width('100%').padding({ top: 10 })
    }
    .padding(16).backgroundColor($r('app.color.card_bg')).borderRadius(18).width('100%')
    .shadow({ radius: 12, color: '#14000000', offsetX: 0, offsetY: 4 })
    .onClick(() => router.pushUrl({ url: 'view/community/PostDetailPage', params: { id: this.post.id } }))
  }
}
