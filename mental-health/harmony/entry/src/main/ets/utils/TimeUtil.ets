export class TimeUtil {
  static fromNow(iso?: string): string {
    if (!iso) return '';
    const t = new Date(iso.replace(' ', 'T')).getTime();
    if (isNaN(t)) return iso;
    const diff = (Date.now() - t) / 1000;
    if (diff < 60) return '刚刚';
    if (diff < 3600) return `${Math.floor(diff / 60)} 分钟前`;
    if (diff < 86400) return `${Math.floor(diff / 3600)} 小时前`;
    if (diff < 86400 * 7) return `${Math.floor(diff / 86400)} 天前`;
    return iso.substring(0, 10);
  }
}
