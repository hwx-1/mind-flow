import { useEffect, useRef, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { AiApi } from '@/api';
import { sse } from '@/api/http';
import { useToast } from '@/components/Toast';
import { ApiError } from '@/api/http';

interface Msg {
  role: 'user' | 'assistant' | 'system';
  content: string;
}

export function AiChatPage() {
  const { id } = useParams();
  const sessionId = id ? +id : 0;
  const [msgs, setMsgs] = useState<Msg[]>([]);
  const [text, setText] = useState('');
  const [streaming, setStreaming] = useState(false);
  const cancelRef = useRef<(() => void) | null>(null);
  const scrollRef = useRef<HTMLDivElement>(null);
  const navigate = useNavigate();
  const toast = useToast((s) => s.push);

  useEffect(() => {
    if (!sessionId) return;
    AiApi.messages(sessionId)
      .then((list) => {
        setMsgs(list.map((m) => ({ role: m.role, content: m.content })));
        setTimeout(scrollEnd, 50);
      })
      .catch((e) => toast((e as ApiError).message, 'error'));
    return () => {
      cancelRef.current?.();
    };
  }, [sessionId]);

  function scrollEnd() {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: 'smooth' });
  }

  async function send() {
    if (!text.trim() || streaming) return;
    const userText = text.trim();
    setText('');
    setMsgs((prev) => [...prev, { role: 'user', content: userText }, { role: 'assistant', content: '' }]);
    setStreaming(true);
    setTimeout(scrollEnd, 30);

    cancelRef.current = await sse(
      '/ai/chat',
      { sessionId, content: userText },
      (delta) => {
        setMsgs((prev) => {
          const next = prev.slice();
          const last = next[next.length - 1];
          if (last && last.role === 'assistant') {
            next[next.length - 1] = { ...last, content: last.content + delta };
          }
          return next;
        });
        setTimeout(scrollEnd, 0);
      },
      () => {
        setStreaming(false);
        cancelRef.current = null;
        setMsgs((prev) => {
          const next = prev.slice();
          const last = next[next.length - 1];
          if (last && last.role === 'assistant' && !last.content) {
            next[next.length - 1] = { ...last, content: '(无回复)' };
          }
          return next;
        });
      },
      (e) => {
        setStreaming(false);
        cancelRef.current = null;
        toast(e.message || 'AI 调用失败', 'error');
        setMsgs((prev) => {
          const next = prev.slice();
          const last = next[next.length - 1];
          if (last && last.role === 'assistant') {
            next[next.length - 1] = { ...last, content: last.content || '出错了,稍后再试' };
          }
          return next;
        });
      }
    );
  }

  function stop() {
    cancelRef.current?.();
    cancelRef.current = null;
    setStreaming(false);
  }

  return (
    <div className="max-w-3xl mx-auto flex flex-col h-[calc(100vh-6rem)]">
      <div className="flex items-center justify-between mb-3">
        <button onClick={() => navigate('/ai')} className="text-sm text-ink-soft hover:text-ink">← 返回</button>
        <h1 className="font-serif text-lg">AI 对话</h1>
        <div className="w-12" />
      </div>

      <div
        ref={scrollRef}
        className="flex-1 overflow-y-auto bg-paper rounded-2xl border border-line p-5 space-y-4 shadow-soft"
      >
        {msgs.length === 0 ? (
          <div className="text-center py-12 text-ink-soft text-sm">说点什么开始吧～</div>
        ) : (
          msgs.map((m, i) => <Bubble key={i} msg={m} />)
        )}
      </div>

      <div className="mt-3 flex gap-2 items-end">
        <textarea
          value={text}
          onChange={(e) => setText(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
              e.preventDefault();
              send();
            }
          }}
          rows={2}
          placeholder={streaming ? '回复中...' : '输入消息,Enter 发送'}
          disabled={streaming}
          className="flex-1 px-4 py-3 rounded-2xl bg-paper border border-line text-[15px] outline-none focus:border-terracotta resize-none disabled:opacity-60"
        />
        {streaming ? (
          <button onClick={stop} className="px-5 py-3 rounded-2xl bg-danger text-white text-sm">
            停止
          </button>
        ) : (
          <button
            onClick={send}
            disabled={!text.trim()}
            className="px-5 py-3 rounded-2xl bg-terracotta text-white text-sm disabled:opacity-50"
          >
            发送
          </button>
        )}
      </div>
    </div>
  );
}

function Bubble({ msg }: { msg: Msg }) {
  if (msg.role === 'user') {
    return (
      <div className="flex justify-end">
        <div className="max-w-[78%] px-4 py-2.5 rounded-2xl rounded-tr-md bg-terracotta text-white text-[15px] leading-relaxed whitespace-pre-wrap">
          {msg.content}
        </div>
      </div>
    );
  }
  return (
    <div className="flex justify-start gap-2 items-start">
      <div className="w-8 h-8 rounded-full bg-gradient-to-br from-sage to-sage-deep text-white text-xs flex items-center justify-center flex-shrink-0">
        AI
      </div>
      <div className="max-w-[78%] px-4 py-2.5 rounded-2xl rounded-tl-md bg-cream-deep text-[15px] leading-relaxed whitespace-pre-wrap">
        {msg.content || <span className="text-ink-soft">思考中...</span>}
      </div>
    </div>
  );
}
