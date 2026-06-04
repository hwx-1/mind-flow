import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { MessageApi } from '@/api';
import type { ChatConvVo, NotificationVo, UnreadCount } from '@/types';
import { Avatar } from '@/components/Avatar';
import { useToast } from '@/components/Toast';
import { ApiError } from '@/api/http';

type Tab = 'chats' | 'like' | 'comment' | 'friend';

export function MessagesPage() {
  const [tab, setTab] = useState<Tab>('chats');
  const [chats, setChats] = useState<ChatConvVo[]>([]);
  const [notifs, setNotifs] = useState<NotificationVo[]>([]);
  const [unread, setUnread] = useState<UnreadCount>({});
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();
  const toast = useToast((s) => s.push);

  useEffect(() => {
    MessageApi.unreadCount().then(setUnread).catch(() => {});
  }, []);

  useEffect(() => {
    setLoading(true);
    if (tab === 'chats') {
      MessageApi.chats()
        .then((arr) => setChats(arr || []))
        .catch((e) => toast((e as ApiError).message, 'error'))
        .finally(() => setLoading(false));
    } else {
      MessageApi.notifications(tab, 1)
        .then((arr) => setNotifs(arr || []))
        .catch((e) => toast((e as ApiError).message, 'error'))
        .finally(() => setLoading(false));
    }
  }, [tab]);

  const tabs: { key: Tab; label: string; key2?: keyof UnreadCount }[] = [
    { key: 'chats',   label: '私聊',   key2: 'chat' },
    { key: 'like',    label: '点赞',   key2: 'like' },
    { key: 'comment', label: '评论',   key2: 'comment' },
    { key: 'friend',  label: '好友',   key2: 'friend' },
  ];

  return (
    <div className="max-w-2xl mx-auto">
      <div className="flex items-center justify-between mb-5">
        <h1 className="font-serif text-2xl">消息</h1>
        <button
          onClick={() => navigate('/friends/add')}
          className="px-4 py-1.5 rounded-full text-sm bg-cream-deep hover:bg-line transition"
        >
          + 添加好友
        </button>
      </div>

      <div className="flex gap-1 p-1 bg-paper rounded-full border border-line mb-5">
        {tabs.map((t) => {
          const n = (t.key2 && unread[t.key2]) || 0;
          return (
            <button
              key={t.key}
              onClick={() => setTab(t.key)}
              className={`flex-1 py-2 text-sm rounded-full transition relative ${
                tab === t.key ? 'bg-terracotta text-white shadow-soft' : 'text-ink-soft hover:text-ink'
              }`}
            >
              {t.label}
              {n > 0 && (
                <span className="ml-1.5 text-[10px] bg-danger text-white px-1.5 py-0.5 rounded-full">
                  {n}
                </span>
              )}
            </button>
          );
        })}
      </div>

      <div className="text-right mb-2">
        <button
          onClick={() => navigate('/friends/requests')}
          className="text-xs text-ink-soft hover:text-terracotta transition"
        >
          好友申请 →
        </button>
      </div>

      {loading ? (
        <div className="text-center py-20 text-ink-soft">加载中...</div>
      ) : tab === 'chats' ? (
        <ChatList chats={chats} onOpen={(uid) => navigate(`/chat/${uid}`)} />
      ) : (
        <NotifList list={notifs} />
      )}
    </div>
  );
}

function ChatList({ chats, onOpen }: { chats: ChatConvVo[]; onOpen: (uid: number) => void }) {
  if (chats.length === 0) {
    return <div className="text-center py-20 text-ink-soft text-sm">还没有聊天记录</div>;
  }
  return (
    <div className="bg-paper rounded-2xl border border-line shadow-soft overflow-hidden">
      <ul className="divide-y divide-line">
        {chats.map((c) => (
          <li
            key={c.userId}
            onClick={() => onOpen(c.userId)}
            className="p-4 px-5 hover:bg-cream-deep cursor-pointer transition flex items-center gap-3"
          >
            <Avatar src={c.avatar} name={c.nickname || `用户${c.userId}`} size={44} />
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2">
                <span className="font-medium">{c.nickname || `用户${c.userId}`}</span>
                <span className="text-xs text-ink-soft ml-auto">{c.updatedAt?.slice(5, 16)}</span>
              </div>
              <div className="text-sm text-ink-soft mt-0.5 truncate">{c.lastMessage || '—'}</div>
            </div>
            {c.unreadCount && c.unreadCount > 0 && (
              <span className="bg-danger text-white text-[11px] px-2 py-0.5 rounded-full flex-shrink-0">
                {c.unreadCount}
              </span>
            )}
          </li>
        ))}
      </ul>
    </div>
  );
}

function NotifList({ list }: { list: NotificationVo[] }) {
  if (list.length === 0) {
    return <div className="text-center py-20 text-ink-soft text-sm">暂无通知</div>;
  }
  return (
    <div className="bg-paper rounded-2xl border border-line shadow-soft overflow-hidden">
      <ul className="divide-y divide-line">
        {list.map((n) => (
          <li key={n.id} className={`p-4 px-5 flex items-start gap-3 ${n.isRead ? '' : 'bg-cream-deep/40'}`}>
            <Avatar src={n.avatar} name={n.nickname || '?'} size={40} />
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2">
                <span className="text-sm font-medium">{n.nickname || '系统'}</span>
                {!n.isRead && <span className="w-1.5 h-1.5 rounded-full bg-danger" />}
                <span className="text-xs text-ink-soft ml-auto">{n.createdAt?.slice(5, 16)}</span>
              </div>
              <p className="text-sm mt-0.5">{n.content}</p>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}
