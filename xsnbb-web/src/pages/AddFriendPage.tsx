import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { UserApi } from '@/api';
import type { UserVo } from '@/types';
import { Avatar } from '@/components/Avatar';
import { useToast } from '@/components/Toast';
import { ApiError } from '@/api/http';

export function AddFriendPage() {
  const [keyword, setKeyword] = useState('');
  const [list, setList] = useState<UserVo[]>([]);
  const [searching, setSearching] = useState(false);
  const [requestTarget, setRequestTarget] = useState<UserVo | null>(null);
  const navigate = useNavigate();
  const toast = useToast((s) => s.push);

  async function search() {
    if (!keyword.trim()) return;
    setSearching(true);
    try {
      const users = await UserApi.search(keyword.trim());
      setList(users || []);
    } catch (e) {
      toast((e as ApiError).message, 'error');
    } finally {
      setSearching(false);
    }
  }

  return (
    <div className="max-w-xl mx-auto">
      <div className="flex items-center gap-3 mb-5">
        <button onClick={() => navigate(-1)} className="text-sm text-ink-soft hover:text-ink">←</button>
        <h1 className="font-serif text-xl">添加好友</h1>
      </div>

      <div className="bg-paper rounded-2xl border border-line p-5 shadow-soft mb-5">
        <div className="flex gap-2">
          <input
            value={keyword}
            onChange={(e) => setKeyword(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && search()}
            placeholder="搜索用户名、昵称、手机号..."
            className="flex-1 px-4 py-2.5 rounded-full bg-cream-deep outline-none focus:bg-cream text-sm"
          />
          <button
            onClick={search}
            disabled={searching || !keyword.trim()}
            className="px-5 py-2.5 rounded-full bg-terracotta text-white text-sm disabled:opacity-50"
          >
            搜索
          </button>
        </div>
      </div>

      {list.length === 0 ? (
        <div className="text-center py-12 text-ink-soft text-sm">{keyword ? '没找到这个人' : '输入关键字搜索用户'}</div>
      ) : (
        <div className="grid gap-3">
          {list.map((u) => (
            <article
              key={u.id}
              className="bg-paper rounded-2xl border border-line p-4 shadow-soft flex items-center gap-3"
            >
              <div className="cursor-pointer" onClick={() => navigate(`/user/${u.id}`)}>
                <Avatar src={u.avatar} name={u.nickname || u.username} size={48} />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="font-medium">{u.nickname || u.username}</span>
                  {u.profileStatus && (
                    <span className="text-[10px] bg-cream-deep px-2 py-0.5 rounded-full text-ink-soft">
                      {u.profileStatus}
                    </span>
                  )}
                </div>
                <div className="text-xs text-ink-soft">@{u.username}</div>
              </div>
              {u.friend ? (
                <span className="text-xs text-sage-deep">已是好友</span>
              ) : u.friendRequestStatus === 0 ? (
                <span className="text-xs text-ink-soft">已申请</span>
              ) : (
                <button
                  onClick={() => setRequestTarget(u)}
                  className="px-3 py-1.5 rounded-full bg-terracotta/15 text-terracotta-deep text-sm hover:bg-terracotta hover:text-white transition"
                >
                  加好友
                </button>
              )}
            </article>
          ))}
        </div>
      )}

      {requestTarget && (
        <RequestModal
          target={requestTarget}
          onClose={() => setRequestTarget(null)}
          onSent={() => {
            setRequestTarget(null);
            search();  // 刷新看状态变化
          }}
        />
      )}
    </div>
  );
}

function RequestModal({ target, onClose, onSent }: { target: UserVo; onClose: () => void; onSent: () => void; }) {
  const [msg, setMsg] = useState('你好,加个好友吧');
  const [sending, setSending] = useState(false);
  const toast = useToast((s) => s.push);

  async function send() {
    setSending(true);
    try {
      await UserApi.requestFriend(target.id, msg);
      toast('已发送好友申请', 'ok');
      onSent();
    } catch (e) {
      toast((e as ApiError).message, 'error');
    } finally {
      setSending(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 bg-ink/40 flex items-center justify-center p-4" onClick={onClose}>
      <div className="bg-paper rounded-2xl shadow-soft-lg w-full max-w-sm p-6" onClick={(e) => e.stopPropagation()}>
        <h3 className="font-serif text-lg mb-4">加 {target.nickname || target.username} 为好友</h3>
        <textarea
          value={msg}
          onChange={(e) => setMsg(e.target.value)}
          maxLength={80}
          rows={3}
          placeholder="给对方留个口信..."
          className="w-full px-3 py-2 rounded-xl bg-cream border border-line outline-none focus:border-terracotta text-sm resize-none"
        />
        <div className="flex justify-end gap-2 mt-4">
          <button onClick={onClose} className="px-4 py-2 text-sm text-ink-soft hover:text-ink">取消</button>
          <button
            onClick={send}
            disabled={sending}
            className="px-5 py-2 rounded-full bg-terracotta text-white text-sm disabled:opacity-50"
          >
            {sending ? '发送中...' : '发送'}
          </button>
        </div>
      </div>
    </div>
  );
}
