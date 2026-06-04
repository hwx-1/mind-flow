import { promptAction, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { vibrator } from '@kit.SensorServiceKit';
import { PostApi } from '../../api/Api';
import { PublishPostReq } from '../../model/Models';
import { LocationSnapshot, LocationUtil } from '../../utils/LocationUtil';
import { LocationSelectionStore } from '../../utils/LocationSelectionStore';
import { UploadUtil } from '../../utils/UploadUtil';
import { Const } from '../../constants/Const';
import { GlassLoading } from '../common/GlassLoading';

interface MediaItem {
  local: string;
  remote?: string;
  uploading: boolean;
}

@Entry
@Component
struct PublishPage {
  @StorageProp('themePrimary') themePrimary: string = '#D98E73';
  @State private content: string = '';
  @State private topic: string = '';
  @State private images: MediaItem[] = [];
  @State private video: MediaItem | null = null;
  @State private submitting: boolean = false;
  @State private locationEnabled: boolean = false;
  @State private locationLabel: string = '不显示位置';
  @State private locationAddress: string = '';
  @State private latitude: number = 0;
  @State private longitude: number = 0;
  @State private locating: boolean = false;

  private readonly ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  aboutToAppear(): void {
    this.applyPendingLocation();
  }

  onPageShow(): void {
    this.applyPendingLocation();
  }

  private applyPendingLocation(): void {
    const selected = LocationSelectionStore.take();
    if (selected !== undefined) {
      this.applySelectedLocation(selected);
    }
  }

  private canSubmit(): boolean {
    return this.content.trim().length > 0 && !this.submitting;
  }

  private imageGridHeight(): number {
    const count = this.images.length + (this.images.length < 9 ? 1 : 0);
    return Math.ceil(Math.max(count, 1) / 3) * 92;
  }

  private removeImage(index: number): void {
    this.images = this.images.filter((_: MediaItem, i: number) => i !== index);
  }

  private remoteImages(): string[] {
    const urls: string[] = [];
    this.images.forEach((item: MediaItem) => {
      if (item.remote) {
        urls.push(item.remote);
      }
    });
    return urls;
  }

  async refreshLocation(): Promise<void> {
    if (this.locating) {
      return;
    }
    this.locating = true;
    try {
      const location = await LocationUtil.current(this.ctx);
      this.locationEnabled = true;
      this.locationLabel = location.label;
      this.locationAddress = location.address;
      this.latitude = location.latitude;
      this.longitude = location.longitude;
    } catch (e) {
      this.locationEnabled = false;
      this.locationLabel = '未获取定位';
      this.locationAddress = '';
    } finally {
      this.locating = false;
    }
  }

  private applySelectedLocation(location: LocationSnapshot | null): void {
    if (location === null) {
      this.locationEnabled = false;
      this.locationLabel = '不显示位置';
      this.locationAddress = '';
      this.latitude = 0;
      this.longitude = 0;
      return;
    }
    this.locationEnabled = true;
    this.locationLabel = location.label;
    this.locationAddress = location.address;
    this.latitude = location.latitude;
    this.longitude = location.longitude;
  }

  private openLocationPicker(): void {
    router.pushUrl({ url: 'view/community/LocationPickerPage' });
  }

  async pickImages(): Promise<void> {
    if (this.images.length >= 9) {
      promptAction.showToast({ message: '最多选择 9 张图片' });
      return;
    }

    try {
      const uris = await UploadUtil.pickImages(9 - this.images.length);
      uris.forEach((uri: string) => {
        const item: MediaItem = { local: uri, uploading: true };
        this.images.push(item);
        this.images = this.images.slice();

        UploadUtil.upload(this.ctx, uri, 'image')
          .then((url: string) => {
            item.remote = url;
            item.uploading = false;
            this.images = this.images.slice();
          })
          .catch((e: Error) => {
            console.error(`publish image upload failed: ${e.message || 'unknown error'}`);
            this.images = this.images.filter((target: MediaItem) => target !== item);
            promptAction.showToast({ message: e.message || '图片上传失败' });
          });
      });
    } catch (e) {
      const err = e as Error;
      console.error(`pick image failed: ${err.message || 'unknown error'}`);
      promptAction.showToast({ message: '选择图片失败' });
    }
  }

  async submit(): Promise<void> {
    if (!this.canSubmit()) {
      promptAction.showToast({ message: '说点什么吧' });
      return;
    }
    if (this.images.some((item: MediaItem) => item.uploading) || this.video?.uploading) {
      promptAction.showToast({ message: '资源还在上传' });
      return;
    }

    this.submitting = true;
    try {
      const req: PublishPostReq = {
        content: this.content.trim(),
        topic: this.topic.trim() || undefined,
        images: this.remoteImages(),
        locationLabel: this.locationEnabled ? this.locationLabel : undefined,
        latitude: this.locationEnabled ? this.latitude : undefined,
        longitude: this.locationEnabled ? this.longitude : undefined,
        address: this.locationEnabled ? (this.locationAddress || undefined) : undefined
      };
      await PostApi.publish(req);
      promptAction.showToast({ message: '发布成功' });
      // 通知社区页刷新（无需退出重进）
      const tick = AppStorage.get<number>(Const.FEED_REFRESH_KEY) ?? 0;
      AppStorage.setOrCreate<number>(Const.FEED_REFRESH_KEY, tick + 1);
      try {
        vibrator.startVibration({ type: 'time', duration: 40 }, { usage: 'touch' });
      } catch (e) {}
      router.back();
    } catch (e) {
    } finally {
      this.submitting = false;
    }
  }

  @Builder
  NavBar() {
    Row() {
      Text('取消')
        .fontSize(18)
        .fontColor($r('app.color.text_main'))
        .height(44)
        .padding({ right: 16 })
        .onClick(() => router.back())
      Blank()
      Text(this.submitting ? '发布中' : '发表')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.canSubmit() ? Color.White : $r('app.color.text_sub'))
        .height(44)
        .padding({ left: 24, right: 24 })
        .borderRadius(14)
        .backgroundColor(this.canSubmit() ? this.themePrimary : $r('app.color.bg_page'))
        .onClick(() => this.submit())
    }
    .width('100%')
    .height(72)
    .padding({ left: 40, right: 40, top: 10 })
    .backgroundColor($r('app.color.card_bg'))
  }

  @Builder
  ImagePicker() {
    Column() {
      Grid() {
        ForEach(this.images, (item: MediaItem, index: number) => {
          GridItem() {
            Stack() {
              Image(item.local)
                .width('100%')
                .aspectRatio(1)
                .borderRadius(0)
                .objectFit(ImageFit.Cover)
              if (item.uploading) {
                Column() {
                  LoadingProgress()
                    .width(26)
                    .height(26)
                    .color(Color.White)
                }
                .width('100%')
                .height('100%')
                .backgroundColor('#80000000')
                .justifyContent(FlexAlign.Center)
              }
              Text('×')
                .fontSize(16)
                .fontColor(Color.White)
                .width(22)
                .height(22)
                .textAlign(TextAlign.Center)
                .borderRadius(11)
                .backgroundColor('#99000000')
                .position({ x: '82%', y: 4 })
                .onClick(() => this.removeImage(index))
            }
          }
        }, (item: MediaItem, index: number) => `${index}-${item.uploading ? 'u' : 'd'}-${item.remote ?? ''}`)

        if (this.images.length < 9) {
          GridItem() {
            Column() {
              Text('+')
                .fontSize(44)
                .fontColor($r('app.color.text_sub'))
            }
            .width('100%')
            .aspectRatio(1)
            .justifyContent(FlexAlign.Center)
            .backgroundColor($r('app.color.bg_page'))
            .onClick(() => this.pickImages())
          }
        }
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(10)
      .rowsGap(10)
      .width(252)
      .height(this.imageGridHeight())
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 40, right: 40, top: 20, bottom: 20 })
    .backgroundColor($r('app.color.card_bg'))
  }

  @Builder
  LocationRow() {
    Column() {
      Divider()
        .color($r('app.color.divider'))
        .margin({ left: 40, right: 40 })
      Row({ space: 18 }) {
        Image($r('sys.media.ohos_ic_public_location'))
          .width(27)
          .height(27)
          .fillColor($r('app.color.text_main'))
        Text('所在位置')
          .fontSize(18)
          .fontColor($r('app.color.text_main'))
          .layoutWeight(1)
        Text(this.locating ? '定位中' : this.locationLabel)
          .fontSize(14)
          .fontColor(this.locationEnabled ? this.themePrimary : $r('app.color.text_sub'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: 150 })
        Image($r('sys.media.ohos_ic_public_arrow_right'))
          .width(18)
          .height(18)
          .fillColor($r('app.color.text_sub'))
      }
      .height(72)
      .padding({ left: 40, right: 40 })
      .backgroundColor($r('app.color.card_bg'))
      .onClick(() => this.openLocationPicker())
      Divider()
        .color($r('app.color.divider'))
        .margin({ left: 40, right: 40 })
    }
    .backgroundColor($r('app.color.card_bg'))
  }

  build() {
    Stack() {
      Column() {
        this.NavBar()

        Scroll() {
          Column({ space: 0 }) {
            TextArea({ placeholder: '这一刻的想法...', text: this.content })
              .height(210)
              .fontSize(18)
              .fontColor($r('app.color.text_main'))
              .placeholderColor($r('app.color.text_sub'))
              .backgroundColor($r('app.color.card_bg'))
              .padding({ left: 40, right: 40, top: 22, bottom: 12 })
              .borderRadius(0)
              .onChange((value: string) => this.content = value)

            this.ImagePicker()

            Blank()
              .height(120)

            this.LocationRow()
          }
          .width('100%')
        }
        .layoutWeight(1)
        .backgroundColor($r('app.color.bg_page'))
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.bg_page'))

      if (this.submitting) {
        Column() {
          GlassLoading({ message: '正在发布' })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#22000000')
      }
    }
    .width('100%')
    .height('100%')
  }
}
