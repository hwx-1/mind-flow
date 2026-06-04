import preferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';
import { Const } from '../constants/Const';
import { UserVo } from '../model/Models';

class AuthStore {
  private store: preferences.Preferences | null = null;
  private token: string = '';
  private refreshToken: string = '';
  private user: UserVo | null = null;

  async restore(ctx: common.UIAbilityContext): Promise<void> {
    try {
      this.store = await preferences.getPreferences(ctx, 'auth');
      this.token = await this.store.get(Const.TOKEN_KEY, '') as string;
      this.refreshToken = await this.store.get(Const.REFRESH_KEY, '') as string;
      const u = await this.store.get(Const.USER_KEY, '') as string;
      this.user = u ? JSON.parse(u) as UserVo : null;
    } catch (e) {
      console.error('Auth.restore', JSON.stringify(e));
    }
  }

  async save(token: string, refresh: string, user: UserVo): Promise<void> {
    this.token = token; this.refreshToken = refresh; this.user = user;
    if (this.store) {
      await this.store.put(Const.TOKEN_KEY, token);
      await this.store.put(Const.REFRESH_KEY, refresh);
      await this.store.put(Const.USER_KEY, JSON.stringify(user));
      await this.store.flush();
    }
  }

  async clear(): Promise<void> {
    this.token = ''; this.refreshToken = ''; this.user = null;
    if (this.store) {
      await this.store.clear();
      await this.store.flush();
    }
  }

  getToken(): string { return this.token; }
  getRefresh(): string { return this.refreshToken; }
  getUser(): UserVo | null { return this.user; }
  isLogin(): boolean { return !!this.token; }
}

export const Auth = new AuthStore();
