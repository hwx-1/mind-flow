import { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { UserApi, PostApi } from '@/api';
import type { UserVo, PostVo } from '@/types';
import { Avatar } from '@/components/Avatar';
import { useAuth } from '@/store/auth';
import { useToast } from '@/components/Toast';
import { ApiError } from '@/api/http';

const STATUS_COLOR: Record<string, string> = {
  '在线': 'bg-sage/20 text-sage-deep',
  '忙碌': 'bg-terracotta/20 text-terracotta-deep',
  '离开': 'bg-gold/20 text-clay',
  '勿扰': 'bg-danger/15 text-danger',
  '隐身': 'bg-ink/10 text-ink-soft',
};

export function UserPage() {
  const { id } = useParams();
  const userId = id ? +id : 0;
  const [profile, setProfile] = useState<UserVo | null>(null);
  const [posts, setPosts] = useState<PostVo[]>([]);
  const myId = useAuth((s) => s.user?.id);
  const navigate = useNavigate();
  const toast = useToast((s) => s.push);

  useEffect(() => {
    if (!userId) return;
    if (userId === myId) {
      navigate('/mine', { replace: true });
      return;
    }
    UserApi.profileOf(userId).then(setProfile).catch((e) => toast((e as ApiError).message, 'error'));
    PostApi.userPosts(userId, 1, 20).then((p) => setPosts(p.list || p.records || [])).catch(() => {});
  }, [userId, myId]);

  async function toggleFollow() {
    if (!profile) return;
    try {
      const r = await UserApi.follow(profile.id);
      setProfile({ ...profile, followed: r.followed });
      toast(r.followed ? '已关注' : '已取关', 'ok');
    } catch (e) {
      toast((e as ApiError).message, 'error');
    }
  }

  if (!profile) return <div className="text-center py-20 text-ink-soft">加载中...</div>;

  return (
    <div className="max-w-3xl mx-auto space-y-5">
      <button onClick={() => navigate(-1)} className="text-sm text-ink-soft hover:text-ink">← 返回</button>

      <div className="bg-paper rounded-2xl border border-line p-6 shadow-soft">
        <div className="flex items-start gap-5">
          <Avatar src={profile.avatar} name={profile.nickname || profile.username} size={84} />
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <h2 className="font-serif text-2xl font-medium">{profile.nickname || profile.username}</h2>
              {profile.profileStatus && (
                <span className={`text-xs px-2.5 py-0.5 rounded-full ${STATUS_COLOR[profile.profileStatus] || 'bg-cream-deep text-ink-soft'}`}>
                  {profile.profileStatus}
                </span>
              )}
              {profile.role === 'admin' && (
                <span className="text-xs bg-gold/20 text-clay px-2.5 py-0.5 rounded-full">管理员</span>
              )}
            </div>
            <p className="text-sm text-ink-soft mt-1">@{profile.username}</p>
            {profile.bio && <p className="text-sm mt-3 leading-relaxed">{profile.bio}</p>}

            <div className="mt-4 flex gap-2 flex-wrap">
              <button
                onClick={toggleFollow}
                className={`px-4 py-1.5 rounded-full text-sm transition ${
                  profile.followed
                    ? 'bg-cream-deep text-ink-soft hover:bg-line'
                    : 'bg-terracotta text-white hover:bg-terracotta-deep'
                }`}
              >
                {profile.followed ? '已关注' : '+ 关注'}
              </button>
              <button
                onClick={() => navigate(`/chat/${profile.id}`)}
                className="px-4 py-1.5 rounded-full text-sm bg-cream-deep hover:bg-line transition"
              >
                发消息
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="bg-paper rounded-2xl border border-line shadow-soft">
        <header className="p-5 border-b border-line">
          <h3 className="font-serif text-lg">TA 发布的</h3>
        </header>
        {posts.length === 0 ? (
          <div className="py-10 text-center text-ink-soft text-sm">还没有发过内容</div>
        ) : (
          <ul className="divide-y divide-line">
            {posts.map((p) => (
              <li
                key={p.id}
                onClick={() => navigate(`/post/${p.id}`)}
                className="p-4 px-5 hover:bg-cream-deep cursor-pointer transition"
              >
                <p className="text-sm line-clamp-2 leading-relaxed break-words">{p.content}</p>
                <div className="mt-2 text-xs text-ink-soft flex gap-4">
                  <span>❤ {p.likeCount || 0}</span>
                  <span>💬 {p.commentCount || 0}</span>
                  <span className="ml-auto">{p.createdAt?.slice(5, 16)}</span>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
