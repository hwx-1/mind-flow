import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { UserApi } from '@/api';
import { useAuth } from '@/store/auth';
import { useToast } from '@/components/Toast';
import { ApiError } from '@/api/http';

export function SettingsPage() {
  const [oldPw, setOldPw] = useState('');
  const [newPw, setNewPw] = useState('');
  const [newPw2, setNewPw2] = useState('');
  const [saving, setSaving] = useState(false);
  const clear = useAuth((s) => s.clear);
  const navigate = useNavigate();
  const toast = useToast((s) => s.push);

  async function changePassword() {
    if (newPw.length < 6) { toast('新密码至少 6 位', 'error'); return; }
    if (newPw !== newPw2) { toast('两次密码不一致', 'error'); return; }
    setSaving(true);
    try {
      await UserApi.changePassword(oldPw, newPw);
      toast('已修改,请重新登录', 'ok');
      setTimeout(() => { clear(); navigate('/login'); }, 1200);
    } catch (e) {
      toast((e as ApiError).message, 'error');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="max-w-xl mx-auto space-y-5">
      <button onClick={() => navigate(-1)} className="text-sm text-ink-soft hover:text-ink">← 返回</button>
      <h1 className="font-serif text-2xl">设置</h1>

      <section className="bg-paper rounded-2xl border border-line shadow-soft">
        <header className="p-5 border-b border-line">
          <h3 className="font-serif text-base">修改密码</h3>
        </header>
        <div className="p-5 space-y-3">
          <Input label="当前密码" value={oldPw} onChange={setOldPw} type="password" placeholder="输入当前密码" />
          <Input label="新密码"   value={newPw} onChange={setNewPw} type="password" placeholder="至少 6 位" />
          <Input label="确认新密码" value={newPw2} onChange={setNewPw2} type="password" placeholder="再输一次" />
          <button
            onClick={changePassword}
            disabled={saving || !oldPw || !newPw}
            className="w-full mt-2 py-2.5 rounded-xl bg-terracotta text-white text-sm disabled:opacity-50"
          >
            {saving ? '保存中...' : '修改密码'}
          </button>
        </div>
      </section>

      <section className="bg-paper rounded-2xl border border-line shadow-soft">
        <header className="p-5 border-b border-line">
          <h3 className="font-serif text-base">关于</h3>
        </header>
        <dl className="p-5 text-sm space-y-2">
          <Row label="应用">心晴 Mind Flow · Web</Row>
          <Row label="域名">xsnbb.xyz</Row>
          <Row label="备案">辽ICP备2025057641号</Row>
          <Row label="技术">React + TypeScript + Spring Boot</Row>
        </dl>
      </section>

      <button
        onClick={() => { clear(); navigate('/login'); }}
        className="w-full py-3 rounded-2xl bg-danger/10 text-danger text-sm hover:bg-danger hover:text-white transition"
      >
        退出登录
      </button>
    </div>
  );
}

function Input({ label, value, onChange, type = 'text', placeholder }: { label: string; value: string; onChange: (s: string) => void; type?: string; placeholder?: string; }) {
  return (
    <div>
      <label className="block text-xs text-ink-soft mb-1.5">{label}</label>
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="w-full px-4 py-2.5 rounded-xl bg-cream border border-line outline-none focus:border-terracotta focus:bg-paper text-sm"
      />
    </div>
  );
}

function Row({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="flex justify-between items-center">
      <dt className="text-ink-soft">{label}</dt>
      <dd>{children}</dd>
    </div>
  );
}
