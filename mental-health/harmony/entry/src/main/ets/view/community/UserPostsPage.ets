import router from '@ohos.router';

@Entry
@Component
struct UserPostsPage {
  @State userId: number = 0;

  aboutToAppear(): void {
    const p = router.getParams() as Record<string, number>;
    this.userId = p['userId'] || 0;
  }

  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left')).width(24).height(24)
          .onClick(() => router.back())
        Text('TA 的发布').fontSize(17).fontWeight(FontWeight.Medium).margin({ left: 12 })
      }.width('100%').padding(14).backgroundColor(Color.White)
      Text('开发中…').fontSize(14).fontColor($r('app.color.text_sub'))
        .margin({ top: 60 }).width('100%').textAlign(TextAlign.Center)
    }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
