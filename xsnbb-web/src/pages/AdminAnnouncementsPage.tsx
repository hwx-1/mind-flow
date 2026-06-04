import { useEffect, useState } from 'react';
import { AnnouncementApi } from '@/api';
import { ApiError } from '@/api/http';
import { useToast } from '@/components/Toast';
import type { AnnouncementVo } from '@/types';

/**
 * 管理员公告管理：发布 / 列表 / 下线。
 * 路由 /announcements/manage，由 AdminOnly 门控。
 * 调用后端 /admin/announcements（AdminInterceptor 校验 role=admin）。
 */
export function AdminAnnouncementsPage() {
  const [list, setList] = useState<AnnouncementVo[]>([]);
  const [loading, setLoading] = useState(true);
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const toast = useToast((s) => s.push);

  useEffect(() => { refresh(); }, []);

  async function refresh() {
    setLoading(true);
    try {
      setList(await AnnouncementApi.list());
    } catch (e) {
      toast((e as ApiError).message, 'error');
    } finally {
      setLoading(false);
    }
  }

  async function publish() {
    if (!content.trim()) {
      toast('请填写公告内容', 'error');
      return;
    }
    setSubmitting(true);
    try {
      await AnnouncementApi.publish(title.trim(), content.trim());
      toast('已发布', 'ok');
      setTitle('');
      setContent('');
      refresh();
    } catch (e) {
      toast((e as ApiError).message, 'error');
    } finally {
      setSubmitting(false);
    }
  }

  async function offline(a: AnnouncementVo) {
    if (!confirm('下线这条公告？下线后 App 和网页都不再显示。')) return;
    try {
      await AnnouncementApi.offline(a.id);
      toast('已下线', 'ok');
      setList(list.filter((x) => x.id !== a.id));
    } catch (e) {
      toast((e as ApiError).message, 'error');
    }
  }

  return (
    <div className="space-y-6">
      <div>
        <h2 className="font-serif text-2xl mb-1">公告管理</h2>
        <p className="text-sm text-ink-soft">
          发布后，App 与网页用户进入时会弹出<span className="text-terracotta-deep">最新一条</span>公告。
        </p>
      </div>

      {/* 发布表单 */}
      <div className="bg-paper rounded-2xl shadow-soft p-5 space-y-3">
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="标题（可选）"
          maxLength={50}
          className="w-full px-4 py-2.5 rounded-xl bg-cream-deep/50 border border-line outline-none focus:border-terracotta text-sm"
        />
        <textarea
          value={content}
          onChange={(e) => setContent(e.target.value)}
          placeholder="公告内容…"
          rows={5}
          maxLength={1000}
          className="w-full px-4 py-3 rounded-xl bg-cream-deep/50 border border-line outline-none focus:border-terracotta text-sm leading-6 resize-none"
        />
        <div className="flex items-center justify-between">
          <span className="text-xs text-ink-soft">{content.length}/1000</span>
          <button
            onClick={publish}
            disabled={submitting}
            className="px-6 py-2 rounded-full bg-gradient-to-br from-terracotta to-terracotta-deep text-white text-sm shadow-soft hover:-translate-y-0.5 transition disabled:opacity-60"
          >
            {submitting ? '发布中…' : '发布公告'}
          </button>
        </div>
      </div>

      {/* 列表 */}
      <div className="space-y-3">
        <h3 className="text-sm text-ink-soft">已发布（上线中）</h3>
        {loading ? (
          <p className="text-sm text-ink-soft">加载中…</p>
        ) : list.length === 0 ? (
          <p className="text-sm text-ink-soft">暂无公告</p>
        ) : (
          list.map((a) => (
            <div key={a.id} className="bg-paper rounded-2xl shadow-soft p-4">
              <div className="flex items-start justify-between gap-3">
                <div className="min-w-0">
                  {a.title && <div className="font-medium text-ink mb-1">{a.title}</div>}
                  <p className="text-sm text-ink whitespace-pre-wrap break-words">{a.content}</p>
                  {a.createdAt && (
                    <div className="text-xs text-ink-soft mt-2">{a.createdAt}</div>
                  )}
                </div>
                <button
                  onClick={() => offline(a)}
                  className="shrink-0 px-3 py-1.5 rounded-full text-xs text-danger border border-danger/30 hover:bg-danger/10 transition"
                >
                  下线
                </button>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
