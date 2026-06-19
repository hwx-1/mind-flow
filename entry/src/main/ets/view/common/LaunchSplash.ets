@Component
export struct LaunchSplash {
  onSkip: () => void = () => {};

  build() {
    Column() {
      Row() {
        Blank()
        Text('跳过')
          .fontSize(13)
          .fontColor($r('app.color.text_sub'))
          .height(32)
          .padding({ left: 14, right: 14 })
          .borderRadius(16)
          .backgroundColor($r('app.color.bg_page'))
          .onClick(() => this.onSkip())
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 32 })

      Blank()

      Column({ space: 14 }) {
        Image($r('app.media.icon'))
          .width(86)
          .height(86)
          .borderRadius(18)
          .objectFit(ImageFit.Cover)
        Text('心晴')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_main'))
        Text('把情绪慢慢说清楚')
          .fontSize(14)
          .fontColor($r('app.color.text_sub'))
      }
      .width('100%')

      Blank()

      Text('Mental Health')
        .fontSize(12)
        .fontColor($r('app.color.text_sub'))
        .margin({ bottom: 34 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.card_bg'))
  }
}
