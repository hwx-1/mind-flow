import { promptAction, router } from '@kit.ArkUI';
import { AiApi } from '../../api/Api';
import { Const } from '../../constants/Const';
import { AiSessionVo } from '../../model/Models';
import { TimeUtil } from '../../utils/TimeUtil';

interface FilterItem {
  key: string;
  label: string;
}

@Entry
@Component
struct HistoryPage {
  @StorageProp('themePrimary') themePrimary: string = '#D98E73';
  @State private list: AiSessionVo[] = [];
  @State private filter: string = '';

  private readonly filters: FilterItem[] = [
    { key: '', label: '全部' },
    { key: Const.BIZ_MENTAL, label: '心理' },
    { key: Const.BIZ_STUDY, label: '学习' },
    { key: Const.BIZ_GENERAL, label: '综合' }
  ];

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    try {
      this.list = await AiApi.sessions(this.filter || undefined);
    } catch (e) {}
  }

  async deleteSession(id: number): Promise<void> {
    AlertDialog.show({
      message: '确定删除该会话？',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '删除',
        fontColor: $r('app.color.danger'),
        action: async () => {
          try {
            await AiApi.deleteSession(id);
            await this.load();
            promptAction.showToast({ message: '已删除' });
          } catch (e) {}
        }
      }
    });
  }

  private bizMark(business: string): string {
    if (business === Const.BIZ_MENTAL) {
      return '心';
    }
    if (business === Const.BIZ_STUDY) {
      return '学';
    }
    return '聊';
  }

  @Builder
  NavBar() {
    Row() {
      Image($r('sys.media.ohos_ic_public_arrow_left'))
        .width(24)
        .height(24)
        .fillColor($r('app.color.text_main'))
        .onClick(() => router.back())
      Text('历史会话')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_main'))
        .margin({ left: 12 })
      Blank()
    }
    .width('100%')
    .height(54)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.card_bg'))
    .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })
  }

  @Builder
  FilterBar() {
    Row({ space: 8 }) {
      ForEach(this.filters, (item: FilterItem) => {
        Text(item.label)
          .fontSize(13)
          .fontColor(this.filter === item.key ? Color.White : $r('app.color.text_sub'))
          .height(30)
          .padding({ left: 14, right: 14 })
          .borderRadius(15)
          .backgroundColor(this.filter === item.key ? this.themePrimary : $r('app.color.bg_page'))
          .onClick(() => {
            this.filter = item.key;
            this.load();
          })
      }, (item: FilterItem) => item.key)
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.card_bg'))
    .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })
  }

  @Builder
  SessionItem(session: AiSessionVo) {
    Row({ space: 12 }) {
      Text(this.bizMark(session.business))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .borderRadius(18)
        .backgroundColor($r('app.color.accent'))
      Column({ space: 4 }) {
        Text(session.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_main'))
        Text(session.lastMsg || '暂无消息')
          .fontSize(12)
          .fontColor($r('app.color.text_sub'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Column({ space: 8 }) {
        Text(TimeUtil.fromNow(session.updatedAt))
          .fontSize(11)
          .fontColor($r('app.color.text_sub'))
        Text('删除')
          .fontSize(12)
          .fontColor($r('app.color.danger'))
          .onClick(() => this.deleteSession(session.id))
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .height(72)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.card_bg'))
    .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })
    .onClick(() => router.pushUrl({
      url: 'view/ai/ChatPage',
      params: { sessionId: session.id, business: session.business, title: session.title }
    }))
  }

  build() {
    Column() {
      this.NavBar()
      this.FilterBar()

      List({ space: 0 }) {
        ForEach(this.list, (session: AiSessionVo) => {
          ListItem() {
            this.SessionItem(session)
          }
        }, (session: AiSessionVo) => session.id.toString())

        if (this.list.length === 0) {
          ListItem() {
            Text('暂无历史会话')
              .fontSize(13)
              .fontColor($r('app.color.text_sub'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(48)
          }
        }
      }
      .layoutWeight(1)
      .backgroundColor($r('app.color.bg_page'))
      .cachedCount(8)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
