import { promptAction, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { UserApi } from '../../api/Api';
import { Auth } from '../../store/Auth';
import { UserVo, UserUpdateReq } from '../../model/Models';
import { UploadUtil } from '../../utils/UploadUtil';
import { ProfileStatusUtil } from '../../utils/ProfileStatusUtil';

interface ProfileStatusOption {
  label: string;
  color: string;
  tint: string;
}

@Entry
@Component
struct ProfileEditPage {
  @StorageProp('themePrimary') themePrimary: string = '#D98E73';
  @State user: UserVo | null = null;
  @State uidText: string = '-';
  @State accountText: string = '-';
  @State nickname: string = '';
  @State bio: string = '';
  @State avatar: string = '';
  @State profileStatus: string = '在线';
  @State gender: number = 0;
  private ctx = getContext(this) as common.UIAbilityContext;
  private readonly statusOptions: ProfileStatusOption[] = [
    { label: '在线', color: ProfileStatusUtil.styleOf('在线').color, tint: ProfileStatusUtil.styleOf('在线').tint },
    { label: '忙碌', color: ProfileStatusUtil.styleOf('忙碌').color, tint: ProfileStatusUtil.styleOf('忙碌').tint },
    { label: '离开', color: ProfileStatusUtil.styleOf('离开').color, tint: ProfileStatusUtil.styleOf('离开').tint },
    { label: '勿扰', color: ProfileStatusUtil.styleOf('勿扰').color, tint: ProfileStatusUtil.styleOf('勿扰').tint },
    { label: '隐身', color: ProfileStatusUtil.styleOf('隐身').color, tint: ProfileStatusUtil.styleOf('隐身').tint }
  ];

  aboutToAppear(): void {
    this.loadProfile();
  }

  private syncUser(user: UserVo | null): void {
    this.user = user;
    this.uidText = String(user?.uid ?? user?.id ?? '-');
    this.accountText = user?.username || '-';
    this.nickname = user?.nickname || '';
    this.bio = user?.bio || '';
    this.avatar = user?.avatar || '';
    this.profileStatus = user?.profileStatus || '在线';
    this.gender = user?.gender || 0;
  }

  async loadProfile(): Promise<void> {
    try {
      const fresh = await UserApi.profile();
      this.syncUser(fresh);
      await Auth.save(Auth.getToken(), Auth.getRefresh(), fresh);
    } catch (e) {
      this.syncUser(Auth.getUser());
    }
  }

  async pickAvatar() {
    try {
      const uris = await UploadUtil.pickImages(1);
      if (uris.length === 0) return;
      promptAction.showToast({ message: '上传中...' });
      const url = await UploadUtil.upload(this.ctx, uris[0], 'image');
      this.avatar = url;
    } catch (e) {
      const err = e as Error;
      console.error(`avatar upload failed: ${err.message || 'unknown error'}`);
      promptAction.showToast({ message: err.message || '上传失败' });
    }
  }

  async save() {
    try {
      const req: UserUpdateReq = {
        nickname: this.nickname,
        bio: this.bio,
        avatar: this.avatar,
        profileStatus: this.profileStatus,
        gender: this.gender
      };
      await UserApi.update(req);
      const fresh = await UserApi.profile();
      this.syncUser(fresh);
      await Auth.save(Auth.getToken(), Auth.getRefresh(), fresh);
      promptAction.showToast({ message: '已保存' });
      router.back();
    } catch (e) {}
  }

  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left')).width(24).height(24)
          .onClick(() => router.back())
        Text('资料编辑').fontSize(17).fontWeight(FontWeight.Medium).layoutWeight(1).margin({ left: 12 })
        Text('保存').fontSize(15).fontColor(this.themePrimary)
          .onClick(() => this.save())
      }.width('100%').padding(14).backgroundColor($r('app.color.card_bg'))

      Column({ space: 12 }) {
          Row({ space: 12 }) {
            Image(this.avatar || $r('app.media.icon'))
              .width(64)
              .height(64)
              .borderRadius(32)
              .objectFit(ImageFit.Cover)
              .onClick(() => this.pickAvatar())
            Column({ space: 6 }) {
              Text(this.nickname || this.accountText)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_main'))
              Text(`UID ${this.uidText}`)
                .fontSize(12)
                .fontColor($r('app.color.text_sub'))
              Text(`账号 ${this.accountText}`)
                .fontSize(12)
                .fontColor($r('app.color.text_sub'))
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .padding(16)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(14)
          .onClick(() => this.pickAvatar())

          Column() {
            Text('昵称').fontSize(13).fontColor($r('app.color.text_sub')).width('100%')
            TextInput({ text: this.nickname }).height(40).margin({ top: 6 })
              .backgroundColor(Color.Transparent).padding(0)
              .onChange(v => this.nickname = v)
          }.padding(16).backgroundColor($r('app.color.card_bg')).borderRadius(14).alignItems(HorizontalAlign.Start)

          Column() {
            Text('一句话简介').fontSize(13).fontColor($r('app.color.text_sub')).width('100%')
            TextArea({ text: this.bio, placeholder: '介绍一下自己…' }).height(84).margin({ top: 6 })
              .backgroundColor(Color.Transparent).padding(0)
              .onChange(v => this.bio = v)
          }.padding(16).backgroundColor($r('app.color.card_bg')).borderRadius(14).alignItems(HorizontalAlign.Start)

          Column({ space: 12 }) {
            Row() {
              Text('当前状态').fontSize(14).layoutWeight(1)
              Text('所有人可见')
                .fontSize(12)
                .fontColor($r('app.color.text_sub'))
            }
            .width('100%')

            Row({ space: 8 }) {
              ForEach(this.statusOptions, (item: ProfileStatusOption) => {
                Text(item.label)
                  .fontSize(13)
                  .fontWeight(this.profileStatus === item.label ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor(this.profileStatus === item.label ? Color.White : item.color)
                  .height(32)
                  .padding({ left: 14, right: 14 })
                  .borderRadius(16)
                  .backgroundColor(this.profileStatus === item.label ? item.color : item.tint)
                  .onClick(() => this.profileStatus = item.label)
              }, (item: ProfileStatusOption) => item.label)
            }
            .width('100%')
          }
          .padding(16)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(14)
          .alignItems(HorizontalAlign.Start)

          Row() {
            Text('性别').fontSize(14).layoutWeight(1)
            Row({ space: 6 }) {
              ForEach(['未知', '男', '女'], (l: string, i: number) => {
                Text(l).fontSize(13)
                  .fontColor(this.gender === i ? Color.White : $r('app.color.text_sub'))
                  .backgroundColor(this.gender === i ? this.themePrimary : $r('app.color.bg_page'))
                  .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                  .borderRadius(14)
                  .onClick(() => this.gender = i)
              })
            }
          }.padding(16).backgroundColor($r('app.color.card_bg')).borderRadius(14)
      }
      .layoutWeight(1)
      .padding({ left: 12, right: 12, top: 0, bottom: 12 })
    }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
