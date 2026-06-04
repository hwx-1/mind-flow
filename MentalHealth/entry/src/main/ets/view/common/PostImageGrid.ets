import { router } from '@kit.ArkUI';

interface ImagePreviewParams {
  images: string[];
  index: number;
}

/**
 * 帖子图片缩略图网格（微博式）：
 *  - 单图：等比缩小为固定缩略图；
 *  - 多图：方格平铺（2/4 图两列，其余三列），Cover 裁切缩略；
 *  - 点击任意图进入全屏查看器（可放大、左右切换）。
 * 复用于社区流卡片与帖子详情页，保证体验一致。
 */
@Component
export struct PostImageGrid {
  @Prop images: string[];

  private open(index: number): void {
    router.pushUrl({
      url: 'view/common/ImagePreviewPage',
      params: { images: this.images, index: index } as ImagePreviewParams
    });
  }

  private isTwoCol(): boolean {
    return this.images.length === 2 || this.images.length === 4;
  }

  private gridHeight(): number {
    const cols: number = this.isTwoCol() ? 2 : 3;
    const count: number = Math.min(this.images.length, 9);
    const rows: number = Math.ceil(count / cols);
    // 单元约 78vp + 4vp 间距
    return rows * 78 + (rows - 1) * 4;
  }

  build() {
    Column() {
      if (this.images.length === 1) {
        Image(this.images[0])
          .width(180)
          .height(180)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
          .onClick((): void => this.open(0))
      } else if (this.images.length > 1) {
        Grid() {
          ForEach(this.images.slice(0, 9), (url: string, index: number): void => {
            GridItem() {
              Image(url)
                .width('100%')
                .aspectRatio(1)
                .objectFit(ImageFit.Cover)
                .borderRadius(6)
                .onClick((): void => this.open(index))
            }
          }, (url: string, index: number): string => `${index}-${url}`)
        }
        .columnsTemplate(this.isTwoCol() ? '1fr 1fr' : '1fr 1fr 1fr')
        .columnsGap(4)
        .rowsGap(4)
        .width(this.isTwoCol() ? 160 : 240)
        .height(this.gridHeight())
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 8 })
  }
}
