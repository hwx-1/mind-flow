import { router } from '@kit.ArkUI';

interface PreviewParams {
  images: string[];
  index: number;
}

/**
 * 全屏图片查看器（微博式）：
 *  - Swiper 左右滑动切换多图；
 *  - 双指捏合 / 双击 放大缩小，放大后可拖动；
 *  - 单击关闭。
 * 严格使用 ArkUI 官方组件与手势：Swiper / Image / PinchGesture / PanGesture / TapGesture。
 */
@Entry
@Component
struct ImagePreviewPage {
  @State images: string[] = [];
  @State current: number = 0;
  // 当前图片是否处于放大态：放大时禁用 Swiper 翻页，避免与拖动冲突
  @State zoomed: boolean = false;

  aboutToAppear(): void {
    const p = router.getParams() as PreviewParams;
    if (p !== undefined && p.images !== undefined && p.images.length > 0) {
      this.images = p.images;
      this.current = (p.index >= 0 && p.index < p.images.length) ? p.index : 0;
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Swiper() {
        ForEach(this.images, (url: string): void => {
          ZoomableImage({
            url: url,
            onZoomChange: (z: boolean): void => {
              this.zoomed = z;
            }
          })
        }, (url: string, index: number): string => `${index}-${url}`)
      }
      .index(this.current)
      .loop(false)
      .indicator(false)
      .disableSwipe(this.zoomed)
      .width('100%')
      .height('100%')
      .onChange((i: number): void => {
        this.current = i;
        this.zoomed = false;
      })

      if (this.images.length > 1) {
        Text(`${this.current + 1} / ${this.images.length}`)
          .fontSize(15)
          .fontColor(Color.White)
          .backgroundColor('#66000000')
          .borderRadius(14)
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .margin({ top: 50, left: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }
}

/**
 * 可缩放图片：自身维护缩放比例与位移，放大状态通过回调上报，
 * 供父级 Swiper 决定是否禁用翻页。
 */
@Component
struct ZoomableImage {
  @Prop url: string;
  onZoomChange: (zoomed: boolean) => void = (): void => {};

  @State scaleValue: number = 1;
  @State offsetX: number = 0;
  @State offsetY: number = 0;

  // 手势开始时的基准值
  private baseScale: number = 1;
  private baseX: number = 0;
  private baseY: number = 0;

  private static readonly MIN_SCALE: number = 1;
  private static readonly MAX_SCALE: number = 4;

  private clampScale(s: number): number {
    if (s < ZoomableImage.MIN_SCALE) {
      return ZoomableImage.MIN_SCALE;
    }
    return s > ZoomableImage.MAX_SCALE ? ZoomableImage.MAX_SCALE : s;
  }

  private syncZoom(): void {
    this.onZoomChange(this.scaleValue > 1.001);
  }

  private resetTransform(): void {
    this.scaleValue = 1;
    this.offsetX = 0;
    this.offsetY = 0;
    this.baseScale = 1;
    this.baseX = 0;
    this.baseY = 0;
    this.syncZoom();
  }

  build() {
    Stack() {
      Image(this.url)
        .objectFit(ImageFit.Contain)
        .width('100%')
        .height('100%')
        .scale({ x: this.scaleValue, y: this.scaleValue })
        .translate({ x: this.offsetX, y: this.offsetY })
    }
    .width('100%')
    .height('100%')
    // 缩放：双指捏合
    .gesture(
      PinchGesture({ fingers: 2 })
        .onActionStart((): void => {
          this.baseScale = this.scaleValue;
        })
        .onActionUpdate((event: GestureEvent): void => {
          this.scaleValue = this.clampScale(this.baseScale * event.scale);
        })
        .onActionEnd((): void => {
          if (this.scaleValue <= 1) {
            this.resetTransform();
          } else {
            this.syncZoom();
          }
        })
    )
    // 拖动：与 Swiper 并行，仅在放大态生效
    .parallelGesture(
      PanGesture()
        .onActionStart((): void => {
          this.baseX = this.offsetX;
          this.baseY = this.offsetY;
        })
        .onActionUpdate((event: GestureEvent): void => {
          if (this.scaleValue > 1) {
            this.offsetX = this.baseX + event.offsetX;
            this.offsetY = this.baseY + event.offsetY;
          }
        })
    )
    // 双击放大 / 还原，与单击互斥（双击优先）
    .gesture(
      GestureGroup(GestureMode.Exclusive,
        TapGesture({ count: 2 })
          .onAction((): void => {
            if (this.scaleValue > 1) {
              this.resetTransform();
            } else {
              this.scaleValue = 2;
              this.syncZoom();
            }
          }),
        TapGesture({ count: 1 })
          .onAction((): void => {
            router.back();
          })
      )
    )
  }
}
