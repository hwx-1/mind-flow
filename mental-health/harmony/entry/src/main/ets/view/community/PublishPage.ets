import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { common } from '@kit.AbilityKit';
import { PostApi } from '../../api/Api';
import { UploadUtil } from '../../utils/UploadUtil';

interface MediaItem { local: string; remote?: string; uploading: boolean; }

@Entry
@Component
struct PublishPage {
  @State content: string = '';
  @State topic: string = '';
  @State images: MediaItem[] = [];
  @State video: MediaItem | null = null;
  @State submitting: boolean = false;
  private ctx = getContext(this) as common.UIAbilityContext;

  async pickImages() {
    if (this.video) {
      promptAction.showToast({ message: '图片和视频不能同时上传' }); return;
    }
    try {
      const uris = await UploadUtil.pickImages(9 - this.images.length);
      for (const uri of uris) {
        const item: MediaItem = { local: uri, uploading: true };
        this.images.push(item);
        UploadUtil.upload(this.ctx, uri, 'image').then(url => {
          item.remote = url; item.uploading = false;
          this.images = this.images.slice();
        }).catch(() => {
          this.images = this.images.filter(x => x !== item);
          promptAction.showToast({ message: '图片上传失败' });
        });
      }
    } catch (e) {}
  }

  async pickVideo() {
    if (this.images.length > 0) {
      promptAction.showToast({ message: '图片和视频不能同时上传' }); return;
    }
    try {
      const uri = await UploadUtil.pickVideo();
      if (!uri) return;
      this.video = { local: uri, uploading: true };
      UploadUtil.upload(this.ctx, uri, 'video').then(url => {
        if (this.video) { this.video.remote = url; this.video.uploading = false; this.video = { local: this.video.local, remote: url, uploading: false }; }
      }).catch(() => {
        this.video = null;
        promptAction.showToast({ message: '视频上传失败' });
      });
    } catch (e) {}
  }

  async submit() {
    if (!this.content.trim()) { promptAction.showToast({ message: '说点什么吧' }); return; }
    if (this.images.some(x => x.uploading) || this.video?.uploading) {
      promptAction.showToast({ message: '资源还在上传' }); return;
    }
    this.submitting = true;
    try {
      await PostApi.publish({
        content: this.content.trim(),
        topic: this.topic.trim() || undefined,
        images: this.images.map(x => x.remote).filter(x => !!x),
        video: this.video?.remote
      });
      promptAction.showToast({ message: '发布成功' });
      router.back();
    } catch (e) {} finally { this.submitting = false; }
  }

  build() {
    Column() {
      Row() {
        Text('取消').fontSize(15).fontColor($r('app.color.text_sub'))
          .onClick(() => router.back())
        Blank()
        Text('发布').fontSize(15).fontWeight(FontWeight.Medium).fontColor(Color.White)
          .backgroundColor($r('app.color.primary'))
          .padding({ left: 18, right: 18, top: 6, bottom: 6 })
          .borderRadius(16)
          .onClick(() => this.submit())
      }.width('100%').padding(14).backgroundColor(Color.White)

      Scroll() {
        Column({ space: 12 }) {
          TextArea({ placeholder: '想分享些什么…', text: this.content })
            .height(160).fontSize(15)
            .backgroundColor(Color.Transparent).padding(12)
            .border({ width: 1, color: $r('app.color.divider'), radius: 8 })
            .onChange(v => this.content = v)

          TextInput({ placeholder: '# 添加话题（可选）', text: this.topic })
            .height(44).fontSize(14)
            .backgroundColor($r('app.color.primary_light'))
            .borderRadius(8).padding({ left: 12, right: 12 })
            .onChange(v => this.topic = v)

          // 已选图片
          if (this.images.length > 0) {
            Grid() {
              ForEach(this.images, (it: MediaItem, idx: number) => {
                GridItem() {
                  Stack() {
                    Image(it.local).width('100%').aspectRatio(1).borderRadius(8).objectFit(ImageFit.Cover)
                    if (it.uploading) {
                      Column() {
                        LoadingProgress().width(28).height(28).color(Color.White)
                      }.width('100%').height('100%').backgroundColor('#80000000')
                        .justifyContent(FlexAlign.Center)
                    }
                    Image($r('sys.media.ohos_ic_public_close'))
                      .width(20).height(20).fillColor(Color.White)
                      .backgroundColor('#80000000').borderRadius(10)
                      .position({ x: '85%', y: 0 })
                      .onClick(() => this.images = this.images.filter((_, i) => i !== idx))
                  }
                }
              })
            }.columnsTemplate('1fr 1fr 1fr').columnsGap(6).rowsGap(6)
              .width('100%')
              .height(Math.ceil(this.images.length / 3) * 100)
          }

          if (this.video) {
            Stack() {
              Image($r('sys.media.ohos_ic_public_videocamera'))
                .width(64).height(64).fillColor(Color.White)
              if (this.video.uploading) {
                LoadingProgress().width(28).height(28).color(Color.White)
              }
            }.width('100%').height(160).backgroundColor('#222').borderRadius(8)
          }

          Row({ space: 16 }) {
            Row({ space: 6 }) {
              Image($r('sys.media.ohos_ic_public_albums'))
                .width(22).height(22).fillColor($r('app.color.primary'))
              Text('图片').fontSize(13).fontColor($r('app.color.primary'))
            }.onClick(() => this.pickImages())
            Row({ space: 6 }) {
              Image($r('sys.media.ohos_ic_public_videocamera'))
                .width(22).height(22).fillColor($r('app.color.primary'))
              Text('视频').fontSize(13).fontColor($r('app.color.primary'))
            }.onClick(() => this.pickVideo())
          }
        }.padding(14)
      }.layoutWeight(1)
    }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
