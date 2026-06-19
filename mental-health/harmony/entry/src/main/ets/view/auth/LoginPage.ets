import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AuthApi } from '../../api/Api';
import { Auth } from '../../store/Auth';

@Entry
@Component
struct LoginPage {
  @State account: string = '';
  @State password: string = '';
  @State loading: boolean = false;

  async doLogin() {
    if (!this.account || !this.password) {
      promptAction.showToast({ message: '请输入账号和密码' }); return;
    }
    this.loading = true;
    try {
      const r = await AuthApi.login(this.account, this.password);
      await Auth.save(r.token, r.refreshToken, r.user);
      router.replaceUrl({ url: 'pages/Index' });
    } catch (e) {} finally { this.loading = false; }
  }

  build() {
    Column() {
      Column() {
        Image($r('app.media.icon')).width(72).height(72).margin({ top: 96, bottom: 20 })
        Text('心晴').fontSize(28).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_main'))
        Text('AI 心理健康助手').fontSize(13).fontColor($r('app.color.text_sub')).margin({ top: 6 })
      }

      Column({ space: 14 }) {
        TextInput({ placeholder: '用户名 / 手机号', text: this.account })
          .height(50).backgroundColor($r('app.color.primary_light'))
          .borderRadius(12).padding({ left: 16, right: 16 })
          .onChange(v => this.account = v)
        TextInput({ placeholder: '密码', text: this.password })
          .type(InputType.Password).height(50)
          .backgroundColor($r('app.color.primary_light'))
          .borderRadius(12).padding({ left: 16, right: 16 })
          .onChange(v => this.password = v)

        Button(this.loading ? '登录中…' : '登 录')
          .width('100%').height(48).borderRadius(24)
          .backgroundColor($r('app.color.primary'))
          .enabled(!this.loading)
          .onClick(() => this.doLogin())

        Row() {
          Text('还没有账号？').fontSize(13).fontColor($r('app.color.text_sub'))
          Text('立即注册').fontSize(13).fontColor($r('app.color.primary'))
            .onClick(() => router.pushUrl({ url: 'view/auth/RegisterPage' }))
        }.justifyContent(FlexAlign.Center).width('100%').margin({ top: 8 })
      }.padding({ left: 24, right: 24, top: 36 })
    }.width('100%').height('100%').backgroundColor(Color.White)
  }
}
