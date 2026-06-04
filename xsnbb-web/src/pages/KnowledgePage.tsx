import { useEffect, useState } from 'react';
import { KnowledgeApi } from '@/api';
import { ApiError } from '@/api/http';
import { useAuth } from '@/store/auth';
import { useToast } from '@/components/Toast';
import type { KnowledgeBaseVo, CreateKnowledgeReq } from '@/types';

const MAX_PRIVATE = 50;
const MAX_CONTENT = 2000;

export function KnowledgePage() {
  const [list, setList] = useState<KnowledgeBaseVo[]>([]);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<KnowledgeBaseVo | 'new' | null>(null);
  const isAdmin = useAuth((s) => s.isAdmin)();
  const myUserId = useAuth((s) => s.user?.id);
  const toast = useToast((s) => s.push);

  useEffect(() => { refresh(); }, []);

  async function refresh() {
    setLoading(true);
    try {
      setList(await KnowledgeApi.list());
    } catch (e) {
      toast((e as ApiError).message, 'error');
    } finally {
      setLoading(false);
    }
  }

  async function toggleEnabled(k: KnowledgeBaseVo) {
    try {
      const updated = await KnowledgeApi.update(k.id, { enabled: k.enabled === 1 ? 0 : 1 });
      setList(list.map((x) => (x.id === k.id ? updated : x)));
      toast(updated.enabled === 1 ? '已启用' : '已禁用', 'ok');
    } catch (e) {
      toast((e as ApiError).message, 'error');
    }
  }

  async function doDelete(k: KnowledgeBaseVo) {
    if (!confirm(`删除「${k.title}」?`)) return;
    try {
      await KnowledgeApi.delete(k.id);
      setList(list.filter((x) => x.id !== k.id));
      toast('已删除', 'ok');
    } catch (e) {
      toast((e as ApiError).message, 'error');
    }
  }

  const globalList = list.filter((x) => x.scope === 'global');
  const privateList = list.filter((x) => x.scope === 'private' && x.userId === myUserId);
  const privateRemain = MAX_PRIVATE - privateList.length;

  return (
    <div className="space-y-5">
      <div className="flex items-start justify-between">
        <div>
          <h2 className="font-serif text-2xl mb-1">AI 知识库</h2>
          <p className="text-sm text-ink-soft">
            告诉 AI 你的偏好、背景、专业知识 ——
            <span className="text-terracotta-deep">所有启用的条目会自动加入对话上下文</span>
          </p>
        </div>
        <button
          onClick={() => setEditing('new')}
          className="px-5 py-2 rounded-full bg-gradient-to-br from-terracotta to-terracotta-deep text-white text-sm shadow-soft hover:-translate-y-0.5 transition"
        >
          + 添加知识
        </button>
      </div>

      {loading ? (
        <div className="text-center py-12 text-ink-soft">加载中...</div>
      ) : (
        <>
          {/* 全局知识库 */}
          {globalList.length > 0 && (
            <section>
              <h3 className="font-serif text-lg mb-3 flex items-center gap-2">
                <span>🌍 全局知识库</span>
                <span className="text-xs font-sans text-ink-soft">(对所有用户生效)</span>
              </h3>
              <div className="grid gap-3">
                {globalList.map((k) => (
                  <KnowledgeCard
                    key={k.id}
                    item={k}
                    editable={isAdmin}
                    onEdit={() => setEditing(k)}
                    onToggle={() => toggleEnabled(k)}
                    onDelete={() => doDelete(k)}
                  />
                ))}
              </div>
            </section>
          )}

          {/* 我的知识 */}
          <section>
            <div className="flex items-center justify-between mb-3">
              <h3 className="font-serif text-lg flex items-center gap-2">
                <span>📚 我的知识</span>
                <span className="text-xs font-sans text-ink-soft">(只在我的对话中生效)</span>
              </h3>
              <span className="text-xs text-ink-soft">
                还可添加 <span className={privateRemain <= 5 ? 'text-danger font-medium' : ''}>{privateRemain}</span> 条
              </span>
            </div>
            {privateList.length === 0 ? (
              <div className="bg-paper rounded-2xl border border-line p-10 text-center text-ink-soft text-sm">
                还没有添加任何知识。点右上角「+ 添加知识」开始吧
                <div className="mt-3 text-xs">
                  比如：「我是程序员,聊技术用通俗语言」「我对花生过敏,不要推荐含花生的食谱」
                </div>
              </div>
            ) : (
              <div className="grid gap-3">
                {privateList.map((k) => (
                  <KnowledgeCard
                    key={k.id}
                    item={k}
                    editable={true}
                    onEdit={() => setEditing(k)}
                    onToggle={() => toggleEnabled(k)}
                    onDelete={() => doDelete(k)}
                  />
                ))}
              </div>
            )}
          </section>
        </>
      )}

      {editing !== null && (
        <EditModal
          item={editing === 'new' ? null : editing}
          canSetGlobal={isAdmin}
          onClose={() => setEditing(null)}
          onSaved={() => {
            setEditing(null);
            refresh();
          }}
        />
      )}
    </div>
  );
}

function KnowledgeCard({
  item,
  editable,
  onEdit,
  onToggle,
  onDelete,
}: {
  item: KnowledgeBaseVo;
  editable: boolean;
  onEdit: () => void;
  onToggle: () => void;
  onDelete: () => void;
}) {
  const enabled = item.enabled === 1;
  return (
    <article
      className={`bg-paper rounded-2xl border p-5 shadow-soft transition ${
        enabled ? 'border-line' : 'border-line opacity-60'
      }`}
    >
      <header className="flex items-start gap-3 mb-2">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 flex-wrap mb-1">
            <h4 className="font-medium text-[15px] truncate">{item.title}</h4>
            {item.scope === 'global' && (
              <span className="text-[10px] bg-gold/20 text-clay px-2 py-0.5 rounded-full">全局</span>
            )}
            {!enabled && (
              <span className="text-[10px] bg-ink/10 text-ink-soft px-2 py-0.5 rounded-full">已禁用</span>
            )}
          </div>
          <p className="text-sm text-ink-soft leading-relaxed whitespace-pre-wrap line-clamp-3 break-words">
            {item.content}
          </p>
        </div>
        <button
          onClick={onToggle}
          disabled={!editable}
          className={`relative w-11 h-6 rounded-full transition flex-shrink-0 disabled:opacity-50 disabled:cursor-not-allowed ${
            enabled ? 'bg-sage' : 'bg-ink/20'
          }`}
          aria-label={enabled ? '禁用' : '启用'}
        >
          <span
            className={`absolute top-0.5 w-5 h-5 rounded-full bg-white shadow-sm transition-all ${
              enabled ? 'left-[22px]' : 'left-0.5'
            }`}
          />
        </button>
      </header>
      {editable && (
        <div className="flex items-center gap-3 pt-3 mt-2 border-t border-dashed border-line text-xs text-ink-soft">
          <button onClick={onEdit} className="hover:text-ink">编辑</button>
          <button onClick={onDelete} className="hover:text-danger">删除</button>
          <span className="ml-auto">{item.content.length}/2000 字</span>
        </div>
      )}
    </article>
  );
}

function EditModal({
  item,
  canSetGlobal,
  onClose,
  onSaved,
}: {
  item: KnowledgeBaseVo | null;
  canSetGlobal: boolean;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [title, setTitle] = useState(item?.title || '');
  const [content, setContent] = useState(item?.content || '');
  const [scope, setScope] = useState<'private' | 'global'>(item?.scope || 'private');
  const [saving, setSaving] = useState(false);
  const toast = useToast((s) => s.push);

  async function save() {
    if (!title.trim() || !content.trim()) {
      toast('标题和内容都不能为空', 'error');
      return;
    }
    if (content.length > MAX_CONTENT) {
      toast(`内容不能超过 ${MAX_CONTENT} 字`, 'error');
      return;
    }
    setSaving(true);
    try {
      if (item) {
        await KnowledgeApi.update(item.id, { title: title.trim(), content });
        toast('已更新', 'ok');
      } else {
        const req: CreateKnowledgeReq = { title: title.trim(), content };
        if (canSetGlobal) req.scope = scope;
        await KnowledgeApi.create(req);
        toast('已添加', 'ok');
      }
      onSaved();
    } catch (e) {
      toast((e as ApiError).message, 'error');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 bg-ink/40 flex items-center justify-center p-4" onClick={onClose}>
      <div
        className="bg-paper rounded-2xl shadow-soft-lg w-full max-w-xl max-h-[90vh] overflow-auto"
        onClick={(e) => e.stopPropagation()}
      >
        <header className="px-6 py-4 border-b border-line flex items-center justify-between">
          <h3 className="font-serif text-lg">{item ? '编辑知识' : '添加知识'}</h3>
          <button onClick={onClose} className="text-ink-soft hover:text-ink text-xl">×</button>
        </header>
        <div className="p-6 space-y-4">
          <div>
            <label className="block text-xs text-ink-soft mb-1.5">标题</label>
            <input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              maxLength={80}
              placeholder="例如:我的职业 / 饮食偏好 / 工作方式"
              className="w-full px-4 py-2.5 rounded-xl bg-cream border border-line outline-none focus:border-terracotta focus:bg-paper text-sm"
            />
          </div>
          <div>
            <label className="block text-xs text-ink-soft mb-1.5">内容</label>
            <textarea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              rows={8}
              maxLength={MAX_CONTENT}
              placeholder="告诉 AI 你希望它怎么理解你、回答你..."
              className="w-full px-4 py-3 rounded-xl bg-cream border border-line outline-none focus:border-terracotta focus:bg-paper text-sm leading-relaxed resize-none"
            />
            <div className="text-right text-xs text-ink-soft mt-1">{content.length} / {MAX_CONTENT}</div>
          </div>
          {!item && canSetGlobal && (
            <div>
              <label className="block text-xs text-ink-soft mb-1.5">作用范围</label>
              <div className="flex gap-2">
                <button
                  onClick={() => setScope('private')}
                  className={`px-4 py-2 rounded-xl text-sm ${
                    scope === 'private' ? 'bg-terracotta text-white' : 'bg-cream-deep text-ink-soft'
                  }`}
                >
                  📚 仅自己
                </button>
                <button
                  onClick={() => setScope('global')}
                  className={`px-4 py-2 rounded-xl text-sm ${
                    scope === 'global' ? 'bg-gold text-white' : 'bg-cream-deep text-ink-soft'
                  }`}
                >
                  🌍 全局(所有用户)
                </button>
              </div>
              {scope === 'global' && (
                <p className="text-xs text-clay mt-2">
                  ⚠️ 全局知识会进入所有用户的对话上下文,请谨慎填写
                </p>
              )}
            </div>
          )}
        </div>
        <footer className="px-6 py-4 border-t border-line flex justify-end gap-2">
          <button onClick={onClose} className="px-4 py-2 text-sm text-ink-soft hover:text-ink">取消</button>
          <button
            onClick={save}
            disabled={saving}
            className="px-6 py-2 rounded-full bg-terracotta text-white text-sm disabled:opacity-50"
          >
            {saving ? '保存中...' : '保存'}
          </button>
        </footer>
      </div>
    </div>
  );
}
