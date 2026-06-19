import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { PostApi } from '@/api';
import type { PostVo } from '@/types';
import { Avatar } from '@/components/Avatar';
import { useToast } from '@/components/Toast';
import { ApiError } from '@/api/http';

export function CommunityPage() {
  const [tab, setTab] = useState<'recommend' | 'hot' | 'follow'>('recommend');
  const [posts, setPosts] = useState<PostVo[]>([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();
  const toast = useToast((s) => s.push);

  useEffect(() => {
    load();
  }, [tab]);

  async function load() {
    setLoading(true);
    try {
      const page = await PostApi.list(tab, 1, 30);
      setPosts(page.list || page.records || []);
    } catch (e) {
      toast((e as ApiError).message, 'error');
    } finally {
      setLoading(false);
    }
  }

  async function onLike(p: PostVo, ev: React.MouseEvent) {
    ev.stopPropagation();
    try {
      const r = await PostApi.like(p.id);
      setPosts((prev) =>
        prev.map((x) =>
          x.id === p.id
            ? { ...x, liked: r.liked, likeCount: x.likeCount + (r.liked ? 1 : -1) }
            : x
        )
      );
    } catch (e) {
      toast((e as ApiError).message, 'error');
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div className="flex gap-1 p-1 bg-paper rounded-full border border-line">
          {(['recommend', 'hot', 'follow'] as const).map((t) => (
            <button
              key={t}
              onClick={() => setTab(t)}
              className={`px-5 py-1.5 text-sm rounded-full transition ${
                tab === t ? 'bg-terracotta text-white shadow-soft' : 'text-ink-soft hover:text-ink'
              }`}
            >
              {t === 'recommend' ? '推荐' : t === 'hot' ? '热门' : '关注'}
            </button>
          ))}
        </div>
        <button
          onClick={() => navigate('/publish')}
          className="px-5 py-2 rounded-full bg-gradient-to-br from-terracotta to-terracotta-deep text-white text-sm shadow-soft hover:-translate-y-0.5 transition"
        >
          + 发布
        </button>
      </div>

      {loading ? (
        <div className="text-center py-20 text-ink-soft">加载中...</div>
      ) : posts.length === 0 ? (
        <div className="text-center py-20 text-ink-soft">还没有内容,来发第一条吧</div>
      ) : (
        <div className="grid gap-4">
          {posts.map((p) => (
            <PostCard key={p.id} post={p} onLike={onLike} onClick={() => navigate(`/post/${p.id}`)} />
          ))}
        </div>
      )}
    </div>
  );
}

function PostCard({
  post,
  onLike,
  onClick,
}: {
  post: PostVo;
  onLike: (p: PostVo, e: React.MouseEvent) => void;
  onClick: () => void;
}) {
  return (
    <article
      onClick={onClick}
      className="bg-paper rounded-2xl border border-line p-5 shadow-soft hover:shadow-soft-lg hover:-translate-y-0.5 transition cursor-pointer"
    >
      <div className="flex items-start gap-3">
        <Avatar src={post.avatar} name={post.nickname || `用户${post.userId}`} size={42} />
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <span className="font-medium text-sm">{post.nickname || `用户${post.userId}`}</span>
            <span className="text-xs text-ink-soft">{fmtTime(post.createdAt)}</span>
            {post.locationLabel && (
              <span className="text-[11px] text-sage-deep bg-sage/15 px-2 py-0.5 rounded-full">
                📍 {post.locationLabel}
              </span>
            )}
          </div>
          <p className="mt-2 text-[15px] leading-relaxed whitespace-pre-wrap break-words">
            {post.content}
          </p>
          {post.images && post.images.length > 0 && (
            <div className="mt-3 grid grid-cols-3 gap-2">
              {post.images.slice(0, 9).map((u, i) => (
                <img
                  key={i}
                  src={u}
                  alt=""
                  className="w-full aspect-square rounded-lg object-cover bg-cream-deep"
                  onError={(e) => ((e.currentTarget as HTMLImageElement).style.display = 'none')}
                />
              ))}
            </div>
          )}
          <div className="mt-3 flex items-center gap-5 text-sm text-ink-soft">
            <button
              onClick={(e) => onLike(post, e)}
              className={`flex items-center gap-1.5 transition ${
                post.liked ? 'text-terracotta' : 'hover:text-terracotta'
              }`}
            >
              <span>{post.liked ? '❤' : '♡'}</span>
              <span>{post.likeCount || 0}</span>
            </button>
            <span className="flex items-center gap-1.5">
              <span>💬</span>
              <span>{post.commentCount || 0}</span>
            </span>
          </div>
        </div>
      </div>
    </article>
  );
}

function fmtTime(t?: string) {
  if (!t) return '';
  try {
    const d = new Date(t.replace(' ', 'T'));
    const diff = (Date.now() - d.getTime()) / 1000;
    if (diff < 60) return '刚刚';
    if (diff < 3600) return `${Math.floor(diff / 60)}分钟前`;
    if (diff < 86400) return `${Math.floor(diff / 3600)}小时前`;
    return d.toLocaleString('zh-CN', { month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' });
  } catch {
    return t;
  }
}
