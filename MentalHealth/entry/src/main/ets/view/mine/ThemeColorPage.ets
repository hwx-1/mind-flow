import { promptAction, router } from '@kit.ArkUI';
import { AppTheme, Rgb } from '../../store/AppTheme';

/**
 * 主题颜色设置页：RGB 滑块 + 实时预览 + 预设色 + 恢复默认。
 * 任意修改都会即时写入 AppTheme（全局 @StorageProp 订阅），所有页面实时变色。
 */
@Entry
@Component
struct ThemeColorPage {
  // 订阅全局主题色，预览随之实时刷新
  @StorageProp('themePrimary') primary: string = '#D98E73';
  @StorageProp('themePrimaryLight') primaryLight: string = '#F3ECE1';

  @State r: number = 217;
  @State g: number = 142;
  @State b: number = 115;

  // 预设主色
  private presets: string[] = [
    '#D98E73', '#7D9268', '#4C8C7D', '#5B8FB9',
    '#9C6FB0', '#C0573F', '#E0A030', '#3A3A3A'
  ];

  aboutToAppear(): void {
    const rgb: Rgb = AppTheme.currentRgb();
    this.r = rgb.r;
    this.g = rgb.g;
    this.b = rgb.b;
  }

  /** 把当前 RGB 写入全局主题（持久化 + 全局刷新） */
  private apply(): void {
    AppTheme.setRgb(this.r, this.g, this.b);
  }

  private currentHex(): string {
    return AppTheme.rgbToHex(this.r, this.g, this.b);
  }

  private applyPreset(hex: string): void {
    const rgb: Rgb = AppTheme.hexToRgb(hex);
    this.r = rgb.r;
    this.g = rgb.g;
    this.b = rgb.b;
    this.apply();
  }

  private resetDefault(): void {
    AppTheme.reset();
    const rgb: Rgb = AppTheme.currentRgb();
    this.r = rgb.r;
    this.g = rgb.g;
    this.b = rgb.b;
    promptAction.showToast({ message: '已恢复默认主题色' });
  }

  build() {
    Column() {
      // 顶部栏
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24).height(24).fillColor($r('app.color.text_main'))
          .onClick((): void => router.back())
        Text('主题颜色')
          .fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_main')).margin({ left: 12 })
      }
      .width('100%').padding({ left: 16, right: 16, top: 20, bottom: 16 })
      .backgroundColor($r('app.color.card_bg'))
      .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })

      Scroll() {
        Column({ space: 16 }) {
          // 预览区
          Column({ space: 14 }) {
            Row() {
              Text('实时预览').fontSize(15).fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_main')).layoutWeight(1)
              Text(this.currentHex())
                .fontSize(14).fontColor($r('app.color.text_sub'))
                .fontFamily('monospace')
            }.width('100%')

            // 主色大色块
            Column()
              .width('100%').height(72).borderRadius(16)
              .backgroundColor(this.primary)

            // 实际控件示例：按钮 + 标签
            Row({ space: 12 }) {
              Button('主按钮')
                .fontSize(14).fontColor(Color.White)
                .backgroundColor(this.primary)
                .height(40).layoutWeight(1)
              Text('标签')
                .fontSize(13).fontColor(this.primary)
                .backgroundColor(this.primaryLight)
                .padding({ left: 16, right: 16, top: 9, bottom: 9 })
                .borderRadius(20)
            }.width('100%')
          }
          .width('100%').padding(16)
          .backgroundColor($r('app.color.card_bg')).borderRadius(14)

          // RGB 调节
          Column({ space: 18 }) {
            Text('自定义 RGB').fontSize(15).fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_main')).width('100%')

            // R
            Row({ space: 12 }) {
              Text('R').fontSize(14).fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_main')).width(20)
              Slider({ value: this.r, min: 0, max: 255, step: 1 })
                .layoutWeight(1).blockColor(Color.White)
                .selectedColor(Color.Red).trackColor($r('app.color.divider'))
                .onChange((v: number): void => {
                  this.r = Math.round(v);
                  this.apply();
                })
              Text(this.r.toString()).fontSize(14)
                .fontColor($r('app.color.text_sub')).width(40).textAlign(TextAlign.End)
            }.width('100%')

            // G
            Row({ space: 12 }) {
              Text('G').fontSize(14).fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_main')).width(20)
              Slider({ value: this.g, min: 0, max: 255, step: 1 })
                .layoutWeight(1).blockColor(Color.White)
                .selectedColor(Color.Green).trackColor($r('app.color.divider'))
                .onChange((v: number): void => {
                  this.g = Math.round(v);
                  this.apply();
                })
              Text(this.g.toString()).fontSize(14)
                .fontColor($r('app.color.text_sub')).width(40).textAlign(TextAlign.End)
            }.width('100%')

            // B
            Row({ space: 12 }) {
              Text('B').fontSize(14).fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_main')).width(20)
              Slider({ value: this.b, min: 0, max: 255, step: 1 })
                .layoutWeight(1).blockColor(Color.White)
                .selectedColor(Color.Blue).trackColor($r('app.color.divider'))
                .onChange((v: number): void => {
                  this.b = Math.round(v);
                  this.apply();
                })
              Text(this.b.toString()).fontSize(14)
                .fontColor($r('app.color.text_sub')).width(40).textAlign(TextAlign.End)
            }.width('100%')
          }
          .width('100%').padding(16)
          .backgroundColor($r('app.color.card_bg')).borderRadius(14)

          // 预设色
          Column({ space: 14 }) {
            Text('预设主题色').fontSize(15).fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_main')).width('100%')
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
              ForEach(this.presets, (item: string): void => {
                Stack() {
                  Column()
                    .width(44).height(44).borderRadius(22)
                    .backgroundColor(item)
                    .border({
                      width: this.currentHex().toUpperCase() === item.toUpperCase() ? 3 : 0,
                      color: $r('app.color.text_main')
                    })
                }
                .margin({ bottom: 12 })
                .onClick((): void => this.applyPreset(item))
              }, (item: string): string => item)
            }.width('100%')
          }
          .width('100%').padding(16)
          .backgroundColor($r('app.color.card_bg')).borderRadius(14)

          // 恢复默认
          Button('恢复默认主题色')
            .fontSize(15).fontColor($r('app.color.text_sub'))
            .backgroundColor($r('app.color.card_bg'))
            .width('100%').height(48).borderRadius(14)
            .onClick((): void => this.resetDefault())
        }
        .width('100%').padding(16)
      }
      .layoutWeight(1).width('100%').align(Alignment.Top)
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
