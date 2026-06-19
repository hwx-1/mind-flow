/**
 * AppTheme —— 全局主题色仓库（用户可在「设置」自定义 RGB 主色）。
 *
 * 机制：
 *  - 主色持久化在 PersistentStorage（重启后仍生效），并镜像到 AppStorage 供响应式读取；
 *  - 各页面用 @StorageProp('themePrimary') / @StorageProp('themePrimaryLight') 订阅，
 *    一处修改，全局所有布局实时刷新；
 *  - primaryLight（浅色衬底）由主色自动推导，无需用户单独设置。
 *
 * 颜色统一使用 '#RRGGBB' 字符串（ArkUI ResourceColor 兼容）。
 */

export interface Rgb {
  r: number;
  g: number;
  b: number;
}

export class AppTheme {
  /** AppStorage / PersistentStorage 键名（与各页面 @StorageProp 一致） */
  static readonly KEY_PRIMARY: string = 'themePrimary';
  static readonly KEY_PRIMARY_LIGHT: string = 'themePrimaryLight';

  /** 默认主色（与原资源 app.color.primary 对齐：赭土色） */
  static readonly DEFAULT_PRIMARY: string = '#D98E73';
  static readonly DEFAULT_PRIMARY_LIGHT: string = '#F3ECE1';

  /** 浅色衬底的混白比例（0~1，越大越浅） */
  private static readonly LIGHT_MIX: number = 0.86;

  /**
   * 应用启动时调用：登记持久化键并把浅色衬底同步到 AppStorage。
   * 需在 EntryAbility.onCreate() 中调用一次。
   */
  static init(): void {
    PersistentStorage.persistProp(AppTheme.KEY_PRIMARY, AppTheme.DEFAULT_PRIMARY);
    const primary: string = AppTheme.current();
    AppStorage.setOrCreate<string>(AppTheme.KEY_PRIMARY_LIGHT, AppTheme.lightOf(primary));
  }

  /** 当前主色（#RRGGBB） */
  static current(): string {
    const v: string | undefined = AppStorage.get<string>(AppTheme.KEY_PRIMARY);
    return (v !== undefined && v.length > 0) ? v : AppTheme.DEFAULT_PRIMARY;
  }

  /** 当前主色的 RGB 分量 */
  static currentRgb(): Rgb {
    return AppTheme.hexToRgb(AppTheme.current());
  }

  /** 设置主色（十六进制 #RRGGBB），自动持久化并刷新浅色衬底 */
  static setColor(hex: string): void {
    const norm: string = AppTheme.normalize(hex);
    AppStorage.setOrCreate<string>(AppTheme.KEY_PRIMARY, norm);
    AppStorage.setOrCreate<string>(AppTheme.KEY_PRIMARY_LIGHT, AppTheme.lightOf(norm));
  }

  /** 设置主色（RGB 分量，0~255） */
  static setRgb(r: number, g: number, b: number): void {
    AppTheme.setColor(AppTheme.rgbToHex(r, g, b));
  }

  /** 恢复默认主色 */
  static reset(): void {
    AppTheme.setColor(AppTheme.DEFAULT_PRIMARY);
  }

  /** 由主色推导浅色衬底（与白色混合） */
  static lightOf(hex: string): string {
    const c: Rgb = AppTheme.hexToRgb(hex);
    const mix = (x: number): number => Math.round(x + (255 - x) * AppTheme.LIGHT_MIX);
    return AppTheme.rgbToHex(mix(c.r), mix(c.g), mix(c.b));
  }

  /** RGB -> #RRGGBB */
  static rgbToHex(r: number, g: number, b: number): string {
    const h = (x: number): string => {
      const v: number = AppTheme.clamp(Math.round(x));
      const s: string = v.toString(16).toUpperCase();
      return s.length === 1 ? '0' + s : s;
    };
    return `#${h(r)}${h(g)}${h(b)}`;
  }

  /** #RGB / #RRGGBB / #AARRGGBB -> RGB（取后 6 位） */
  static hexToRgb(hex: string): Rgb {
    let s: string = hex.trim();
    if (s.startsWith('#')) {
      s = s.substring(1);
    }
    if (s.length === 3) {
      const a: string = s.charAt(0);
      const b2: string = s.charAt(1);
      const c2: string = s.charAt(2);
      s = `${a}${a}${b2}${b2}${c2}${c2}`;
    }
    if (s.length === 8) {
      s = s.substring(2); // 去掉 AA
    }
    if (s.length !== 6) {
      const d: Rgb = AppTheme.hexToRgb(AppTheme.DEFAULT_PRIMARY);
      return d;
    }
    const r: number = parseInt(s.substring(0, 2), 16);
    const g: number = parseInt(s.substring(2, 4), 16);
    const b: number = parseInt(s.substring(4, 6), 16);
    return { r: AppTheme.clamp(r), g: AppTheme.clamp(g), b: AppTheme.clamp(b) };
  }

  /** 校验并规整为 #RRGGBB；非法则回退默认色 */
  static normalize(hex: string): string {
    const rgb: Rgb = AppTheme.hexToRgb(hex);
    return AppTheme.rgbToHex(rgb.r, rgb.g, rgb.b);
  }

  /** 是否合法十六进制颜色 */
  static isValidHex(hex: string): boolean {
    return /^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(hex.trim());
  }

  private static clamp(x: number): number {
    if (Number.isNaN(x)) {
      return 0;
    }
    return x < 0 ? 0 : (x > 255 ? 255 : x);
  }
}
