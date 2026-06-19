import { promptAction, router } from '@kit.ArkUI';
import { PostApi } from '../../api/Api';
import { PostVo, CommentVo } from '../../model/Models';
import { TimeUtil } from '../../utils/TimeUtil';
import { EmojiBar } from '../common/EmojiBar';
import { GlassLoading } from '../common/GlassLoading';
import { PostImageGrid } from '../common/PostImageGrid';

@Entry
@Component
struct PostDetailPage {
  @StorageProp('themePrimary') themePrimary: string = '#D98E73';
  @State post: PostVo | null = null;
  @State comments: CommentVo[] = [];
  @State input: string = '';
  @State sending: boolean = false;
  @State likeScale: number = 1;
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
    animateTo({ duration: 220, curve: Curve.Friction }, () => this.likeScale = 1.24);
    setTimeout(() => animateTo({ duration: 260, curve: Curve.Friction }, () => this.likeScale = 1), 120);
    const r = await PostApi.like(this.post.id);
    await this.load();
    if (this.post && this.post.liked !== r.liked) {
      this.post.liked = r.liked;
    }
  }

  async collect() {
    if (!this.post) return;
    const r = await PostApi.collect(this.post.id);
    await this.load();
    if (this.post && this.post.collected !== r.collected) {
      this.post.collected = r.collected;
    }
    promptAction.showToast({ message: r.collected ? '已收藏' : '已取消收藏' });
  }

  async submitComment() {
    if (!this.input.trim() || !this.post) return;
    this.sending = true;
    try {
      await PostApi.comment(this.post.id, this.input.trim());
      this.input = '';
      await this.load();
    } catch (e) {} finally { this.sending = false; }
  }

  build() {
    Column() {
      // 顶栏
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left')).width(24).height(24)
          .fillColor($r('app.color.text_main'))
          .onClick(() => router.back())
        Text('帖子详情').fontSize(17).fontWeight(FontWeight.Medium).margin({ left: 12 })
      }.width('100%').padding(14).backgroundColor($r('app.color.card_bg'))
      .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })

      if (!this.post) {
        Column() { GlassLoading({ message: '加载帖子' }) }
        .layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ListItem() {
            Row({ space: 10 }) {
              if (this.post!.avatar) {
                Image(this.post!.avatar).width(44).height(44).borderRadius(22).objectFit(ImageFit.Cover)
              } else {
                Text((this.post!.nickname || '匿').substring(0, 1))
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                  .width(44)
                  .height(44)
                  .textAlign(TextAlign.Center)
                  .borderRadius(22)
                  .backgroundColor(this.themePrimary)
              }
              Column() {
                Text(this.post!.nickname).fontSize(15).fontWeight(FontWeight.Medium)
                Text(TimeUtil.fromNow(this.post!.createdAt)).fontSize(12).fontColor($r('app.color.text_sub'))
              }.alignItems(HorizontalAlign.Start)
            }.width('100%')
          }

          ListItem() {
            Text(this.post!.content).fontSize(16).width('100%').lineHeight(24)
          }

          if (this.post!.locationLabel) {
            ListItem() {
              Text(this.post!.locationLabel)
                .fontSize(12)
                .fontColor($r('app.color.text_sub'))
                .width('100%')
            }
          }

          if (this.post!.images && this.post!.images.length > 0) {
            ListItem() {
              Row() {
                PostImageGrid({ images: this.post!.images })
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)
            }
          }

          ListItem() {
            Divider().color($r('app.color.divider'))
          }

          ListItem() {
            Text(`评论 (${this.post!.commentCount})`).fontSize(15).fontWeight(FontWeight.Medium).width('100%')
          }

          ForEach(this.comments, (c: CommentVo) => {
            ListItem() {
              Row({ space: 10 }) {
                Image(c.avatar || $r('app.media.icon')).width(34).height(34).borderRadius(17)
                Column() {
                  Text(c.nickname || '匿名').fontSize(13).fontWeight(FontWeight.Medium)
                  Text(c.content).fontSize(14).margin({ top: 4 }).width('100%')
                  Text(TimeUtil.fromNow(c.createdAt)).fontSize(11).fontColor($r('app.color.text_sub'))
                    .margin({ top: 4 })
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              }.width('100%').padding({ top: 8, bottom: 8 })
            }
          }, (c: CommentVo) => c.id.toString())

          if (this.comments.length === 0) {
            ListItem() {
              Text('还没有评论，来抢沙发吧').fontSize(13)
                .fontColor($r('app.color.text_sub'))
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding({ top: 20, bottom: 20 })
            }
          }
        }
        .layoutWeight(1)
        .padding({ left: 14, right: 14, top: 0, bottom: 14 })
        .backgroundColor($r('app.color.card_bg'))

        Column() {
          EmojiBar({ onPick: (value: string) => this.input += value })
          Row({ space: 12 }) {
            TextInput({ placeholder: '说点什么…', text: this.input })
              .layoutWeight(1).height(38).fontSize(14)
              .backgroundColor($r('app.color.bg_page'))
              .borderRadius(19).padding({ left: 14, right: 14 })
              .onChange(v => this.input = v)

            Column() {
              Image($r('sys.media.ohos_ic_public_ok'))
                .width(22).height(22)
                .fillColor(this.post!.liked ? $r('app.color.danger') : $r('app.color.text_sub'))
                .scale({ x: this.likeScale, y: this.likeScale })
            }.onClick(() => this.like())

            Column() {
              Image($r('sys.media.ohos_ic_public_add'))
                .width(22).height(22)
                .fillColor(this.post!.collected ? this.themePrimary : $r('app.color.text_sub'))
            }.onClick(() => this.collect())

            if (this.input.length > 0) {
              Button(this.sending ? '...' : '发送').fontSize(13).height(34)
                .backgroundColor(this.themePrimary)
                .enabled(!this.sending)
                .onClick(() => this.submitComment())
            }
          }.width('100%').padding({ left: 10, right: 10, bottom: 10 })
        }
        .width('100%')
        .backgroundColor($r('app.color.card_bg'))
        .border({ width: { top: 0.5 }, color: $r('app.color.divider') })
      }
    }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
