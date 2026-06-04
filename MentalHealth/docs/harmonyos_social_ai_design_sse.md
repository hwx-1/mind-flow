# HarmonyOS 社交 + AI 设计与 SSE 落地方案

本文档按当前项目结构编写，适配 DevEco Studio / API 12 / ArkTS。现有关键文件：

- `/Users/hhhwenxin/Projects/MentalHealth/entry/src/main/ets/api/HttpClient.ets`
- `/Users/hhhwenxin/Projects/MentalHealth/entry/src/main/ets/view/community/PublishPage.ets`
- `/Users/hhhwenxin/Projects/MentalHealth/entry/src/main/ets/view/community/LocationPickerPage.ets`
- `/Users/hhhwenxin/Projects/MentalHealth/entry/src/main/ets/view/common/PostCard.ets`
- `/Users/hhhwenxin/Projects/MentalHealth/entry/src/main/ets/view/ai/ChatPage.ets`
- `/Users/hhhwenxin/Projects/MentalHealth/entry/src/main/ets/view/message/MessagePage.ets`
- `/Users/hhhwenxin/Projects/MentalHealth/entry/src/main/resources/base/profile/main_pages.json`

## 1. 全局 UI 设计规范

推荐使用浅色暖调体系，与 `xsnbb.xyz` 管理后台保持同一品牌气质：暖米色背景、纸张白卡片、陶土橙主色、鼠尾草绿辅助色。移动端不直接照搬后台的桌面布局，但色彩、圆角、分割线和按钮质感保持一致。

### 1.1 色彩

当前项目已经接近这套方案，可继续收敛：

| Token | 色值 | 用途 |
| --- | --- | --- |
| `primary` | `#D98E73` | 主按钮、选中态、关注/发送 |
| `primary_light` | `#F3ECE1` | 主色浅底标签、输入框底色 |
| `accent` | `#9CAF88` | AI、在线、评论辅助色 |
| `accent_deep` | `#7D9268` | 绿色文字和强调态 |
| `gold` | `#E0B87F` | 温暖提示、学习辅导类装饰 |
| `blush` | `#F0D4C4` | 柔和头像/占位背景 |
| `clay` | `#8A7158` | 次级强调、陌生人气泡 |
| `danger` | `#C0573F` | 点赞、未读红点、删除 |
| `bg_page` | `#FAF6F0` | 页面背景 |
| `card_bg` | `#FFFDFA` | 列表项、聊天栏、发帖白底区域 |
| `text_main` | `#4A3F35` | 主标题、正文 |
| `text_sub` | `#8A7D6E` | 时间、提示、摘要 |
| `divider` | `#ECE2D4` | 0.5px 分割线 |

资源文件建议保持在：

```json
{
  "color": [
    { "name": "primary", "value": "#FFD98E73" },
    { "name": "primary_light", "value": "#FFF3ECE1" },
    { "name": "accent", "value": "#FF9CAF88" },
    { "name": "accent_deep", "value": "#FF7D9268" },
    { "name": "gold", "value": "#FFE0B87F" },
    { "name": "blush", "value": "#FFF0D4C4" },
    { "name": "clay", "value": "#FF8A7158" },
    { "name": "danger", "value": "#FFC0573F" },
    { "name": "bg_page", "value": "#FFFAF6F0" },
    { "name": "card_bg", "value": "#FFFFFDFA" },
    { "name": "text_main", "value": "#FF4A3F35" },
    { "name": "text_sub", "value": "#FF8A7D6E" },
    { "name": "divider", "value": "#FFECE2D4" }
  ]
}
```

### 1.2 字号与间距

| 场景 | 字号 | 字重 | 行高/高度 |
| --- | --- | --- | --- |
| 一级页标题 | 22-24 | Bold | 顶栏 56 |
| 列表主标题 | 15-16 | Medium | 行高 22 |
| 正文/聊天 | 14-15 | Regular | 行高 22-23 |
| 摘要/时间 | 11-13 | Regular | 行高 17-19 |
| 按钮文字 | 14-16 | Medium/Bold | 高度 36-44 |

全局间距：

- 页面左右边距：`16`
- 列表项上下内边距：`12`
- 卡片内边距：`12-16`
- 头像：消息列表 `48x48`，社区卡片 `42x42`
- 圆角：按钮/输入框保持 `14-22`，列表头像可用 `8-14`，图片 `8`，大卡片 `14-20`
- 分割线：列表用 `.divider({ strokeWidth: 0.5, startMargin: 76 })`

### 1.3 底部导航

四个 Tab：社区、AI、消息、我的。建议：

- 选中图标和文字：`primary`
- 未选中：`text_sub`
- 图标 22-24，文字 11
- 未读角标放在消息 Tab 图标右上角，红底白字，高 `16-18`
- 底栏高度 `58-64`，背景 `card_bg`，顶部 0.5px 分割线

## 2. 数据结构建议

当前 `Models.ets` 已经覆盖大部分字段。建议后端统一返回：

```ts
export interface PostVo {
  id: number;
  userId: number;
  uid?: string;
  nickname: string;
  avatar: string;
  content: string;
  topic?: string;
  images?: string[];
  video?: string;
  locationLabel?: string;
  latitude?: number;
  longitude?: number;
  likeCount: number;
  commentCount: number;
  liked: boolean;
  collected: boolean;
  createdAt: string;
}

export interface CommentVo {
  id: number;
  userId?: number;
  nickname?: string;
  avatar?: string;
  content: string;
  emojiUrl?: string;
  replyId?: number;
  createdAt: string;
}

export interface ChatConvVo {
  userId: number;
  uid?: string;
  nickname?: string;
  avatar?: string;
  lastMessage?: string;
  unreadCount?: number;
  updatedAt: string;
  relation?: 'friend' | 'pending' | 'stranger';
}
```

## 3. 贴吧发帖页 ArkTS 关键代码

当前项目已有 `/entry/src/main/ets/view/community/PublishPage.ets`。如果要补齐「最多 9 图或 1 视频、话题、定位、发布」完整逻辑，可按下面结构调整。

```ts
import { promptAction, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { PostApi } from '../../api/Api';
import { PublishPostReq } from '../../model/Models';
import { LocationUtil } from '../../utils/LocationUtil';
import { UploadUtil } from '../../utils/UploadUtil';

interface MediaItem {
  local: string;
  remote?: string;
  uploading: boolean;
}

@Entry
@Component
struct PublishPage {
  @State private content: string = '';
  @State private topic: string = '';
  @State private images: MediaItem[] = [];
  @State private video: MediaItem | null = null;
  @State private submitting: boolean = false;
  @State private locating: boolean = false;
  @State private locationLabel: string = '获取位置';
  @State private locationAddress: string = '';
  @State private latitude: number = 0;
  @State private longitude: number = 0;

  private readonly ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  aboutToAppear(): void {
    this.refreshLocation();
  }

  private canSubmit(): boolean {
    const hasText = this.content.trim().length > 0;
    const hasMedia = this.images.length > 0 || this.video !== null;
    return (hasText || hasMedia) && !this.submitting;
  }

  private remoteImages(): string[] {
    const list: string[] = [];
    this.images.forEach((item: MediaItem) => {
      if (item.remote) list.push(item.remote);
    });
    return list;
  }

  async refreshLocation(): Promise<void> {
    if (this.locating) return;
    this.locating = true;
    try {
      const snap = await LocationUtil.current(this.ctx);
      this.locationLabel = snap.label;
      this.locationAddress = snap.address;
      this.latitude = snap.latitude;
      this.longitude = snap.longitude;
    } catch (_) {
      this.locationLabel = '不显示位置';
      this.locationAddress = '';
    } finally {
      this.locating = false;
    }
  }

  async pickImages(): Promise<void> {
    if (this.video) {
      promptAction.showToast({ message: '图片和视频不能同时发布' });
      return;
    }
    const remain = 9 - this.images.length;
    if (remain <= 0) return;
    const uris = await UploadUtil.pickImages(remain);
    uris.forEach((uri: string) => {
      const item: MediaItem = { local: uri, uploading: true };
      this.images = this.images.concat([item]);
      UploadUtil.upload(this.ctx, uri, 'image')
        .then((url: string) => {
          item.remote = url;
          item.uploading = false;
          this.images = this.images.slice();
        })
        .catch(() => {
          this.images = this.images.filter((target: MediaItem) => target !== item);
          promptAction.showToast({ message: '图片上传失败' });
        });
    });
  }

  async pickVideo(): Promise<void> {
    if (this.images.length > 0) {
      promptAction.showToast({ message: '图片和视频不能同时发布' });
      return;
    }
    const uri = await UploadUtil.pickVideo();
    if (!uri) return;
    const item: MediaItem = { local: uri, uploading: true };
    this.video = item;
    UploadUtil.upload(this.ctx, uri, 'video')
      .then((url: string) => {
        item.remote = url;
        item.uploading = false;
        this.video = item;
      })
      .catch(() => {
        this.video = null;
        promptAction.showToast({ message: '视频上传失败' });
      });
  }

  async submit(): Promise<void> {
    if (!this.canSubmit()) {
      promptAction.showToast({ message: '写点内容或选择图片/视频' });
      return;
    }
    if (this.images.some((item: MediaItem) => item.uploading) || this.video?.uploading) {
      promptAction.showToast({ message: '资源还在上传' });
      return;
    }
    this.submitting = true;
    try {
      const req: PublishPostReq = {
        content: this.content.trim(),
        topic: this.topic.trim() || undefined,
        images: this.remoteImages(),
        video: this.video?.remote,
        locationLabel: this.locationLabel !== '不显示位置' ? this.locationLabel : undefined,
        latitude: this.locationLabel !== '不显示位置' ? this.latitude : undefined,
        longitude: this.locationLabel !== '不显示位置' ? this.longitude : undefined,
        address: this.locationAddress || undefined
      };
      await PostApi.publish(req);
      promptAction.showToast({ message: '发布成功' });
      router.back();
    } finally {
      this.submitting = false;
    }
  }

  @Builder
  NavBar() {
    Row() {
      Text('取消')
        .fontSize(16)
        .fontColor($r('app.color.text_main'))
        .height(44)
        .onClick(() => router.back())
      Blank()
      Text(this.submitting ? '发布中' : '发表')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.canSubmit() ? Color.White : $r('app.color.text_sub'))
        .height(36)
        .padding({ left: 18, right: 18 })
        .borderRadius(18)
        .backgroundColor(this.canSubmit() ? $r('app.color.primary') : $r('app.color.bg_page'))
        .onClick(() => this.submit())
    }
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.card_bg'))
  }

  @Builder
  MediaGrid() {
    Grid() {
      ForEach(this.images, (item: MediaItem, index: number) => {
        GridItem() {
          Stack() {
            Image(item.local).width('100%').aspectRatio(1).objectFit(ImageFit.Cover).borderRadius(6)
            if (item.uploading) {
              LoadingProgress().width(24).height(24).color(Color.White)
            }
            Text('x')
              .fontSize(14)
              .fontColor(Color.White)
              .width(22)
              .height(22)
              .textAlign(TextAlign.Center)
              .borderRadius(11)
              .backgroundColor('#99000000')
              .position({ x: '76%', y: 4 })
              .onClick(() => this.images = this.images.filter((_, i: number) => i !== index))
          }
        }
      }, (_item: MediaItem, index: number) => index.toString())

      if (this.video) {
        GridItem() {
          Stack() {
            Video({ src: this.video.local })
              .width('100%')
              .aspectRatio(1)
              .controls(false)
              .autoPlay(false)
              .objectFit(ImageFit.Cover)
            Image($r('sys.media.ohos_ic_public_play')).width(38).height(38).fillColor(Color.White)
          }
        }
      }

      if (this.images.length < 9 && this.video === null) {
        GridItem() {
          Column() {
            Text('+').fontSize(34).fontColor($r('app.color.text_sub'))
          }
          .width('100%')
          .aspectRatio(1)
          .justifyContent(FlexAlign.Center)
          .backgroundColor($r('app.color.bg_page'))
          .borderRadius(6)
          .onClick(() => this.pickImages())
        }
      }
    }
    .columnsTemplate('1fr 1fr 1fr')
    .columnsGap(8)
    .rowsGap(8)
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }

  build() {
    Column() {
      this.NavBar()
      Scroll() {
        Column({ space: 0 }) {
          TextArea({ placeholder: '这一刻的想法...', text: this.content })
            .height(180)
            .fontSize(16)
            .lineHeight(24)
            .backgroundColor($r('app.color.card_bg'))
            .padding({ left: 16, right: 16, top: 14, bottom: 10 })
            .onChange((value: string) => this.content = value)

          this.MediaGrid()

          Row({ space: 8 }) {
            Text('#').fontSize(16).fontColor($r('app.color.primary'))
            TextInput({ placeholder: '添加话题', text: this.topic })
              .layoutWeight(1)
              .height(40)
              .backgroundColor(Color.Transparent)
              .fontSize(14)
              .onChange((value: string) => this.topic = value)
          }
          .height(48)
          .padding({ left: 16, right: 16 })
          .backgroundColor($r('app.color.card_bg'))

          Row({ space: 8 }) {
            Image($r('sys.media.ohos_ic_public_location')).width(18).height(18).fillColor($r('app.color.primary'))
            Text(this.locating ? '定位中' : this.locationLabel)
              .layoutWeight(1)
              .fontSize(14)
              .fontColor($r('app.color.text_main'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .height(48)
          .padding({ left: 16, right: 16 })
          .backgroundColor($r('app.color.card_bg'))
          .onClick(() => this.refreshLocation())
        }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
```

## 4. 动态卡片 ArkTS 关键代码

当前项目已有 `/entry/src/main/ets/view/common/PostCard.ets`。为了避免数据库操作后页面无反馈，点赞、评论、关注这类动作都建议：先调用接口，再拉 `detail/list` 刷新，最后 `this.post = fresh` 或 `this.onChanged()`。

```ts
import { router } from '@kit.ArkUI';
import { PostApi } from '../../api/Api';
import { PostVo } from '../../model/Models';
import { TimeUtil } from '../../utils/TimeUtil';

@Component
export struct PostCard {
  @Prop post: PostVo;
  @State private likeScale: number = 1;
  onChanged: () => void = () => {};

  async toggleLike(e: ClickEvent): Promise<void> {
    e.stopPropagation();
    animateTo({ duration: 180, curve: Curve.Friction }, () => this.likeScale = 1.22);
    setTimeout(() => animateTo({ duration: 180, curve: Curve.Friction }, () => this.likeScale = 1), 120);
    await PostApi.like(this.post.id);
    const fresh = await PostApi.detail(this.post.id);
    this.post.liked = fresh.liked;
    this.post.likeCount = fresh.likeCount;
    this.post.commentCount = fresh.commentCount;
    this.onChanged();
  }

  @Builder
  Media(images?: string[], video?: string) {
    if (images && images.length > 0) {
      Grid() {
        ForEach(images.slice(0, 9), (url: string) => {
          GridItem() {
            Image(url).width('100%').aspectRatio(1).objectFit(ImageFit.Cover).borderRadius(6)
          }
        }, (url: string) => url)
      }
      .columnsTemplate(images.length === 2 || images.length === 4 ? '1fr 1fr' : '1fr 1fr 1fr')
      .columnsGap(4)
      .rowsGap(4)
      .height(images.length <= 3 ? 110 : (images.length <= 6 ? 220 : 330))
      .margin({ top: 8 })
    }
    if (video) {
      Video({ src: video })
        .width('100%')
        .aspectRatio(1.65)
        .controls(true)
        .autoPlay(false)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)
        .margin({ top: 8 })
    }
  }

  build() {
    Column({ space: 0 }) {
      Row({ space: 10 }) {
        Image(this.post.avatar || $r('app.media.icon'))
          .width(42)
          .height(42)
          .borderRadius(21)
          .objectFit(ImageFit.Cover)
          .onClick((e: ClickEvent) => {
            e.stopPropagation();
            router.pushUrl({ url: 'view/community/UserPostsPage', params: { userId: this.post.userId } });
          })
        Column({ space: 2 }) {
          Text(this.post.nickname || '匿名用户')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_main'))
          Text(TimeUtil.fromNow(this.post.createdAt))
            .fontSize(11)
            .fontColor($r('app.color.text_sub'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }

      Text(this.post.content)
        .width('100%')
        .fontSize(15)
        .lineHeight(22)
        .fontColor($r('app.color.text_main'))
        .margin({ top: 8 })
        .maxLines(6)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      if (this.post.topic) {
        Text(`#${this.post.topic}`)
          .fontSize(13)
          .fontColor($r('app.color.primary'))
          .margin({ top: 6 })
      }

      if (this.post.locationLabel) {
        Text(this.post.locationLabel)
          .fontSize(12)
          .fontColor($r('app.color.text_sub'))
          .margin({ top: 6 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      this.Media(this.post.images, this.post.video)

      Row() {
        Row({ space: 4 }) {
          Image($r('sys.media.ohos_ic_public_email')).width(18).height(18).fillColor($r('app.color.text_sub'))
          Text(this.post.commentCount.toString()).fontSize(13).fontColor($r('app.color.text_sub'))
        }
        .layoutWeight(1)
        .onClick((e: ClickEvent) => {
          e.stopPropagation();
          router.pushUrl({ url: 'view/community/PostDetailPage', params: { id: this.post.id, focusComment: 1 } });
        })
        Row({ space: 4 }) {
          Image($r('sys.media.ohos_ic_public_ok'))
            .width(18)
            .height(18)
            .fillColor(this.post.liked ? $r('app.color.danger') : $r('app.color.text_sub'))
            .scale({ x: this.likeScale, y: this.likeScale })
          Text(this.post.likeCount.toString())
            .fontSize(13)
            .fontColor(this.post.liked ? $r('app.color.danger') : $r('app.color.text_sub'))
        }
        .onClick((e: ClickEvent) => this.toggleLike(e))
      }
      .padding({ top: 10 })
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(8)
    .onClick(() => router.pushUrl({ url: 'view/community/PostDetailPage', params: { id: this.post.id } }))
  }
}
```

## 5. AI 对话页：真正 SSE 流式输出

### 5.1 为什么现在会一次性返回

常见原因：

1. 前端用了普通 `fetch/session.fetch/request`，只有响应结束后才拿到 body。
2. 后端不是 `text/event-stream`，而是一次性返回 JSON。
3. 后端没有每个 token 后 `flush`。
4. 宝塔 / Nginx 开了 `proxy_buffering` 或 gzip，把小块响应缓冲到结束再发。
5. SSE 帧格式不对：必须是 `data: xxx\n\n`。
6. 客户端没有按 `\n\n` 拼接帧，遇到半包/粘包时解析失败。

### 5.2 ArkTS SSE 客户端

当前项目 `/entry/src/main/ets/api/HttpClient.ets` 已经使用 `requestInStream`，核心代码如下：

```ts
import http from '@ohos.net.http';
import { util } from '@kit.ArkTS';
import { Const } from '../constants/Const';
import { Auth } from '../store/Auth';

interface SseDelta {
  delta?: string;
  content?: string;
  text?: string;
  message?: string;
}

class HttpClient {
  private emitSsePayload(payload: string, onDelta: (s: string) => void): boolean {
    if (payload === '[DONE]') return true;
    try {
      const obj = JSON.parse(payload) as SseDelta;
      const delta = obj.delta || obj.content || obj.text || obj.message;
      if (delta) onDelta(delta);
    } catch (_) {
      onDelta(payload);
    }
    return false;
  }

  sse(
    url: string,
    body: object,
    onDelta: (s: string) => void,
    onDone: () => void,
    onError: (e: Error) => void
  ): () => void {
    const fullUrl = url.startsWith('http') ? url : `${Const.BASE_URL}${url}`;
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream'
    };
    const token = Auth.getToken();
    if (token) headers['Authorization'] = `Bearer ${token}`;

    let buffer = '';
    let finished = false;
    const decoder = util.TextDecoder.create('utf-8');
    const request = http.createHttp();

    const processFrame = (frame: string): boolean => {
      let payload = '';
      frame.split('\n').forEach((line: string) => {
        const text = line.trim();
        if (text.startsWith('data:')) payload += text.substring(5).trim();
      });
      if (!payload) return false;
      return this.emitSsePayload(payload, onDelta);
    };

    const processBuffer = (): void => {
      buffer = buffer.replace(/\r\n/g, '\n');
      let idx = buffer.indexOf('\n\n');
      while (idx !== -1) {
        const frame = buffer.substring(0, idx);
        buffer = buffer.substring(idx + 2);
        if (processFrame(frame)) {
          finished = true;
          onDone();
          return;
        }
        idx = buffer.indexOf('\n\n');
      }
    };

    request.on('dataReceive', (data: ArrayBuffer): void => {
      if (finished) return;
      buffer += decoder.decodeToString(new Uint8Array(data));
      processBuffer();
    });

    request.on('dataEnd', (): void => {
      if (!finished) {
        if (buffer.trim().length > 0) processFrame(buffer.trim());
        finished = true;
        onDone();
      }
      request.destroy();
    });

    request.requestInStream(fullUrl, {
      method: http.RequestMethod.POST,
      header: headers,
      extraData: JSON.stringify(body),
      connectTimeout: 15000,
      readTimeout: 120000,
      usingCache: false
    }).then((code: number) => {
      if (code < 200 || code >= 300) {
        finished = true;
        onError(new Error(`SSE HTTP ${code}`));
      }
    }).catch((e: Error) => {
      finished = true;
      onError(e);
      request.destroy();
    });

    return (): void => {
      finished = true;
      request.destroy();
    };
  }
}

export const Http = new HttpClient();
```

### 5.3 ChatPage 打字机效果

关键点：不要每收到 1 个 token 就马上刷新整页，建议放进 `pendingDelta`，每 30-50ms 批量刷一次，既有逐字感，也不会卡 UI。

```ts
import { promptAction, router } from '@kit.ArkUI';
import { AiApi } from '../../api/Api';
import { Http } from '../../api/HttpClient';
import { AiMessageVo, ChatReq } from '../../model/Models';

interface ChatMsg {
  role: string;
  content: string;
}

@Entry
@Component
struct ChatPage {
  @State private messages: ChatMsg[] = [];
  @State private input: string = '';
  @State private streaming: boolean = false;
  @State private title: string = 'AI 助手';

  private sessionId: number = 0;
  private business: string = 'general';
  private readonly listScroller: Scroller = new Scroller();
  private cancelStream: (() => void) | null = null;
  private streamingIndex: number = -1;
  private pendingDelta: string = '';
  private flushTimer: number | null = null;

  async aboutToAppear(): Promise<void> {
    const p = router.getParams() as Record<string, number | string>;
    this.sessionId = (p?.sessionId as number) ?? 0;
    this.business = (p?.business as string) ?? 'general';
    this.title = (p?.title as string) ?? 'AI 助手';
    await this.loadHistory();
  }

  aboutToDisappear(): void {
    this.stopStream();
  }

  async loadHistory(): Promise<void> {
    const list = await AiApi.messages(this.sessionId);
    this.messages = list.map((item: AiMessageVo): ChatMsg => ({ role: item.role, content: item.content }));
    if (this.messages.length === 0) this.messages = [{ role: 'assistant', content: '你好，有什么想聊的？' }];
    this.scrollEnd(80);
  }

  private scrollEnd(delay: number = 30): void {
    setTimeout(() => this.listScroller.scrollEdge(Edge.Bottom), delay);
  }

  private flushDelta(): void {
    if (this.streamingIndex < 0 || this.pendingDelta.length === 0) {
      this.flushTimer = null;
      return;
    }
    this.messages[this.streamingIndex].content += this.pendingDelta;
    this.pendingDelta = '';
    this.messages = this.messages.slice();
    this.flushTimer = null;
    this.scrollEnd(20);
  }

  private scheduleFlush(): void {
    if (this.flushTimer !== null) return;
    this.flushTimer = setTimeout(() => this.flushDelta(), 40);
  }

  private stopStream(): void {
    if (this.cancelStream) {
      this.cancelStream();
      this.cancelStream = null;
    }
    if (this.flushTimer !== null) {
      clearTimeout(this.flushTimer);
      this.flushTimer = null;
    }
    this.flushDelta();
    this.streaming = false;
    this.streamingIndex = -1;
  }

  send(): void {
    if (this.streaming) return;
    const text = this.input.trim();
    if (!text) return;

    this.input = '';
    this.messages = this.messages.concat([{ role: 'user', content: text }, { role: 'assistant', content: '' }]);
    this.streamingIndex = this.messages.length - 1;
    this.streaming = true;
    this.scrollEnd();

    const body: ChatReq = { sessionId: this.sessionId, content: text };
    this.cancelStream = Http.sse(
      '/ai/chat',
      body,
      (delta: string) => {
        this.pendingDelta += delta;
        this.scheduleFlush();
      },
      () => {
        this.flushDelta();
        this.streaming = false;
        this.streamingIndex = -1;
        this.cancelStream = null;
        this.scrollEnd();
      },
      (e: Error) => {
        this.flushDelta();
        if (this.streamingIndex >= 0) {
          this.messages[this.streamingIndex].content = `出错了：${e.message}`;
          this.messages = this.messages.slice();
        }
        this.streaming = false;
        this.streamingIndex = -1;
        this.cancelStream = null;
        promptAction.showToast({ message: 'AI 回复失败' });
      }
    );
  }

  @Builder
  Bubble(m: ChatMsg, index: number) {
    if (m.role === 'user') {
      Row() {
        Blank()
        Text(m.content)
          .fontSize(15)
          .lineHeight(22)
          .fontColor(Color.White)
          .padding({ left: 13, right: 13, top: 10, bottom: 10 })
          .backgroundColor($r('app.color.primary'))
          .borderRadius({ topLeft: 16, topRight: 4, bottomLeft: 16, bottomRight: 16 })
          .constraintSize({ maxWidth: '78%' })
      }
      .width('100%')
      .padding({ left: 54 })
    } else {
      Row({ space: 8 }) {
        Text('AI')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .width(30)
          .height(30)
          .textAlign(TextAlign.Center)
          .borderRadius(15)
          .backgroundColor($r('app.color.accent'))
        Text(m.content || (this.streaming && index === this.streamingIndex ? '思考中...' : ''))
          .fontSize(15)
          .lineHeight(23)
          .fontColor($r('app.color.text_main'))
          .padding({ left: 13, right: 13, top: 10, bottom: 10 })
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius({ topLeft: 4, topRight: 16, bottomLeft: 16, bottomRight: 16 })
          .constraintSize({ maxWidth: '78%' })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .padding({ right: 54 })
    }
  }

  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left')).width(24).height(24).onClick(() => router.back())
        Text(this.title).fontSize(17).fontWeight(FontWeight.Bold).layoutWeight(1).margin({ left: 12 })
        if (this.streaming) Text('停止').fontSize(13).fontColor($r('app.color.primary')).onClick(() => this.stopStream())
      }
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor($r('app.color.card_bg'))

      List({ space: 14, scroller: this.listScroller }) {
        ForEach(this.messages, (m: ChatMsg, index: number) => {
          ListItem() { this.Bubble(m, index) }
        }, (_m: ChatMsg, index: number) => index.toString())
      }
      .layoutWeight(1)
      .padding({ left: 12, right: 12, top: 14, bottom: 14 })

      Row({ space: 8 }) {
        TextInput({ placeholder: this.streaming ? 'AI 正在回复...' : '输入消息', text: this.input })
          .layoutWeight(1)
          .height(40)
          .fontSize(15)
          .borderRadius(20)
          .backgroundColor($r('app.color.bg_page'))
          .enabled(!this.streaming)
          .onChange((value: string) => this.input = value)
          .onSubmit(() => this.send())
        Text(this.streaming ? '停止' : '发送')
          .height(40)
          .padding({ left: 16, right: 16 })
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .borderRadius(20)
          .backgroundColor(this.streaming || this.input.trim().length > 0 ? $r('app.color.primary') : '#66D98E73')
          .onClick(() => this.streaming ? this.stopStream() : this.send())
      }
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .backgroundColor($r('app.color.card_bg'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
```

## 6. 后端 SSE 配合

### 6.1 Node.js / Express 示例

```js
app.post('/api/ai/chat', async (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream; charset=utf-8');
  res.setHeader('Cache-Control', 'no-cache, no-transform');
  res.setHeader('Connection', 'keep-alive');
  res.setHeader('X-Accel-Buffering', 'no');
  res.flushHeaders?.();

  try {
    for await (const token of llmStream(req.body.content)) {
      res.write(`data: ${JSON.stringify({ delta: token })}\n\n`);
    }
    res.write('data: [DONE]\n\n');
  } catch (e) {
    res.write(`data: ${JSON.stringify({ delta: '服务暂时不可用' })}\n\n`);
    res.write('data: [DONE]\n\n');
  } finally {
    res.end();
  }
});
```

如果使用 NestJS / Koa，也同样要保证每个 token 后 `write`，不要先拼完整字符串再返回。

### 6.2 Python / Flask 示例

```py
from flask import Flask, Response, request
import json

app = Flask(__name__)

@app.post('/api/ai/chat')
def ai_chat():
    content = request.json.get('content', '')

    def generate():
        for token in llm_stream(content):
            yield 'data: ' + json.dumps({'delta': token}, ensure_ascii=False) + '\n\n'
        yield 'data: [DONE]\n\n'

    return Response(
        generate(),
        mimetype='text/event-stream',
        headers={
            'Cache-Control': 'no-cache, no-transform',
            'X-Accel-Buffering': 'no'
        }
    )
```

### 6.3 宝塔 / Nginx 反代配置

宝塔里如果网站使用 Nginx 反代，SSE 路由至少要关闭缓冲：

```nginx
location /api/ai/chat {
    proxy_pass http://127.0.0.1:8080/api/ai/chat;
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    proxy_buffering off;
    proxy_cache off;
    gzip off;
    add_header X-Accel-Buffering no;
}
```

如果后端在 `/api` 下整体反代，可以在整个 `/api/` location 关闭 `proxy_buffering`，或者单独给 `/api/ai/chat` 加更高优先级的 location。

## 7. 消息页 ArkTS 关键代码

当前项目已有 `/entry/src/main/ets/view/message/MessagePage.ets`。它已经包含互动通知、私信列表、搜索、未读角标、添加好友入口。建议结构如下：

```ts
import { router } from '@kit.ArkUI';
import { MessageApi } from '../../api/Api';
import { NotificationVo, ChatConvVo } from '../../model/Models';
import { TimeUtil } from '../../utils/TimeUtil';

@Component
export struct MessagePage {
  @State private notes: NotificationVo[] = [];
  @State private chats: ChatConvVo[] = [];
  @State private unread: Record<string, number> = {};
  @State private refreshing: boolean = false;
  @State private loading: boolean = false;
  @State private showNotifications: boolean = false;
  @State private searchText: string = '';

  aboutToAppear(): void {
    this.refresh();
  }

  onPageShow(): void {
    this.refresh();
  }

  async refresh(): Promise<void> {
    if (this.loading) return;
    this.loading = true;
    try {
      this.notes = await MessageApi.notifications('all');
      this.chats = await MessageApi.chats();
      this.unread = await MessageApi.unreadCount();
    } finally {
      this.loading = false;
      this.refreshing = false;
    }
  }

  private notificationUnread(): number {
    return (this.unread['like'] || 0) + (this.unread['comment'] || 0) + (this.unread['follow'] || 0) + (this.unread['friend'] || 0);
  }

  private matchSearch(c: ChatConvVo): boolean {
    const q = this.searchText.trim().toLowerCase();
    if (!q) return true;
    return (c.nickname || '用户').toLowerCase().includes(q) || (c.lastMessage || '').toLowerCase().includes(q);
  }

  @Builder
  Header() {
    Column({ space: 10 }) {
      Row() {
        Text('消息').fontSize(24).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_main'))
        Blank()
        Text('+')
          .fontSize(26)
          .fontColor($r('app.color.text_main'))
          .width(34)
          .height(34)
          .textAlign(TextAlign.Center)
          .borderRadius(17)
          .backgroundColor($r('app.color.bg_page'))
          .onClick(() => router.pushUrl({ url: 'view/message/AddFriendPage' }))
      }
      Row({ space: 8 }) {
        Text('搜索').fontSize(13).fontColor($r('app.color.text_sub'))
        TextInput({ placeholder: '搜索好友或聊天记录', text: this.searchText })
          .layoutWeight(1)
          .height(36)
          .fontSize(14)
          .backgroundColor(Color.Transparent)
          .onChange((value: string) => this.searchText = value)
      }
      .height(40)
      .padding({ left: 12, right: 12 })
      .borderRadius(20)
      .backgroundColor($r('app.color.bg_page'))
    }
    .padding({ left: 16, right: 16, top: 14, bottom: 12 })
    .backgroundColor($r('app.color.card_bg'))
  }

  @Builder
  NotificationEntry() {
    Row({ space: 12 }) {
      Stack() {
        Text('互')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .width(48)
          .height(48)
          .textAlign(TextAlign.Center)
          .borderRadius(8)
          .backgroundColor($r('app.color.accent'))
        if (this.notificationUnread() > 0) {
          Text(this.notificationUnread() > 99 ? '99+' : this.notificationUnread().toString())
            .fontSize(10)
            .fontColor(Color.White)
            .height(18)
            .padding({ left: 6, right: 6 })
            .borderRadius(9)
            .backgroundColor($r('app.color.danger'))
            .position({ x: 34, y: -5 })
        }
      }
      Column({ space: 5 }) {
        Text('互动消息').fontSize(15).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_main'))
        Text(this.notes.length > 0 ? this.notes[0].content : '暂无新的互动消息')
          .fontSize(13)
          .fontColor($r('app.color.text_sub'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.card_bg'))
    .onClick(() => this.showNotifications = !this.showNotifications)
  }

  @Builder
  ConversationRow(c: ChatConvVo) {
    Row({ space: 12 }) {
      Stack() {
        Image(c.avatar || $r('app.media.icon'))
          .width(48)
          .height(48)
          .borderRadius(8)
          .objectFit(ImageFit.Cover)
        if (c.unreadCount && c.unreadCount > 0) {
          Text(c.unreadCount > 99 ? '99+' : c.unreadCount.toString())
            .fontSize(10)
            .fontColor(Color.White)
            .height(18)
            .padding({ left: 6, right: 6 })
            .borderRadius(9)
            .backgroundColor($r('app.color.danger'))
            .position({ x: 34, y: -5 })
        }
      }
      Column({ space: 5 }) {
        Row() {
          Text(c.nickname || '用户').fontSize(15).fontWeight(FontWeight.Medium).layoutWeight(1)
          Text(TimeUtil.fromNow(c.updatedAt)).fontSize(12).fontColor($r('app.color.text_sub'))
        }
        Text(c.lastMessage || '')
          .fontSize(13)
          .fontColor($r('app.color.text_sub'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .height(72)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.card_bg'))
    .onClick(() => router.pushUrl({
      url: 'view/message/ChatRoomPage',
      params: { userId: c.userId, nickname: c.nickname, avatar: c.avatar }
    }))
  }

  build() {
    Column() {
      this.Header()
      Refresh({ refreshing: $$this.refreshing }) {
        List({ space: 0 }) {
          ListItem() { this.NotificationEntry() }
          ForEach(this.chats, (c: ChatConvVo) => {
            if (this.matchSearch(c)) {
              ListItem() { this.ConversationRow(c) }
            }
          }, (c: ChatConvVo) => c.userId.toString())
        }
        .divider({ strokeWidth: 0.5, color: $r('app.color.divider'), startMargin: 76 })
      }
      .layoutWeight(1)
      .onRefreshing(() => this.refresh())
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
```

## 8. 个人页

个人页建议保持微信资料页逻辑：

- 顶部资料卡不做大面积装饰，白底 + 头像 + 昵称 + UID + 状态 + 简介。
- “关注/粉丝/获赞”一行展示数字。
- 我的帖子 / 我的点赞 / 我的评论做三段 Tab 或三行入口。
- 编辑资料页所有字段顶格，使用白底列表表单。
- 状态颜色必须由状态映射，不要固定绿色。

状态颜色建议：

```ts
export class ProfileStatusUtil {
  static label(status?: string): string {
    if (status === 'busy') return '忙碌';
    if (status === 'away') return '离开';
    if (status === 'study') return '学习中';
    if (status === 'sad') return '低落';
    return '在线';
  }

  static color(status?: string): string {
    if (status === 'busy') return '#C0573F';
    if (status === 'away') return '#E0B87F';
    if (status === 'study') return '#9CAF88';
    if (status === 'sad') return '#8A7D6E';
    return '#7D9268';
  }
}
```

## 9. 图片上传与高德定位整合

### 9.1 图片上传

真机上不能把 PhotoViewPicker 返回的 `photoUri` 当普通路径直接读。当前项目的 `/entry/src/main/ets/utils/UploadUtil.ets` 已经采用正确方向：先 `fileIo.openSync(uri)`，拷贝到 `ctx.cacheDir`，再 multipart 上传。

关键注意：

- 上传字段名统一为 `file`。
- 后端接口建议：`POST /api/upload/image`、`POST /api/upload/video`。
- 返回：`{ "code": 0, "msg": "ok", "data": { "url": "https://..." } }`
- 服务端需要允许 `jpg/jpeg/png/webp/heic/heif/avif/mp4/mov`。
- 如果服务端不能处理 HEIC，建议后端接收后转 JPG，或前端限制 picker 只选 JPEG/PNG。

### 9.2 定位

当前 `LocationUtil` 使用系统定位和反地理编码。如果你接入高德 SDK，建议前端返回统一结构：

```ts
export interface LocationSnapshot {
  latitude: number;
  longitude: number;
  label: string;   // 展示：例如 “万达广场”
  address: string; // 详情：例如 “北京市朝阳区...”
}
```

发布动态只存：

- `locationLabel`
- `address`
- `latitude`
- `longitude`

当前实现已经拆成两层：

- `PublishPage`：默认不显示位置，点击“所在位置”进入选择页。
- `LocationPickerPage`：可选“不显示位置”“实时定位”“50km 内附近位置”。
- `LocationUtil.searchNearby`：当前预留高德 Web 服务 Key；正式接入高德 HarmonyOS NEXT SDK 时，替换这里为 SDK 的 POI 周边检索，页面无需重写。

50km 规则放在工具层统一校验：`Const.AMAP_LOCATION_RADIUS = 50000`，无论用户从搜索列表、地图选点还是实时定位进入，都只允许选择当前位置 50km 内的位置。

列表只展示 `locationLabel`，详情页再展示完整 `address`。

## 10. 路由设计

`main_pages.json` 必须注册所有被 `router.pushUrl` 跳转的页面。当前建议：

```json
{
  "src": [
    "pages/Index",
    "view/auth/LoginPage",
    "view/auth/RegisterPage",
    "view/community/PostDetailPage",
    "view/community/PublishPage",
    "view/community/LocationPickerPage",
    "view/community/SearchPage",
    "view/community/UserPostsPage",
    "view/ai/ChatPage",
    "view/ai/HistoryPage",
    "view/message/AddFriendPage",
    "view/message/ChatRoomPage",
    "view/mine/SettingsPage",
    "view/mine/ProfileEditPage",
    "view/mine/MyPostsPage",
    "view/mine/MyLikesPage",
    "view/mine/MyCommentsPage"
  ]
}
```

页面传参示例：

```ts
router.pushUrl({
  url: 'view/community/PostDetailPage',
  params: { id: post.id, focusComment: 1 }
});

const params = router.getParams() as Record<string, number | string>;
const postId = params.id as number;
```

## 11. 解决“界面违和感”的实操清单

1. 所有一级页面背景统一 `bg_page`，列表项统一 `card_bg`。
2. 头像尺寸只保留两档：社区 `42`，消息/联系人 `48`。
3. 列表圆角少用：微信式列表不需要每行都做卡片，靠白底和分割线即可。
4. 按钮统一胶囊：高度 `36/40/44`，圆角等于高度一半。
5. 正文字号收敛到 `14/15/16`，不要混用 18 以上字号做普通内容。
6. 社区信息流卡片用 `14` 内边距，图片间距 `4`，卡片间距 `8`。
7. 聊天气泡左右最大宽度 `78%`，输入栏固定高 `60` 左右。
8. 数据库写操作后必须刷新：点赞后拉 detail，评论后拉 comments/detail，发帖后返回列表页并触发列表 refresh。
9. 搜索页、添加好友页、聊天页都要注册到 `main_pages.json`。
10. SSE 路由关闭 Nginx 缓冲，并在前端使用 `requestInStream`。
