import { promptAction, router } from '@kit.ArkUI';
import { AuthApi } from '../../api/Api';
import { Auth } from '../../store/Auth';
import { LaunchSplash } from '../common/LaunchSplash';

interface LoginModeItem {
  key: number;
  label: string;
}

@Entry
@Component
struct LoginPage {
  @StorageProp('themePrimary') themePrimary: string = '#D98E73';
  @StorageProp('themePrimaryLight') themePrimaryLight: string = '#F3ECE1';
  @State private mode: number = 0;
  @State private account: string = '';
  @State private password: string = '';
  @State private code: string = '';
  @State private sendingCode: boolean = false;
  @State private loggingIn: boolean = false;
  @State private showSplash: boolean = true;
  @State private acceptedTerms: boolean = false;

  private readonly modes: LoginModeItem[] = [
    { key: 0, label: '密码登录' },
    { key: 1, label: '验证码登录' }
  ];

  aboutToAppear(): void {
    setTimeout(() => this.dismissSplash(), 1800);
  }

  private dismissSplash(): void {
    if (!this.showSplash) {
      return;
    }
    this.showSplash = false;
  }

  private isPhone(value: string): boolean {
    return /^1\d{10}$/.test(value.trim());
  }

  private canUseCodeMode(): boolean {
    return this.isPhone(this.account);
  }

  async sendCode(): Promise<void> {
    const phone = this.account.trim();
    if (!this.isPhone(phone)) {
      promptAction.showToast({ message: '请输入正确的手机号' });
      return;
    }
    this.sendingCode = true;
    try {
      await AuthApi.sendCode(phone, 'login');
      promptAction.showToast({ message: '验证码已发送' });
    } catch (e) {
    } finally {
      this.sendingCode = false;
    }
  }

  async doLogin(): Promise<void> {
    if (!this.acceptedTerms) {
      promptAction.showToast({ message: '请先勾选并同意用户须知' });
      return;
    }

    const account = this.account.trim();
    if (!account) {
      promptAction.showToast({ message: this.mode === 0 ? '请输入账号或手机号' : '请输入手机号' });
      return;
    }

    this.loggingIn = true;
    try {
      const resp = this.mode === 0
        ? await AuthApi.loginByPassword(account, this.password)
        : await AuthApi.loginByCode(account, this.code);
      await Auth.save(resp.token, resp.refreshToken, resp.user);
      router.replaceUrl({ url: 'pages/Index' });
    } catch (e) {
    } finally {
      this.loggingIn = false;
    }
  }

  private async socialLogin(provider: string): Promise<void> {
    promptAction.showToast({ message: `${provider === 'wechat' ? '微信' : 'QQ'}登录暂未接入` });
  }

  private showTerms(): void {
    AlertDialog.show({
      title: '用户须知',
      message: '请遵守社区规范，理性交流，不发布违法违规、攻击辱骂、泄露隐私或可能伤害他人的内容。AI 咨询仅提供陪伴与参考，不能替代专业医疗诊断或治疗；如遇紧急心理危机，请及时联系身边可信的人或当地专业机构。',
      primaryButton: {
        value: '我知道了',
        action: () => {}
      }
    });
  }

  @Builder
  ModeTabs() {
    Row({ space: 10 }) {
      ForEach(this.modes, (item: LoginModeItem) => {
        Text(item.label)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.mode === item.key ? Color.White : $r('app.color.text_sub'))
          .height(32)
          .padding({ left: 14, right: 14 })
          .borderRadius(16)
          .backgroundColor(this.mode === item.key ? this.themePrimary : $r('app.color.bg_page'))
          .onClick(() => this.mode = item.key)
      }, (item: LoginModeItem) => item.key.toString())
    }
    .width('100%')
  }

  @Builder
  SocialButtons() {
    Column({ space: 10 }) {
      Text('其他登录方式')
        .fontSize(12)
        .fontColor($r('app.color.text_sub'))
        .width('100%')
      Row({ space: 10 }) {
        Button('微信登录')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(this.themePrimaryLight)
          .fontColor(this.themePrimary)
          .borderRadius(22)
          .onClick(() => this.socialLogin('wechat'))
        Button('QQ 登录')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(this.themePrimaryLight)
          .fontColor($r('app.color.accent'))
          .borderRadius(22)
          .onClick(() => this.socialLogin('qq'))
      }
    }
  }

  build() {
    Stack() {
      Column() {
        Column() {
          Image($r('app.media.icon'))
            .width(72)
            .height(72)
            .margin({ top: 88, bottom: 18 })
          Text('心晴')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_main'))
          Text('AI 心理健康助手')
            .fontSize(13)
            .fontColor($r('app.color.text_sub'))
            .margin({ top: 6 })
        }
        .width('100%')

        Scroll() {
          Column({ space: 14 }) {
            this.ModeTabs()

            TextInput({ placeholder: this.mode === 0 ? '账号 / 手机号' : '手机号', text: this.account })
              .height(48)
              .backgroundColor(this.themePrimaryLight)
              .borderRadius(14)
              .padding({ left: 16, right: 16 })
              .type(this.mode === 1 ? InputType.PhoneNumber : InputType.Normal)
              .onChange((value: string) => this.account = value)

            if (this.mode === 0) {
              TextInput({ placeholder: '密码', text: this.password })
                .type(InputType.Password)
                .height(48)
                .backgroundColor(this.themePrimaryLight)
                .borderRadius(14)
                .padding({ left: 16, right: 16 })
                .onChange((value: string) => this.password = value)
            } else {
              Row({ space: 8 }) {
                TextInput({ placeholder: '验证码', text: this.code })
                  .layoutWeight(1)
                  .height(48)
                  .backgroundColor(this.themePrimaryLight)
                  .borderRadius(14)
                  .padding({ left: 16, right: 16 })
                  .onChange((value: string) => this.code = value)
                Button(this.sendingCode ? '发送中…' : '获取验证码')
                  .height(48)
                  .padding({ left: 14, right: 14 })
                  .borderRadius(14)
                  .backgroundColor(this.themePrimaryLight)
                  .fontColor(this.themePrimary)
                  .enabled(!this.sendingCode && this.canUseCodeMode())
                  .onClick(() => this.sendCode())
              }
            }

            Button(this.loggingIn ? '登录中…' : '登 录')
              .width('100%')
              .height(48)
              .borderRadius(24)
              .backgroundColor(this.themePrimary)
              .enabled(!this.loggingIn && (this.mode === 0 ? this.account.trim().length > 0 && this.password.length > 0 : this.account.trim().length > 0 && this.code.length > 0))
              .onClick(() => this.doLogin())

            Row({ space: 6 }) {
              Checkbox({ name: 'loginTerms' })
                .select(this.acceptedTerms)
                .selectedColor(this.themePrimary)
                .onChange((value: boolean) => this.acceptedTerms = value)
              Text('我已阅读并同意')
                .fontSize(12)
                .fontColor($r('app.color.text_sub'))
              Text('用户须知')
                .fontSize(12)
                .fontColor(this.themePrimary)
                .onClick(() => this.showTerms())
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            Row() {
              Text('还没有账号？')
                .fontSize(13)
                .fontColor($r('app.color.text_sub'))
              Text('立即注册')
                .fontSize(13)
                .fontColor(this.themePrimary)
                .margin({ left: 4 })
                .onClick(() => router.pushUrl({ url: 'view/auth/RegisterPage' }))
            }
            .justifyContent(FlexAlign.Center)
            .width('100%')
            .margin({ top: 2 })

            this.SocialButtons()
          }
          .width('100%')
          .padding({ left: 24, right: 24, bottom: 28 })
        }
        .edgeEffect(EdgeEffect.Spring)
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.bg_page'))

      if (this.showSplash) {
        LaunchSplash({ onSkip: () => this.dismissSplash() })
          .zIndex(99)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
