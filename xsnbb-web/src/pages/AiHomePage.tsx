import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { AiApi } from '@/api';
import type { AiSessionVo } from '@/types';
import { useToast } from '@/components/Toast';
import { ApiError } from '@/api/http';

const BIZS = [
  { key: 'mental',  name: '心理咨询', desc: '聊聊心事,我在听',         color: 'from-terracotta to-blush',      icon: '🫂' },
  { key: 'study',   name: '学习辅导', desc: '拆解问题,陪你一起想清楚', color: 'from-sage to-sage-deep',         icon: '📚' },
  { key: 'general', name: '综合聊天', desc: '随便聊聊,放松一下',       color: 'from-gold to-clay',              icon: '🌸' },
] as const;

export function AiHomePage() {
  const [sessions, setSessions] = useState<AiSessionVo[]>([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();
  const toast = useToast((s) => s.push);

  useEffect(() => {
    AiApi.sessions()
      .then(setSessions)
      .catch((e) => toast((e as ApiError).message, 'error'))
      .finally(() => setLoading(false));
  }, []);

  async function startBiz(biz: typeof BIZS[number]) {
    try {
      const s = await AiApi.createSession(biz.key, biz.name);
      navigate(`/ai/chat/${s.id}`);
    } catch (e) {
      toast((e as ApiError).message, 'error');
    }
  }

  async function deleteSession(id: number, ev: React.MouseEvent) {
    ev.stopPropagation();
    if (!confirm('删除这个会话?')) return;
    try {
      await AiApi.deleteSession(id);
      setSessions(sessions.filter((s) => s.id !== id));
    } catch (e) {
      toast((e as ApiError).message, 'error');
    }
  }

  return (
    <div className="space-y-6">
      <div>
        <h2 className="font-serif text-2xl mb-1">AI 咨询</h2>
        <p className="text-sm text-ink-soft">挑一个方向开始,或继续之前的对话</p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        {BIZS.map((b) => (
          <button
            key={b.key}
            onClick={() => startBiz(b)}
            className={`p-6 rounded-2xl bg-gradient-to-br ${b.color} text-white text-left hover:-translate-y-1 shadow-soft hover:shadow-soft-lg transition`}
          >
            <div className="text-4xl mb-3">{b.icon}</div>
            <div className="font-serif text-xl mb-1">{b.name}</div>
            <div className="text-sm opacity-90">{b.desc}</div>
          </button>
        ))}
      </div>

      <div className="bg-paper rounded-2xl border border-line shadow-soft">
        <header className="p-5 border-b border-line">
          <h3 className="font-serif text-lg">最近的对话</h3>
        </header>
        {loading ? (
          <div className="py-12 text-center text-ink-soft text-sm">加载中...</div>
        ) : sessions.length === 0 ? (
          <div className="py-12 text-center text-ink-soft text-sm">还没有对话,点上面开始一个吧</div>
        ) : (
          <ul className="divide-y divide-line">
            {sessions.map((s) => (
              <li
                key={s.id}
                onClick={() => navigate(`/ai/chat/${s.id}`)}
                className="p-4 px-5 flex items-center gap-3 hover:bg-cream-deep cursor-pointer transition"
              >
                <div className="text-2xl">{BIZS.find((b) => b.key === s.business)?.icon || '💬'}</div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="font-medium">{s.title || s.business}</span>
                    <span className="text-[11px] bg-gold/15 text-clay px-2 py-0.5 rounded-full">
                      {BIZS.find((b) => b.key === s.business)?.name || s.business}
                    </span>
                  </div>
                  <div className="text-xs text-ink-soft mt-0.5 truncate">{s.lastMsg || '— 还没消息 —'}</div>
                </div>
                <button
                  onClick={(e) => deleteSession(s.id, e)}
                  className="text-xs text-ink-soft hover:text-danger transition"
                >
                  删除
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
