export class Const {
  // 服务器地址 —— 部署后改这里
  static readonly BASE_URL: string = 'https://xsnbb.xyz/api';
  static readonly WS_URL: string   = 'wss://xsnbb.xyz/api/ws/im';
  // 高德 Web 服务 Key。正式接入 HarmonyOS NEXT 高德 SDK 后，可改由 SDK 查询 POI。
  static readonly AMAP_WEB_KEY: string = '';
  static readonly AMAP_LOCATION_RADIUS: number = 50000;

  static readonly TOKEN_KEY: string = 'app_token';
  static readonly REFRESH_KEY: string = 'app_refresh';
  static readonly USER_KEY: string = 'app_user';

  static readonly BIZ_MENTAL: string = 'mental';
  static readonly BIZ_STUDY: string = 'study';
  static readonly BIZ_GENERAL: string = 'general';

  /** AppStorage key：社区动态刷新信号。发帖成功后自增，社区页 @StorageProp 监听后自动刷新。 */
  static readonly FEED_REFRESH_KEY: string = 'feedRefreshTick';

  /** AppStorage key：消息/会话刷新信号。聊天页返回、已读变化后自增，消息页监听后自动刷新。 */
  static readonly MSG_REFRESH_KEY: string = 'msgRefreshTick';

  /** AppStorage key：当前登录用户，供资料/状态变更后响应式刷新。 */
  static readonly CURRENT_USER_KEY: string = 'currentUser';

  /** AppStorage key：AI 会话刷新信号。对话页返回后自增，AI 首页监听后刷新最近会话。 */
  static readonly AI_REFRESH_KEY: string = 'aiRefreshTick';
}
