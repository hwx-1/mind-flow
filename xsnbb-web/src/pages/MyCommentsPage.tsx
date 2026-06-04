import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { PostApi } from '@/api';
import { useToast } from '@/components/Toast';
import { ApiError } from '@/api/http';

interface MyComment {
  id: number;
  content: string;
  createdAt: string;
  postId?: number;
  postContent?: string;
}

export function MyCommentsPage() {
  const [list, setList] = useState<MyComment[]>([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();
  const toast = useToast((s) => s.push);

  useEffect(() => {
    PostApi.myComments()
      .then((arr) => setList(arr as unknown as MyComment[]))
      .catch((e) => toast((e as ApiError).message, 'error'))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="max-w-2xl mx-auto">
      <button onClick={() => navigate(-1)} className="text-sm text-ink-soft hover:text-ink mb-4">
        ← 返回
      </button>
      <h1 className="font-serif text-2xl mb-1">我的评论</h1>
      <p className="text-sm text-ink-soft mb-5">你在帖子下留下的评论</p>

      {loading ? (
        <div className="text-center py-20 text-ink-soft">加载中...</div>
      ) : list.length === 0 ? (
        <div className="text-center py-20 text-ink-soft text-sm">还没评论过</div>
      ) : (
        <div className="grid gap-3">
          {list.map((c) => (
            <article
              key={c.id}
              onClick={() => c.postId && navigate(`/post/${c.postId}`)}
              className="bg-paper rounded-2xl border border-line p-4 shadow-soft hover:shadow-soft-lg hover:-translate-y-0.5 transition cursor-pointer"
            >
              <p className="text-sm leading-relaxed break-words">{c.content}</p>
              <div className="mt-3 pt-3 border-t border-dashed border-line text-xs text-ink-soft flex justify-between">
                <span>评论于 #{c.postId}</span>
                <span>{c.createdAt?.slice(5, 16)}</span>
              </div>
              {c.postContent && (
                <p className="mt-2 text-xs text-ink-soft line-clamp-2 break-words bg-cream-deep rounded-lg p-2">
                  原帖: {c.postContent}
                </p>
              )}
            </article>
          ))}
        </div>
      )}
    </div>
  );
}
