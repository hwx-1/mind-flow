import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

export class LaunchNotice {
  private static readonly STORE_NAME: string = 'launch_state';
  private static readonly LAST_NOTICE_KEY: string = 'lastNoticeDate';

  private static todayKey(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = `${now.getMonth() + 1}`.padStart(2, '0');
    const day = `${now.getDate()}`.padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  static async showIfNeeded(ctx: common.UIAbilityContext): Promise<void> {
    try {
      const store = await preferences.getPreferences(ctx, LaunchNotice.STORE_NAME);
      const today = LaunchNotice.todayKey();
      const last = await store.get(LaunchNotice.LAST_NOTICE_KEY, '') as string;
      if (last === today) {
        return;
      }

      await store.put(LaunchNotice.LAST_NOTICE_KEY, today);
      await store.flush();

      AlertDialog.show({
        message: '欢迎使用心晴。当前版本已支持账号密码登录、验证码登录、AI 流式对话、发帖定位和个人资料编辑；微信/QQ 登录与部分后端能力正在接入中。',
        primaryButton: {
          value: '知道了',
          action: () => {}
        },
        secondaryButton: {
          value: '稍后查看',
          action: () => {}
        }
      });
    } catch (e) {
      console.error('LaunchNotice.showIfNeeded', JSON.stringify(e));
    }
  }
}
