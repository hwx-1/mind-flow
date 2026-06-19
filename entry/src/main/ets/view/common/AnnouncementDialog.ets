/**
 * 公告弹窗（微博式）：标题 + 内容（可滚动）+ 两个操作。
 *  - 「不再显示」：屏蔽该公告 1 天；
 *  - 「我知道了」：仅关闭，下次进入仍弹。
 */
@CustomDialog
export struct AnnouncementDialog {
  controller: CustomDialogController;
  title: string = '公告';
  content: string = '';
  onNeverDay: () => void = (): void => {};
  onKnow: () => void = (): void => {};
  @StorageProp('themePrimary') themePrimary: string = '#D98E73';

  build() {
    Column() {
      // 顶部标题条
      Row() {
        Image($r('sys.media.ohos_ic_public_email'))
          .width(22).height(22).fillColor(this.themePrimary)
        Text(this.title)
          .fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_main'))
          .margin({ left: 8 })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ top: 22, bottom: 14 })

      // 内容（超长可滚动）
      Scroll() {
        Text(this.content)
          .fontSize(15)
          .lineHeight(24)
          .fontColor($r('app.color.text_main'))
          .width('100%')
      }
      .edgeEffect(EdgeEffect.Spring)
      .constraintSize({ maxHeight: 320 })
      .padding({ left: 22, right: 22 })
      .align(Alignment.TopStart)

      Divider().color($r('app.color.divider')).margin({ top: 18 })

      // 操作区
      Row() {
        Text('不再显示')
          .fontSize(15)
          .fontColor($r('app.color.text_sub'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .height(50)
          .onClick((): void => {
            this.onNeverDay();
            this.controller.close();
          })
        Divider().vertical(true).color($r('app.color.divider')).height(28)
        Text('我知道了')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themePrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .height(50)
          .onClick((): void => {
            this.onKnow();
            this.controller.close();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('82%')
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(18)
  }
}
