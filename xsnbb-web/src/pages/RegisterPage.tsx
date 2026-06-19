import { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { AuthApi } from '@/api';
import { useAuth } from '@/store/auth';
import { useToast } from '@/components/Toast';
import { ApiError } from '@/api/http';

export function RegisterPage() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [password2, setPassword2] = useState('');
  const [phone, setPhone] = useState('');
  const [code, setCode] = useState('');
  const [countdown, setCountdown] = useState(0);
  const [loading, setLoading] = useState(false);
  const setAuth = useAuth((s) => s.setAuth);
  const navigate = useNavigate();
  const toast = useToast((s) => s.push);

  useEffect(() => {
    if (countdown <= 0) return;
    const t = setTimeout(() => setCountdown(countdown - 1), 1000);
    return () => clearTimeout(t);
  }, [countdown]);

  async function sendCode() {
    if (!/^1[3-9]\d{9}$/.test(phone)) {
      toast('请输入正确的手机号', 'error');
      return;
    }
    try {
      await AuthApi.sendCode(phone, 'register');
      toast('验证码已发送', 'ok');
      setCountdown(60);
    } catch (e) {
      toast((e as ApiError).message, 'error');
    }
  }

  async function submit() {
    if (username.trim().length < 3) {
      toast('用户名至少 3 个字符', 'error');
      return;
    }
    if (password.length < 6) {
      toast('密码至少 6 位', 'error');
      return;
    }
    if (password !== password2) {
      toast('两次密码不一致', 'error');
      return;
    }
    if (!/^1[3-9]\d{9}$/.test(phone)) {
      toast('请输入正确的手机号', 'error');
      return;
    }
    setLoading(true);
    try {
      const resp = await AuthApi.register(username.trim(), password, phone, code || undefined);
      setAuth(resp.token, resp.refreshToken, resp.user);
      toast('注册成功', 'ok');
      navigate('/', { replace: true });
    } catch (e) {
      toast((e as ApiError).message, 'error');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-[calc(100vh-3rem)] flex items-center justify-center">
      <div className="w-full max-w-sm bg-paper rounded-3xl shadow-soft-lg border border-line p-10 relative overflow-hidden">
        <div className="absolute -top-16 -right-16 w-40 h-40 rounded-full bg-gradient-radial from-sage/30 to-transparent pointer-events-none" />
        <div className="relative">
          <h1 className="font-serif text-2xl font-bold text-terracotta-deep mb-1">
            注册心晴账号
          </h1>
          <p className="text-xs tracking-widest text-ink-soft mb-8">CREATE YOUR ACCOUNT</p>

          <Field label="用户名">
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              maxLength={20}
              placeholder="3-20 个字符"
              className="input"
            />
          </Field>
          <Field label="密码">
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="至少 6 位"
              className="input"
            />
          </Field>
          <Field label="确认密码">
            <input
              type="password"
              value={password2}
              onChange={(e) => setPassword2(e.target.value)}
              placeholder="再输入一次"
              className="input"
            />
          </Field>
          <Field label="手机号">
            <input
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value.replace(/\D/g, '').slice(0, 11))}
              placeholder="11 位手机号"
              className="input"
            />
          </Field>
          <Field label="验证码">
            <div className="flex gap-2">
              <input
                type="text"
                value={code}
                onChange={(e) => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                placeholder="4 位数字"
                className="input flex-1"
              />
              <button
                onClick={sendCode}
                disabled={countdown > 0}
                className="px-4 py-3 rounded-xl bg-cream-deep text-sm text-ink-soft hover:bg-line transition whitespace-nowrap disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {countdown > 0 ? `${countdown}s` : '获取验证码'}
              </button>
            </div>
          </Field>

          <button
            onClick={submit}
            disabled={loading}
            className="w-full mt-4 py-3.5 rounded-xl bg-gradient-to-br from-terracotta to-terracotta-deep text-white font-medium tracking-widest shadow-soft hover:-translate-y-0.5 transition disabled:opacity-60"
          >
            {loading ? '注册中...' : '注 册'}
          </button>

          <p className="text-center text-xs text-ink-soft mt-6 pt-5 border-t border-dashed border-line">
            已有账号？<Link to="/login" className="text-terracotta-deep hover:underline ml-1">去登录</Link>
          </p>
        </div>
        <style>{`
          .input { width: 100%; padding: 0.7rem 1rem; border: 1.5px solid #ece2d4; border-radius: 0.875rem; font-size: 0.95rem; background: #faf6f0; color: #4a3f35; transition: all .25s; outline: none; }
          .input:focus { border-color: #d98e73; background: #fffdfa; box-shadow: 0 0 0 4px rgba(217,142,115,.1); }
        `}</style>
      </div>
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="mb-3">
      <label className="block text-xs text-ink-soft mb-1.5 tracking-wider">{label}</label>
      {children}
    </div>
  );
}
