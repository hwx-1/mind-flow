import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { PostApi } from '@/api';
import { http, ApiError } from '@/api/http';
import type { PostVo, CommentVo } from '@/types';
import { Avatar } from '@/components/Avatar';
import { useToast } from '@/components/Toast';

export function PostDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const toast = useToast((s) => s.push);
  const [post, setPost] = useState<PostVo | null>(null);
  const [comments, setComments] = useState<CommentVo[]>([]);
  const [text, setText] = useState('');
  const [posting, setPosting] = useState(false);

  useEffect(() => {
    if (!id) return;
    PostApi.detail(+id).then(setPost).catch((e) => toast((e as ApiError).message, 'error'));
    PostApi.comments(+id).then(setComments).catch(() => {});
  }, [id]);

  async function submitComment() {
    if (!text.trim() || !post) return;
    setPosting(true);
    try {
      await http.post(`/post/${post.id}/comment`, { content: text });
      setText('');
      const list = await PostApi.comments(post.id);
      setComments(list);
      setPost({ ...post, commentCount: (post.commentCount || 0) + 1 });
      toast('已评论', 'ok');
    } catch (e) {
      toast((e as ApiError).message, 'error');
    } finally {
      setPosting(false);
    }
  }

  async function toggleLike() {
    if (!post) return;
    try {
      const r = await PostApi.like(post.id);
      setPost({ ...post, liked: r.liked, likeCount: post.likeCount + (r.liked ? 1 : -1) });
    } catch (e) {
      toast((e as ApiError).message, 'error');
    }
  }

  if (!post) return <div className="text-center py-20 text-ink-soft">加载中...</div>;

  return (
    <div className="max-w-2xl mx-auto">
      <button onClick={() => navigate(-1)} className="text-sm text-ink-soft hover:text-ink mb-4">
        ← 返回
      </button>

      <article className="bg-paper rounded-2xl border border-line p-6 shadow-soft">
        <header className="flex items-center gap-3 mb-4">
          <Avatar src={post.avatar} name={post.nickname || `用户${post.userId}`} />
          <div>
            <div className="font-medium">{post.nickname || `用户${post.userId}`}</div>
            <div className="text-xs text-ink-soft">{fmtTime(post.createdAt)}</div>
          </div>
          {post.locationLabel && (
            <span className="ml-auto text-xs text-sage-deep bg-sage/15 px-2.5 py-1 rounded-full">
              📍 {post.locationLabel}
            </span>
          )}
        </header>

        <div className="text-[15px] leading-relaxed whitespace-pre-wrap break-words">
          {post.content}
        </div>

        {post.images && post.images.length > 0 && (
          <div className="mt-4 grid grid-cols-3 gap-2">
            {post.images.map((u, i) => (
              <img
                key={i}
                src={u}
                alt=""
                className="w-full aspect-square rounded-lg object-cover"
                onError={(e) => ((e.currentTarget as HTMLImageElement).style.display = 'none')}
              />
            ))}
          </div>
        )}

        <div className="mt-5 pt-4 border-t border-line flex items-center gap-5 text-sm text-ink-soft">
          <button
            onClick={toggleLike}
            className={`flex items-center gap-1.5 transition ${post.liked ? 'text-terracotta' : 'hover:text-terracotta'}`}
          >
            <span className="text-base">{post.liked ? '❤' : '♡'}</span>
            <span>{post.likeCount || 0}</span>
          </button>
          <span>💬 {post.commentCount || 0}</span>
        </div>
      </article>

      <section className="mt-6">
        <h3 className="font-serif text-lg mb-3">评论 ({comments.length})</h3>
        <div className="bg-paper rounded-2xl border border-line p-4 mb-4 flex gap-2">
          <input
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder="留下你的想法..."
            className="flex-1 px-4 py-2 rounded-full bg-cream-deep text-sm outline-none focus:bg-cream"
            onKeyDown={(e) => e.key === 'Enter' && submitComment()}
          />
          <button
            disabled={posting || !text.trim()}
            onClick={submitComment}
            className="px-5 py-2 rounded-full bg-terracotta text-white text-sm disabled:opacity-50"
          >
            发送
          </button>
        </div>

        {comments.length === 0 ? (
          <div className="text-center py-10 text-ink-soft text-sm">还没有评论</div>
        ) : (
          <div className="space-y-3">
            {comments.map((c) => (
              <div key={c.id} className="bg-paper rounded-2xl border border-line p-4 flex gap-3">
                <Avatar src={c.avatar} name={c.nickname || '?'} size={36} />
                <div className="flex-1 min-w-0">
                  <div className="flex items-baseline gap-2 mb-1">
                    <span className="text-sm font-medium">{c.nickname || '匿名'}</span>
                    <span className="text-xs text-ink-soft">{fmtTime(c.createdAt)}</span>
                  </div>
                  <p className="text-sm leading-relaxed break-words">{c.content}</p>
                </div>
              </div>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}

function fmtTime(t?: string) {
  if (!t) return '';
  try {
    return new Date(t.replace(' ', 'T')).toLocaleString('zh-CN', {
      month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit',
    });
  } catch { return t; }
}
