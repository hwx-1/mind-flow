import { useEffect, useState } from 'react';
import { AnnouncementApi } from '@/api';
import { useAuth } from '@/store/auth';
import type { AnnouncementVo } from '@/types';

const KEY_ID = 'xsnbb-ann-dismiss-id';
const KEY_UNTIL = 'xsnbb-ann-dismiss-until';
const ONE_DAY = 24 * 60 * 60 * 1000;

function shouldShow(id: number): boolean {
  const did = Number(localStorage.getItem(KEY_ID) || '0');
  const until = Number(localStorage.getItem(KEY_UNTIL) || '0');
  return !(id === did && Date.now() < until);
}

/**
 * 进入网站后的公告弹窗（与 App 端一致）：
 *  - 「我知道了」：仅关闭，下次进入仍弹；
 *  - 「不再显示」：屏蔽该公告 1 天。
 */
export function AnnouncementModal() {
  const isLogin = useAuth((s) => s.isLogin)();
  const [ann, setAnn] = useState<AnnouncementVo | null>(null);

  useEffect(() => {
    if (!isLogin) return;
    let alive = true;
    AnnouncementApi.latest()
      .then((a) => {
        if (alive && a && a.content && shouldShow(a.id)) setAnn(a);
      })
      .catch(() => {});
    return () => { alive = false; };
  }, [isLogin]);

  if (!ann) return null;

  const close = () => setAnn(null);
  const neverDay = () => {
    localStorage.setItem(KEY_ID, String(ann.id));
    localStorage.setItem(KEY_UNTIL, String(Date.now() + ONE_DAY));
    close();
  };

  return (
    <div className="fixed inset-0 z-[400] flex items-center justify-center bg-ink/40 backdrop-blur-sm px-4">
      <div className="w-full max-w-md bg-paper rounded-2xl shadow-soft-lg overflow-hidden">
        <div className="flex items-center justify-center gap-2 pt-6 pb-3">
          <span className="text-terracotta text-lg">📢</span>
          <h3 className="font-serif text-xl text-ink">{ann.title || '公告'}</h3>
        </div>
        <div className="px-6 max-h-[55vh] overflow-y-auto">
          <p className="text-[15px] leading-7 text-ink whitespace-pre-wrap">{ann.content}</p>
        </div>
        <div className="flex border-t border-line mt-5">
          <button
            onClick={neverDay}
            className="flex-1 py-3.5 text-sm text-ink-soft hover:bg-cream-deep/60 transition"
          >
            不再显示
          </button>
          <div className="w-px bg-line" />
          <button
            onClick={close}
            className="flex-1 py-3.5 text-sm font-medium text-terracotta-deep hover:bg-cream-deep/60 transition"
          >
            我知道了
          </button>
        </div>
      </div>
    </div>
  );
}
