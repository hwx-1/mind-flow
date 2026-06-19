/**
 * 公告弹窗的本地状态：记录用户对某条公告「不再显示」的截止时间（1 天）。
 * - 点击「我知道了」：不记录，下次进入仍弹；
 * - 点击「不再显示」：记录该公告 id 与截止时间(now+24h)，期间不再弹。
 */
export class AnnouncementStore {
  static readonly KEY_ID: string = 'annDismissId';
  static readonly KEY_UNTIL: string = 'annDismissUntil';
  private static readonly ONE_DAY_MS: number = 24 * 60 * 60 * 1000;

  /** 应用启动时登记持久化键，需在 EntryAbility.onCreate() 调用一次。 */
  static init(): void {
    PersistentStorage.persistProp(AnnouncementStore.KEY_ID, 0);
    PersistentStorage.persistProp(AnnouncementStore.KEY_UNTIL, 0);
  }

  /** 该公告当前是否应当弹出 */
  static shouldShow(id: number): boolean {
    const dismissId: number = AppStorage.get<number>(AnnouncementStore.KEY_ID) ?? 0;
    const until: number = AppStorage.get<number>(AnnouncementStore.KEY_UNTIL) ?? 0;
    if (id === dismissId && Date.now() < until) {
      return false;
    }
    return true;
  }

  /** 「不再显示」：屏蔽该公告 1 天 */
  static dismissForDay(id: number): void {
    AppStorage.setOrCreate<number>(AnnouncementStore.KEY_ID, id);
    AppStorage.setOrCreate<number>(AnnouncementStore.KEY_UNTIL, Date.now() + AnnouncementStore.ONE_DAY_MS);
  }
}
