import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { UserApi } from '@/api';
import type { FriendRequestVo } from '@/types';
import { Avatar } from '@/components/Avatar';
import { useToast } from '@/components/Toast';
import { ApiError } from '@/api/http';

export function FriendRequestsPage() {
  const [list, setList] = useState<FriendRequestVo[]>([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();
  const toast = useToast((s) => s.push);

  useEffect(() => { refresh(); }, []);

  async function refresh() {
    setLoading(true);
    try {
      setList(await UserApi.friendRequests() || []);
    } catch (e) {
      toast((e as ApiError).message, 'error');
    } finally {
      setLoading(false);
    }
  }

  async function accept(id: number) {
    try {
      await UserApi.acceptFriend(id);
      toast('已通过', 'ok');
      refresh();
    } catch (e) {
      toast((e as ApiError).message, 'error');
    }
  }

  return (
    <div className="max-w-xl mx-auto">
      <div className="flex items-center gap-3 mb-5">
        <button onClick={() => navigate(-1)} className="text-sm text-ink-soft hover:text-ink">←</button>
        <h1 className="font-serif text-xl">好友申请</h1>
      </div>

      {loading ? (
        <div className="text-center py-12 text-ink-soft">加载中...</div>
      ) : list.length === 0 ? (
        <div className="text-center py-12 text-ink-soft text-sm">暂无好友申请</div>
      ) : (
        <div className="grid gap-3">
          {list.map((r) => (
            <article key={r.id} className="bg-paper rounded-2xl border border-line p-4 shadow-soft">
              <div className="flex items-start gap-3">
                <Avatar src={r.avatar} name={r.nickname || '?'} size={44} />
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="font-medium">{r.nickname || '匿名'}</span>
                    <span className="text-xs text-ink-soft">{r.createdAt?.slice(5, 16)}</span>
                  </div>
                  <p className="mt-1 text-sm text-ink-soft break-words">{r.message}</p>
                </div>
                {r.status === 0 ? (
                  <button
                    onClick={() => accept(r.id)}
                    className="px-4 py-1.5 rounded-full bg-terracotta text-white text-sm hover:bg-terracotta-deep transition"
                  >
                    通过
                  </button>
                ) : r.status === 1 ? (
                  <span className="text-xs text-sage-deep">已通过</span>
                ) : (
                  <span className="text-xs text-ink-soft">已拒绝</span>
                )}
              </div>
            </article>
          ))}
        </div>
      )}
    </div>
  );
}
