export class Const {
  // 备案前临时方案：用 IP + 8080
  static readonly BASE_URL: string = 'http://39.96.36.94:8080/api';
  static readonly WS_URL: string   = 'ws://39.96.36.94:8080/api/ws/im';

  static readonly TOKEN_KEY: string = 'app_token';
  static readonly REFRESH_KEY: string = 'app_refresh';
  static readonly USER_KEY: string = 'app_user';

  static readonly BIZ_MENTAL: string = 'mental';
  static readonly BIZ_STUDY: string = 'study';
  static readonly BIZ_GENERAL: string = 'general';
}