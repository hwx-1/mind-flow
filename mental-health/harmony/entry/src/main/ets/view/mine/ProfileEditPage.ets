import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { common } from '@kit.AbilityKit';
import { UserApi } from '../../api/Api';
import { Auth } from '../../store/Auth';
import { UserVo } from '../../model/Models';
import { UploadUtil } from '../../utils/UploadUtil';

@Entry
@Component
struct ProfileEditPage {
  @State user: UserVo | null = null;
  @State nickname: string = '';
  @State bio: string = '';
  @State avatar: string = '';
  @State gender: number = 0;
  private ctx = getContext(this) as common.UIAbilityContext;

  aboutToAppear(): void {
    this.user = Auth.getUser();
    if (this.user) {
      this.nickname = this.user.nickname || '';
      this.bio = this.user.bio || '';
      this.avatar = this.user.avatar || '';
      this.gender = this.user.gender || 0;
    }
  }

  async pickAvatar() {
    try {
      const uris = await UploadUtil.pickImages(1);
      if (uris.length === 0) return;
      promptAction.showToast({ message: '上传中...' });
      const url = await UploadUtil.upload(this.ctx, uris[0], 'image');
      this.avatar = url;
    } catch (e) { promptAction.showToast({ message: '上传失败' }); }
  }

  async save() {
    try {
      await UserApi.update({
        nickname: this.nickname,
        bio: this.bio,
        avatar: this.avatar,
        gender: this.gender
      });
      const fresh = await UserApi.profile();
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
        Text('保存').fontSize(15).fontColor($r('app.color.primary'))
          .onClick(() => this.save())
      }.width('100%').padding(14).backgroundColor(Color.White)

      Column({ space: 12 }) {
        Row() {
          Text('头像').fontSize(14).layoutWeight(1)
          Image(this.avatar || $r('app.media.icon')).width(56).height(56).borderRadius(28)
        }.padding(16).backgroundColor(Color.White).borderRadius(10)
          .onClick(() => this.pickAvatar())

        Column() {
          Text('昵称').fontSize(13).fontColor($r('app.color.text_sub')).width('100%')
          TextInput({ text: this.nickname }).height(40).margin({ top: 6 })
            .backgroundColor(Color.Transparent).padding(0)
            .onChange(v => this.nickname = v)
        }.padding(16).backgroundColor(Color.White).borderRadius(10).alignItems(HorizontalAlign.Start)

        Column() {
          Text('一句话简介').fontSize(13).fontColor($r('app.color.text_sub')).width('100%')
          TextArea({ text: this.bio, placeholder: '介绍一下自己…' }).height(80).margin({ top: 6 })
            .backgroundColor(Color.Transparent).padding(0)
            .onChange(v => this.bio = v)
        }.padding(16).backgroundColor(Color.White).borderRadius(10).alignItems(HorizontalAlign.Start)

        Row() {
          Text('性别').fontSize(14).layoutWeight(1)
          Row({ space: 6 }) {
            ForEach(['未知', '男', '女'], (l: string, i: number) => {
              Text(l).fontSize(13)
                .fontColor(this.gender === i ? Color.White : $r('app.color.text_sub'))
                .backgroundColor(this.gender === i ? $r('app.color.primary') : $r('app.color.bg_page'))
                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                .borderRadius(12)
                .onClick(() => this.gender = i)
            })
          }
        }.padding(16).backgroundColor(Color.White).borderRadius(10)
      }.padding(12)
    }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
