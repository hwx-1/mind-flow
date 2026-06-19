import { promptAction, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { Const } from '../../constants/Const';
import { LocationSnapshot, LocationUtil } from '../../utils/LocationUtil';
import { LocationSelectionStore } from '../../utils/LocationSelectionStore';

@Entry
@Component
struct LocationPickerPage {
  @StorageProp('themePrimary') themePrimary: string = '#D98E73';
  @StorageProp('themePrimaryLight') themePrimaryLight: string = '#F3ECE1';
  @State private center: LocationSnapshot | null = null;
  @State private candidates: LocationSnapshot[] = [];
  @State private keyword: string = '';
  @State private loadingCurrent: boolean = false;
  @State private searching: boolean = false;
  @State private tip: string = '';

  private readonly ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  aboutToAppear(): void {
    this.loadCurrent();
  }

  private async loadCurrent(): Promise<void> {
    if (this.loadingCurrent) {
      return;
    }
    this.loadingCurrent = true;
    this.tip = '';
    try {
      this.center = await LocationUtil.current(this.ctx);
      await this.searchNearby();
    } catch (e) {
      this.tip = '无法获取实时定位，请检查定位权限';
    } finally {
      this.loadingCurrent = false;
    }
  }

  private async searchNearby(): Promise<void> {
    if (!this.center || this.searching) {
      return;
    }
    this.searching = true;
    this.tip = '';
    try {
      const list = await LocationUtil.searchNearby(this.center, this.keyword);
      this.candidates = list;
      if (Const.AMAP_WEB_KEY.length === 0) {
        this.tip = '配置高德 Key 或接入高德 SDK 后，可搜索 50km 内位置';
      } else if (list.length === 0) {
        this.tip = '没有找到 50km 内的位置';
      }
    } catch (e) {
      this.tip = '附近位置搜索失败，请稍后重试';
      this.candidates = [];
    } finally {
      this.searching = false;
    }
  }

  private distanceText(item: LocationSnapshot): string {
    const distance = item.distance ?? (this.center ? LocationUtil.distanceMeters(this.center, item) : 0);
    if (distance >= 1000) {
      return `${(distance / 1000).toFixed(1)}km`;
    }
    return `${Math.round(distance)}m`;
  }

  private selectNoLocation(): void {
    LocationSelectionStore.set(null);
    router.back();
  }

  private selectCurrent(): void {
    if (!this.center) {
      promptAction.showToast({ message: '还没有获取到实时定位' });
      return;
    }
    LocationSelectionStore.set(this.center);
    router.back();
  }

  private selectCandidate(item: LocationSnapshot): void {
    if (this.center && LocationUtil.distanceMeters(this.center, item) > Const.AMAP_LOCATION_RADIUS) {
      promptAction.showToast({ message: '只能选择 50km 以内的位置' });
      return;
    }
    LocationSelectionStore.set(item);
    router.back();
  }

  @Builder
  Header() {
    Row() {
      Text('取消')
        .fontSize(16)
        .fontColor($r('app.color.text_main'))
        .height(44)
        .onClick(() => router.back())
      Blank()
      Text('选择位置')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_main'))
      Blank()
      Text('不显示')
        .fontSize(16)
        .fontColor(this.themePrimary)
        .height(44)
        .onClick(() => this.selectNoLocation())
    }
    .height(56)
    .width('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.card_bg'))
    .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })
  }

  @Builder
  SearchBox() {
    Row({ space: 8 }) {
      Text('搜')
        .fontSize(13)
        .fontColor($r('app.color.text_sub'))
      TextInput({ placeholder: '搜索 50km 内的位置', text: this.keyword })
        .layoutWeight(1)
        .height(38)
        .fontSize(14)
        .backgroundColor(Color.Transparent)
        .padding(0)
        .onChange((value: string) => this.keyword = value)
        .onSubmit((): void => {
          this.searchNearby();
        })
      if (this.keyword.length > 0) {
        Text('搜索')
          .fontSize(13)
          .fontColor(this.themePrimary)
          .padding({ left: 8, right: 2, top: 6, bottom: 6 })
          .onClick(() => this.searchNearby())
      }
    }
    .height(42)
    .padding({ left: 12, right: 12 })
    .margin({ left: 16, right: 16, top: 12, bottom: 8 })
    .borderRadius(21)
    .backgroundColor($r('app.color.bg_page'))
  }

  @Builder
  CurrentRow() {
    Row({ space: 12 }) {
      Text('定')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .width(38)
        .height(38)
        .textAlign(TextAlign.Center)
        .borderRadius(19)
        .backgroundColor(this.themePrimary)
      Column({ space: 4 }) {
        Text(this.center ? this.center.label : (this.loadingCurrent ? '正在获取实时定位' : '实时定位'))
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_main'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.center ? this.center.address : '使用当前位置发布')
          .fontSize(12)
          .fontColor($r('app.color.text_sub'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      if (this.loadingCurrent) {
        LoadingProgress()
          .width(22)
          .height(22)
          .color(this.themePrimary)
      }
    }
    .height(64)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.card_bg'))
    .onClick(() => this.selectCurrent())
  }

  @Builder
  CandidateRow(item: LocationSnapshot) {
    Row({ space: 12 }) {
      Text(this.distanceText(item))
        .fontSize(11)
        .fontColor(this.themePrimary)
        .width(46)
        .height(24)
        .textAlign(TextAlign.Center)
        .borderRadius(12)
        .backgroundColor(this.themePrimaryLight)
      Column({ space: 4 }) {
        Text(item.label)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_main'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(item.address)
          .fontSize(12)
          .fontColor($r('app.color.text_sub'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .height(62)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.card_bg'))
    .onClick(() => this.selectCandidate(item))
  }

  build() {
    Column() {
      this.Header()
      this.SearchBox()

      List({ space: 0 }) {
        ListItem() {
          this.CurrentRow()
        }

        ListItem() {
          Row() {
            Text('不显示位置')
              .fontSize(15)
              .fontColor($r('app.color.text_main'))
              .layoutWeight(1)
            Text('发布时不带定位')
              .fontSize(12)
              .fontColor($r('app.color.text_sub'))
          }
          .height(56)
          .padding({ left: 16, right: 16 })
          .backgroundColor($r('app.color.card_bg'))
          .onClick(() => this.selectNoLocation())
        }

        if (this.candidates.length > 0) {
          ListItem() {
            Text('50km 内附近位置')
              .fontSize(12)
              .fontColor($r('app.color.text_sub'))
              .padding({ left: 16, right: 16, top: 14, bottom: 8 })
              .width('100%')
          }
        }

        ForEach(this.candidates, (item: LocationSnapshot) => {
          ListItem() {
            this.CandidateRow(item)
          }
        }, (item: LocationSnapshot) => `${item.label}_${item.latitude}_${item.longitude}`)

        if (this.tip.length > 0) {
          ListItem() {
            Text(this.tip)
              .fontSize(13)
              .fontColor($r('app.color.text_sub'))
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding({ top: 36, left: 24, right: 24 })
          }
        }

        if (this.searching) {
          ListItem() {
            Column() {
              LoadingProgress()
                .width(28)
                .height(28)
                .color(this.themePrimary)
              Text('搜索附近位置')
                .fontSize(13)
                .fontColor($r('app.color.text_sub'))
                .margin({ top: 8 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 42 })
          }
        }
      }
      .layoutWeight(1)
      .divider({ strokeWidth: 0.5, color: $r('app.color.divider'), startMargin: 76 })
      .backgroundColor($r('app.color.bg_page'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
