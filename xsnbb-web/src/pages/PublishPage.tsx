import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { PostApi, UploadApi } from '@/api';
import { useToast } from '@/components/Toast';
import { ApiError } from '@/api/http';

export function PublishPage() {
  const [content, setContent] = useState('');
  const [images, setImages] = useState<string[]>([]);
  const [topic, setTopic] = useState('');
  const [uploading, setUploading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const navigate = useNavigate();
  const toast = useToast((s) => s.push);

  async function onFiles(e: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(e.target.files || []);
    if (!files.length) return;
    if (images.length + files.length > 9) {
      toast('最多 9 张图', 'error');
      return;
    }
    setUploading(true);
    try {
      const uploaded: string[] = [];
      for (const f of files) {
        const r = await UploadApi.image(f);
        uploaded.push(r.url);
      }
      setImages([...images, ...uploaded]);
    } catch (e) {
      toast((e as ApiError).message || '上传失败', 'error');
    } finally {
      setUploading(false);
      e.target.value = '';
    }
  }

  async function submit() {
    if (!content.trim()) {
      toast('内容不能为空', 'error');
      return;
    }
    setSubmitting(true);
    try {
      await PostApi.publish({
        content: content.trim(),
        topic: topic.trim() || undefined,
        images: images.length ? images : undefined,
      });
      toast('发布成功', 'ok');
      navigate('/', { replace: true });
    } catch (e) {
      toast((e as ApiError).message, 'error');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="max-w-2xl mx-auto">
      <div className="flex items-center justify-between mb-5">
        <button onClick={() => navigate(-1)} className="text-sm text-ink-soft hover:text-ink">← 返回</button>
        <h1 className="font-serif text-xl">发布想法</h1>
        <button
          onClick={submit}
          disabled={submitting || !content.trim()}
          className="px-5 py-2 rounded-full bg-terracotta text-white text-sm disabled:opacity-50"
        >
          {submitting ? '发布中...' : '发布'}
        </button>
      </div>

      <div className="bg-paper rounded-2xl border border-line p-5 shadow-soft">
        <textarea
          value={content}
          onChange={(e) => setContent(e.target.value)}
          placeholder="此刻在想什么？把心事温柔地放下来..."
          maxLength={2000}
          rows={8}
          className="w-full p-3 bg-cream rounded-xl text-[15px] leading-relaxed outline-none resize-none focus:bg-paper border border-transparent focus:border-line transition"
        />
        <div className="text-right text-xs text-ink-soft mt-1">{content.length} / 2000</div>

        {images.length > 0 && (
          <div className="mt-3 grid grid-cols-3 gap-2">
            {images.map((u, i) => (
              <div key={i} className="relative aspect-square">
                <img src={u} alt="" className="w-full h-full rounded-lg object-cover bg-cream-deep" />
                <button
                  onClick={() => setImages(images.filter((_, x) => x !== i))}
                  className="absolute top-1 right-1 w-6 h-6 rounded-full bg-ink/70 text-white text-xs hover:bg-danger"
                >
                  ×
                </button>
              </div>
            ))}
          </div>
        )}

        <div className="mt-4 flex items-center gap-3 flex-wrap">
          <label className="px-4 py-2 rounded-full bg-cream-deep text-sm text-ink-soft hover:text-ink cursor-pointer">
            {uploading ? '上传中...' : '+ 图片'}
            <input type="file" accept="image/*" multiple onChange={onFiles} className="hidden" disabled={uploading} />
          </label>
          <input
            value={topic}
            onChange={(e) => setTopic(e.target.value)}
            placeholder="# 话题(可选)"
            className="px-4 py-2 rounded-full bg-cream-deep text-sm outline-none focus:bg-cream"
            maxLength={20}
          />
        </div>
      </div>
    </div>
  );
}
