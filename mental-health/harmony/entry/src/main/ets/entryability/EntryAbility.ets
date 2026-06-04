import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { Auth } from '../store/Auth';

export default class EntryAbility extends UIAbility {
  onCreate(): void {}

  onWindowStageCreate(stage: window.WindowStage): void {
    Auth.restore(this.context);
    const route = Auth.isLogin() ? 'pages/Index' : 'view/auth/LoginPage';
    stage.loadContent(route, (err) => {
      if (err.code) console.error('loadContent fail', JSON.stringify(err));
    });
  }
}
