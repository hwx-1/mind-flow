import { useEffect, useRef, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { MessageApi, UserApi } from '@/api';
import type { ChatMsgVo, UserVo } from '@/types';
import { Avatar } from '@/components/Avatar';
import { useAuth } from '@/store/auth';
import { useToast } from '@/components/Toast';
import { ApiError } from '@/api/http';

const POLL_MS = 5000;

export function ChatRoomPage() {
  const { userId } = useParams();
  const otherId = userId ? +userId : 0;
  const [other, setOther] = useState<UserVo | null>(null);
  const [msgs, setMsgs] = useState<ChatMsgVo[]>([]);
  const [text, setText] = useState('');
  const [sending, setSending] = useState(false);
  const me = useAuth((s) => s.user);
  const scrollRef = useRef<HTMLDivElement>(null);
  const navigate = useNavigate();
  const toast = useToast((s) => s.push);

  useEffect(() => {
    if (!otherId) return;
    UserApi.profileOf(otherId).then(setOther).catch(() => {});
    load(false);
    const timer = setInterval(() => load(true), POLL_MS);
    return () => clearInterval(timer);
  }, [otherId]);

  async function load(silent: boolean) {
    try {
      const list = await MessageApi.chatWith(otherId);
      setMsgs(list || []);
      if (!silent) setTimeout(scrollEnd, 50);
    } catch (e) {
      if (!silent) toast((e as ApiError).message, 'error');
    }
  }

  function scrollEnd() {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: 'smooth' });
  }

  async function send() {
    if (!text.trim() || sending) return;
    setSending(true);
    const t = text.trim();
    setText('');
    try {
      const sent = await MessageApi.send(otherId, t);
      setMsgs([...msgs, sent]);
      setTimeout(scrollEnd, 50);
    } catch (e) {
      toast((e as ApiError).message, 'error');
      setText(t);
    } finally {
      setSending(false);
    }
  }

  if (!me) return null;

  return (
    <div className="max-w-2xl mx-auto flex flex-col h-[calc(100vh-6rem)]">
      <header className="flex items-center gap-3 pb-4 mb-3 border-b border-line">
        <button onClick={() => navigate(-1)} className="text-ink-soft hover:text-ink text-sm">←</button>
        <Avatar src={other?.avatar} name={other?.nickname || other?.username || '?'} size={36} />
        <div className="flex-1 min-w-0">
          <div className="font-medium">{other?.nickname || other?.username || '加载中...'}</div>
          {other?.profileStatus && <div className="text-xs text-ink-soft">{other.profileStatus}</div>}
        </div>
      </header>

      <div ref={scrollRef} className="flex-1 overflow-y-auto bg-paper rounded-2xl border border-line p-5 space-y-3 shadow-soft">
        {msgs.length === 0 ? (
          <div className="text-center py-12 text-ink-soft text-sm">还没有消息,打个招呼吧～</div>
        ) : (
          msgs.map((m) => <Bubble key={m.id} msg={m} mine={m.fromUser === me.id} other={other} myAvatar={me.avatar} myName={me.nickname || me.username} />)
        )}
      </div>

      <div className="mt-3 flex gap-2">
        <input
          value={text}
          onChange={(e) => setText(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && send()}
          placeholder="输入消息..."
          disabled={sending}
          className="flex-1 px-4 py-2.5 rounded-full bg-paper border border-line outline-none focus:border-terracotta text-sm"
        />
        <button
          onClick={send}
          disabled={!text.trim() || sending}
          className="px-5 py-2.5 rounded-full bg-terracotta text-white text-sm disabled:opacity-50"
        >
          发送
        </button>
      </div>
    </div>
  );
}

function Bubble({ msg, mine, other, myAvatar, myName }: { msg: ChatMsgVo; mine: boolean; other: UserVo | null; myAvatar?: string; myName?: string; }) {
  if (mine) {
    return (
      <div className="flex justify-end gap-2 items-end">
        <div className="max-w-[72%] px-3.5 py-2 rounded-2xl rounded-br-md bg-terracotta text-white text-[14.5px] leading-relaxed break-words">
          {msg.content}
        </div>
        <Avatar src={myAvatar} name={myName || '?'} size={32} />
      </div>
    );
  }
  return (
    <div className="flex justify-start gap-2 items-end">
      <Avatar src={other?.avatar} name={other?.nickname || '?'} size={32} />
      <div className="max-w-[72%] px-3.5 py-2 rounded-2xl rounded-bl-md bg-cream-deep text-[14.5px] leading-relaxed break-words">
        {msg.content}
      </div>
    </div>
  );
}
