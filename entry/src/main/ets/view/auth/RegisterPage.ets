import { promptAction, router } from '@kit.ArkUI';
import { AuthApi } from '../../api/Api';
import { Auth } from '../../store/Auth';

@Entry
@Component
struct RegisterPage {
  @StorageProp('themePrimary') themePrimary: string = '#D98E73';
  @StorageProp('themePrimaryLight') themePrimaryLight: string = '#F3ECE1';
  @State username: string = '';
  @State phone: string = '';
  @State password: string = '';
  @State code: string = '';
  @State sending: boolean = false;
  @State submitting: boolean = false;

  async sendCode() {
    if (!/^1\d{10}$/.test(this.phone)) {
      promptAction.showToast({ message: '请输入正确手机号' }); return;
    }
    this.sending = true;
    try {
      await AuthApi.sendCode(this.phone, 'register');
      promptAction.showToast({ message: '验证码已发送' });
    } catch (e) {} finally { this.sending = false; }
  }

  async submit() {
    if (!this.username || !this.password || !this.phone) {
      promptAction.showToast({ message: '请填写完整' }); return;
    }
    if (this.password.length < 6) {
      promptAction.showToast({ message: '密码不少于 6 位' }); return;
    }
    this.submitting = true;
    try {
      const r = await AuthApi.register(this.username, this.password, this.phone, this.code);
      await Auth.save(r.token, r.refreshToken, r.user);
      router.replaceUrl({ url: 'pages/Index' });
    } catch (e) {} finally { this.submitting = false; }
  }

  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left')).width(24).height(24)
          .onClick(() => router.back())
        Text('注册').fontSize(18).fontWeight(FontWeight.Medium).margin({ left: 12 })
      }.width('100%').padding({ left: 16, top: 16, bottom: 12 })

      Column({ space: 14 }) {
        TextInput({ placeholder: '用户名（3-20 位）', text: this.username })
          .height(50).backgroundColor(this.themePrimaryLight)
          .borderRadius(14).padding({ left: 16, right: 16 })
          .onChange(v => this.username = v)
        TextInput({ placeholder: '手机号', text: this.phone })
          .type(InputType.PhoneNumber).height(50)
          .backgroundColor(this.themePrimaryLight)
          .borderRadius(14).padding({ left: 16, right: 16 })
          .onChange(v => this.phone = v)
        Row({ space: 8 }) {
          TextInput({ placeholder: '验证码', text: this.code })
            .height(50).layoutWeight(1)
            .backgroundColor(this.themePrimaryLight)
            .borderRadius(14).padding({ left: 16, right: 16 })
            .onChange(v => this.code = v)
          Button(this.sending ? '发送中' : '获取验证码')
            .height(50).fontSize(13)
            .backgroundColor(this.themePrimaryLight)
            .fontColor(this.themePrimary)
            .enabled(!this.sending)
            .onClick(() => this.sendCode())
        }
        TextInput({ placeholder: '密码（不少于 6 位）', text: this.password })
          .type(InputType.Password).height(50)
          .backgroundColor(this.themePrimaryLight)
          .borderRadius(14).padding({ left: 16, right: 16 })
          .onChange(v => this.password = v)

        Button(this.submitting ? '注册中…' : '注 册')
          .width('100%').height(48).borderRadius(24)
          .backgroundColor(this.themePrimary)
          .enabled(!this.submitting)
          .onClick(() => this.submit())
          .margin({ top: 12 })
      }.padding({ left: 24, right: 24, top: 24 })
    }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
