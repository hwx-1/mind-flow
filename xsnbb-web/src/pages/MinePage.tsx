import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
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

export function MinePage() {
  const [profile, setProfile] = useState<UserVo | null>(null);
  const [posts, setPosts] = useState<PostVo[]>([]);
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState<Partial<UserVo>>({});
  const [saving, setSaving] = useState(false);
  const setUser = useAuth((s) => s.setUser);
  const isAdmin = useAuth((s) => s.isAdmin)();
  const navigate = useNavigate();
  const toast = useToast((s) => s.push);

  useEffect(() => {
    refresh();
    PostApi.my(1, 20).then((p) => setPosts(p.list || p.records || [])).catch(() => {});
  }, []);

  async function refresh() {
    try {
      const u = await UserApi.profile();
      setProfile(u);
      setUser(u);
    } catch (e) {
      toast((e as ApiError).message, 'error');
    }
  }

  function startEdit() {
    if (!profile) return;
    setDraft({ nickname: profile.nickname, bio: profile.bio, profileStatus: profile.profileStatus });
    setEditing(true);
  }

  async function save() {
    setSaving(true);
    try {
      await UserApi.update(draft);
      toast('保存成功', 'ok');
      setEditing(false);
      refresh();
    } catch (e) {
      toast((e as ApiError).message, 'error');
    } finally {
      setSaving(false);
    }
  }

  if (!profile) return <div className="text-center py-20 text-ink-soft">加载中...</div>;

  return (
    <div className="max-w-3xl mx-auto space-y-5">
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
            <p className="text-sm text-ink-soft mt-1">
              @{profile.username} {profile.uid ? `· UID ${profile.uid}` : ''}
            </p>
            {profile.bio && <p className="text-sm mt-3 leading-relaxed">{profile.bio}</p>}
            <div className="mt-4 flex gap-2">
              <button
                onClick={startEdit}
                className="px-4 py-1.5 rounded-full bg-cream-deep text-sm hover:bg-line transition"
              >
                编辑资料
              </button>
              {isAdmin && (
                <a
                  href="/admin/"
                  target="_blank"
                  rel="noopener"
                  className="px-4 py-1.5 rounded-full bg-gold/20 text-clay text-sm hover:bg-gold/30 transition"
                >
                  进入管理后台 →
                </a>
              )}
              {isAdmin && (
                <button
                  onClick={() => navigate('/announcements/manage')}
                  className="px-4 py-1.5 rounded-full bg-gold/20 text-clay text-sm hover:bg-gold/30 transition"
                >
                  公告管理
                </button>
              )}
            </div>
          </div>
        </div>
      </div>

      {editing && (
        <div className="fixed inset-0 bg-ink/40 z-50 flex items-center justify-center p-4" onClick={() => setEditing(false)}>
          <div
            className="bg-paper rounded-2xl shadow-soft-lg max-w-md w-full p-6"
            onClick={(e) => e.stopPropagation()}
          >
            <h3 className="font-serif text-lg mb-4">编辑资料</h3>
            <FormItem label="昵称">
              <input
                value={draft.nickname || ''}
                onChange={(e) => setDraft({ ...draft, nickname: e.target.value })}
                maxLength={20}
                className="w-full px-3 py-2 rounded-lg border border-line bg-cream outline-none focus:border-terracotta"
              />
            </FormItem>
            <FormItem label="一句话简介">
              <textarea
                value={draft.bio || ''}
                onChange={(e) => setDraft({ ...draft, bio: e.target.value })}
                rows={3}
                maxLength={120}
                className="w-full px-3 py-2 rounded-lg border border-line bg-cream outline-none focus:border-terracotta resize-none"
              />
            </FormItem>
            <FormItem label="当前状态">
              <div className="flex gap-2 flex-wrap">
                {['在线', '忙碌', '离开', '勿扰', '隐身'].map((s) => (
                  <button
                    key={s}
                    onClick={() => setDraft({ ...draft, profileStatus: s })}
                    className={`px-3 py-1.5 rounded-full text-xs ${
                      draft.profileStatus === s
                        ? 'bg-terracotta text-white'
                        : 'bg-cream-deep text-ink-soft hover:text-ink'
                    }`}
                  >
                    {s}
                  </button>
                ))}
              </div>
            </FormItem>
            <div className="flex justify-end gap-2 mt-5">
              <button onClick={() => setEditing(false)} className="px-4 py-2 text-sm text-ink-soft hover:text-ink">
                取消
              </button>
              <button
                onClick={save}
                disabled={saving}
                className="px-5 py-2 rounded-full bg-terracotta text-white text-sm disabled:opacity-50"
              >
                {saving ? '保存中...' : '保存'}
              </button>
            </div>
          </div>
        </div>
      )}

      <div className="bg-paper rounded-2xl border border-line shadow-soft overflow-hidden">
        <ul className="divide-y divide-line">
          <QuickLink label="我的点赞" icon="❤" onClick={() => navigate('/mine/likes')} />
          <QuickLink label="我的评论" icon="💬" onClick={() => navigate('/mine/comments')} />
          <QuickLink label="消息中心" icon="✉️" onClick={() => navigate('/messages')} />
          <QuickLink label="知识库"   icon="📚" onClick={() => navigate('/knowledge')} />
          <QuickLink label="设置"     icon="⚙️" onClick={() => navigate('/settings')} />
        </ul>
      </div>

      <div className="bg-paper rounded-2xl border border-line shadow-soft">
        <header className="p-5 border-b border-line flex items-baseline justify-between">
          <h3 className="font-serif text-lg">我发布的</h3>
          <span className="text-sm text-ink-soft">{posts.length} 条</span>
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
                <p className="text-sm line-clamp-2 leading-relaxed">{p.content}</p>
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

function FormItem({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="mb-3">
      <label className="block text-xs text-ink-soft mb-1.5">{label}</label>
      {children}
    </div>
  );
}

function QuickLink({ label, icon, onClick }: { label: string; icon: string; onClick: () => void }) {
  return (
    <li
      onClick={onClick}
      className="p-4 px-5 flex items-center gap-3 hover:bg-cream-deep cursor-pointer transition"
    >
      <span className="text-xl">{icon}</span>
      <span className="flex-1 text-sm">{label}</span>
      <span className="text-ink-soft text-sm">›</span>
    </li>
  );
}
