interface EmojiItem {
  value: string;
  label: string;
}

@Component
export struct EmojiBar {
  @StorageProp('themePrimary') themePrimary: string = '#D98E73';
  @StorageProp('themePrimaryLight') themePrimaryLight: string = '#F3ECE1';
  onPick: (value: string) => void = () => {};
  @State customEmojis: EmojiItem[] = [];
  private systemEmojis: string[] = ['😀', '😊', '🥰', '😂', '😌', '😭', '👏', '💪', '✨', '🌈', '❤️', '💬'];

  aboutToAppear(): void {
    setTimeout(() => {
      this.customEmojis = [
        { value: '[抱抱]', label: '抱抱' },
        { value: '[加油]', label: '加油' },
        { value: '[治愈]', label: '治愈' }
      ];
    }, 120);
  }

  build() {
    Column() {
      Scroll() {
        Row({ space: 10 }) {
          ForEach(this.systemEmojis, (emoji: string) => {
            Text(emoji)
              .fontSize(23)
              .width(34)
              .height(34)
              .textAlign(TextAlign.Center)
              .borderRadius(17)
              .backgroundColor($r('app.color.glass_tint'))
              .onClick(() => this.onPick(emoji))
          })
          ForEach(this.customEmojis, (emoji: EmojiItem) => {
            Text(emoji.label)
              .fontSize(12)
              .fontColor(this.themePrimary)
              .height(34)
              .padding({ left: 10, right: 10 })
              .borderRadius(17)
              .backgroundColor(this.themePrimaryLight)
              .onClick(() => this.onPick(emoji.value))
          }, (emoji: EmojiItem) => emoji.value)
        }.padding({ left: 12, right: 12 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height(48)
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.card_bg'))
  }
}
