@Component
export struct GlassLoading {
  @StorageProp('themePrimary') themePrimary: string = '#D98E73';
  message: string = '加载中';

  build() {
    Row({ space: 10 }) {
      LoadingProgress()
        .width(26)
        .height(26)
        .color(this.themePrimary)
      Text(this.message)
        .fontSize(13)
        .fontColor($r('app.color.text_main'))
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .borderRadius(22)
    .backgroundColor($r('app.color.card_bg'))
    .border({ width: 0.5, color: $r('app.color.divider') })
  }
}
