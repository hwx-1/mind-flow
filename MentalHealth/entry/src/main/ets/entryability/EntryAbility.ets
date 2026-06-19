import { UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { Auth } from '../store/Auth';
import { AppTheme } from '../store/AppTheme';
import { AnnouncementStore } from '../store/AnnouncementStore';

export default class EntryAbility extends UIAbility {
  onCreate(): void {
    // 登记并恢复用户自定义主题色（重启后仍生效，全局响应式）
    AppTheme.init();
    // 登记公告「不再显示」持久化状态
    AnnouncementStore.init();
  }

  onWindowStageCreate(stage: window.WindowStage): void {
    Auth.restore(this.context).then((): void => {
      const route = Auth.isLogin() ? 'pages/Index' : 'view/auth/LoginPage';
      stage.loadContent(route, (err: BusinessError): void => {
        if (err.code) console.error('loadContent fail', JSON.stringify(err));
      });
    });
  }
}
