import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { PostApi } from '@/api';
import type { PostVo } from '@/types';
import { Avatar } from '@/components/Avatar';
import { useToast } from '@/components/Toast';
import { ApiError } from '@/api/http';

export function MyLikesPage() {
  const [posts, setPosts] = useState<PostVo[]>([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();
  const toast = useToast((s) => s.push);

  useEffect(() => {
    PostApi.myLikes(1, 50)
      .then((p) => setPosts(p.list || p.records || []))
      .catch((e) => toast((e as ApiError).message, 'error'))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="max-w-2xl mx-auto">
      <button onClick={() => navigate(-1)} className="text-sm text-ink-soft hover:text-ink mb-4">
        ← 返回
      </button>
      <h1 className="font-serif text-2xl mb-1">我的点赞</h1>
      <p className="text-sm text-ink-soft mb-5">你点过赞的帖子</p>

      {loading ? (
        <div className="text-center py-20 text-ink-soft">加载中...</div>
      ) : posts.length === 0 ? (
        <div className="text-center py-20 text-ink-soft text-sm">还没点过赞</div>
      ) : (
        <div className="grid gap-3">
          {posts.map((p) => (
            <article
              key={p.id}
              onClick={() => navigate(`/post/${p.id}`)}
              className="bg-paper rounded-2xl border border-line p-4 shadow-soft hover:shadow-soft-lg hover:-translate-y-0.5 transition cursor-pointer"
            >
              <div className="flex items-start gap-3">
                <Avatar src={p.avatar} name={p.nickname || `用户${p.userId}`} size={36} />
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium">{p.nickname || `用户${p.userId}`}</span>
                    <span className="text-xs text-ink-soft">{p.createdAt?.slice(5, 16)}</span>
                  </div>
                  <p className="mt-1.5 text-sm leading-relaxed line-clamp-3 break-words">{p.content}</p>
                  <div className="mt-2 text-xs text-ink-soft flex gap-4">
                    <span className="text-terracotta">❤ {p.likeCount || 0}</span>
                    <span>💬 {p.commentCount || 0}</span>
                  </div>
                </div>
              </div>
            </article>
          ))}
        </div>
      )}
    </div>
  );
}
