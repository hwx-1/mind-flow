import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Const } from '../constants/Const';
import { UserVo } from '../model/Models';

/** AppStorage 中当前登录用户的 key，供 @StorageLink/@StorageProp 响应式绑定。 */
export const CURRENT_USER_KEY: string = 'currentUser';

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
      this.publishUser();
    } catch (e) {
      console.error('Auth.restore', JSON.stringify(e));
    }
  }

  /** 把当前用户同步到 AppStorage，触发所有 @StorageLink/@StorageProp 绑定刷新。 */
  private publishUser(): void {
    if (AppStorage.has(CURRENT_USER_KEY)) {
      AppStorage.set<UserVo | null>(CURRENT_USER_KEY, this.user);
    } else {
      AppStorage.setOrCreate<UserVo | null>(CURRENT_USER_KEY, this.user);
    }
  }

  async save(token: string, refresh: string, user: UserVo): Promise<void> {
    this.token = token;
    this.refreshToken = refresh;
    this.user = user;
    this.publishUser();
    if (this.store) {
      await this.store.put(Const.TOKEN_KEY, token);
      await this.store.put(Const.REFRESH_KEY, refresh);
      await this.store.put(Const.USER_KEY, JSON.stringify(user));
      await this.store.flush();
    }
  }

  async clear(): Promise<void> {
    this.token = '';
    this.refreshToken = '';
    this.user = null;
    this.publishUser();
    if (this.store) {
      await this.store.clear();
      await this.store.flush();
    }
  }

  getToken(): string { return this.token; }
  getRefresh(): string { return this.refreshToken; }
  getUser(): UserVo | null { return this.user; }
  isLogin(): boolean { return this.token.length > 0; }
}

export const Auth = new AuthStore();
