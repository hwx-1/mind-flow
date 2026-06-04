import { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { AuthApi } from '@/api';
import { useAuth } from '@/store/auth';
import { useToast } from '@/components/Toast';
import { ApiError } from '@/api/http';

type Mode = 'password' | 'code';

export function LoginPage() {
  const [mode, setMode] = useState<Mode>('password');
  const [account, setAccount] = useState('');
  const [password, setPassword] = useState('');
  const [phone, setPhone] = useState('');
  const [code, setCode] = useState('');
  const [loading, setLoading] = useState(false);
  const [countdown, setCountdown] = useState(0);
  const setAuth = useAuth((s) => s.setAuth);
  const isLogin = useAuth((s) => s.isLogin)();
  const navigate = useNavigate();
  const location = useLocation();
  const toast = useToast((s) => s.push);

  useEffect(() => {
    if (isLogin) {
      const from = (location.state as { from?: string })?.from || '/';
      navigate(from, { replace: true });
    }
  }, [isLogin]);

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
      await AuthApi.sendCode(phone, 'login');
      toast('验证码已发送', 'ok');
      setCountdown(60);
    } catch (e) {
      toast((e as ApiError).message, 'error');
    }
  }

  async function doLogin() {
    setLoading(true);
    try {
      let resp;
      if (mode === 'password') {
        if (!account || !password) {
          toast('请输入账号和密码', 'error');
          return;
        }
        resp = await AuthApi.loginByPassword(account, password);
      } else {
        if (!/^1[3-9]\d{9}$/.test(phone) || code.length < 4) {
          toast('请输入正确的手机号和验证码', 'error');
          return;
        }
        resp = await AuthApi.loginByCode(phone, code);
      }
      setAuth(resp.token, resp.refreshToken, resp.user);
      toast('登录成功', 'ok');
    } catch (e) {
      toast((e as ApiError).message || '登录失败', 'error');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-[calc(100vh-3rem)] flex items-center justify-center">
      <div className="w-full max-w-sm bg-paper rounded-3xl shadow-soft-lg border border-line p-10 relative overflow-hidden">
        <div className="absolute -top-16 -right-16 w-40 h-40 rounded-full bg-gradient-radial from-gold/30 to-transparent pointer-events-none" />
        <div className="relative">
          <h1 className="font-serif text-3xl font-bold text-terracotta-deep mb-1">
            心晴 <span className="text-sage-deep">·</span> Mind Flow
          </h1>
          <p className="text-xs tracking-widest text-ink-soft mb-8">MINDFUL · WARM · TOGETHER</p>

          {/* Tab 切换 */}
          <div className="flex gap-1 mb-6 p-1 bg-cream-deep rounded-full">
            <button
              onClick={() => setMode('password')}
              className={`flex-1 py-2 text-sm rounded-full transition ${
                mode === 'password' ? 'bg-paper shadow-sm text-ink' : 'text-ink-soft'
              }`}
            >
              密码登录
            </button>
            <button
              onClick={() => setMode('code')}
              className={`flex-1 py-2 text-sm rounded-full transition ${
                mode === 'code' ? 'bg-paper shadow-sm text-ink' : 'text-ink-soft'
              }`}
            >
              验证码登录
            </button>
          </div>

          {mode === 'password' ? (
            <>
              <Field label="账号">
                <input
                  type="text"
                  value={account}
                  onChange={(e) => setAccount(e.target.value)}
                  placeholder="用户名 / 手机号"
                  className="input"
                  autoComplete="username"
                />
              </Field>
              <Field label="密码">
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="请输入密码"
                  className="input"
                  autoComplete="current-password"
                  onKeyDown={(e) => e.key === 'Enter' && doLogin()}
                />
              </Field>
            </>
          ) : (
            <>
              <Field label="手机号">
                <input
                  type="tel"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value.replace(/\D/g, '').slice(0, 11))}
                  placeholder="11 位手机号"
                  className="input"
                  autoComplete="tel"
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
                    onKeyDown={(e) => e.key === 'Enter' && doLogin()}
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
            </>
          )}

          <button
            onClick={doLogin}
            disabled={loading}
            className="w-full mt-4 py-3.5 rounded-xl bg-gradient-to-br from-terracotta to-terracotta-deep text-white font-medium tracking-widest shadow-soft hover:-translate-y-0.5 transition disabled:opacity-60 disabled:translate-y-0"
          >
            {loading ? '登录中...' : '登 录'}
          </button>

          <p className="text-center text-xs text-ink-soft mt-6 pt-5 border-t border-dashed border-line leading-relaxed">
            还没有账号？<a href="/register" className="text-terracotta-deep hover:underline">立即注册</a>
            <br />
            管理员登录后右上角会出现「进入后台」入口
          </p>
        </div>
      </div>
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="mb-4">
      <label className="block text-xs text-ink-soft mb-1.5 tracking-wider">{label}</label>
      {children}
      <style>{`
        .input {
          width: 100%;
          padding: 0.8rem 1rem;
          border: 1.5px solid #ece2d4;
          border-radius: 0.875rem;
          font-size: 0.95rem;
          background: #faf6f0;
          color: #4a3f35;
          transition: all .25s;
          outline: none;
        }
        .input:focus { border-color: #d98e73; background: #fffdfa; box-shadow: 0 0 0 4px rgba(217,142,115,.1); }
      `}</style>
    </div>
  );
}
