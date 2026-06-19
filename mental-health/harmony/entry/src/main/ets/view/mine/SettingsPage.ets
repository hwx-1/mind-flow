import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { Auth } from '../../store/Auth';
import { UserApi } from '../../api/Api';

@Entry
@Component
struct SettingsPage {
  @State oldPwd: string = '';
  @State newPwd: string = '';
  @State showChangePwd: boolean = false;

  async logout() {
    AlertDialog.show({
      message: '确定退出登录？',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '退出', fontColor: $r('app.color.danger'),
        action: async () => {
          await Auth.clear();
          router.replaceUrl({ url: 'view/auth/LoginPage' });
        }
      }
    });
  }

  async changePwd() {
    if (this.oldPwd.length < 6 || this.newPwd.length < 6) {
      promptAction.showToast({ message: '密码不少于 6 位' }); return;
    }
    try {
      await UserApi.changePassword(this.oldPwd, this.newPwd);
      promptAction.showToast({ message: '密码已修改，请重新登录' });
      await Auth.clear();
      router.replaceUrl({ url: 'view/auth/LoginPage' });
    } catch (e) {}
  }

  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left')).width(24).height(24)
          .onClick(() => router.back())
        Text('设置').fontSize(17).fontWeight(FontWeight.Medium).margin({ left: 12 })
      }.width('100%').padding(14).backgroundColor(Color.White)

      Column({ space: 10 }) {
        Row() {
          Text('修改密码').fontSize(15).layoutWeight(1)
          Image($r('sys.media.ohos_ic_public_arrow_right'))
            .width(16).height(16).fillColor($r('app.color.text_sub'))
        }.width('100%').padding(16).backgroundColor(Color.White).borderRadius(10)
          .onClick(() => this.showChangePwd = !this.showChangePwd)

        if (this.showChangePwd) {
          Column({ space: 10 }) {
            TextInput({ placeholder: '原密码' }).type(InputType.Password)
              .height(44).backgroundColor($r('app.color.bg_page'))
              .borderRadius(8).padding({ left: 12, right: 12 })
              .onChange(v => this.oldPwd = v)
            TextInput({ placeholder: '新密码' }).type(InputType.Password)
              .height(44).backgroundColor($r('app.color.bg_page'))
              .borderRadius(8).padding({ left: 12, right: 12 })
              .onChange(v => this.newPwd = v)
            Button('提交').width('100%').height(40)
              .backgroundColor($r('app.color.primary'))
              .onClick(() => this.changePwd())
          }.padding(16).backgroundColor(Color.White).borderRadius(10)
        }

        Row() {
          Text('关于').fontSize(15).layoutWeight(1)
          Text('v1.0.0').fontSize(13).fontColor($r('app.color.text_sub'))
        }.width('100%').padding(16).backgroundColor(Color.White).borderRadius(10)

        Button('退出登录').width('100%').height(44)
          .backgroundColor(Color.White).fontColor($r('app.color.danger'))
          .borderRadius(10).margin({ top: 20 })
          .onClick(() => this.logout())
      }.padding(12)
    }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
