import { NavLink, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '@/store/auth';
import { Avatar } from './Avatar';

export function TopNav() {
  const user = useAuth((s) => s.user);
  const isAdmin = useAuth((s) => s.isAdmin)();
  const clear = useAuth((s) => s.clear);
  const navigate = useNavigate();
  const loc = useLocation();

  function logout() {
    clear();
    navigate('/login');
  }

  // 登录/注册页不显示顶部导航
  if (loc.pathname === '/login' || loc.pathname === '/register') return null;
  if (!user) return null;

  const linkClass = ({ isActive }: { isActive: boolean }) =>
    `px-4 py-2 rounded-full text-sm transition-all ${
      isActive
        ? 'bg-terracotta text-white shadow-soft'
        : 'text-ink-soft hover:text-ink hover:bg-cream-deep'
    }`;

  return (
    <header className="sticky top-0 z-30 bg-paper/80 backdrop-blur-md border-b border-line">
      <div className="max-w-5xl mx-auto px-6 h-16 flex items-center gap-6">
        <div
          className="font-serif text-xl font-bold text-terracotta-deep cursor-pointer"
          onClick={() => navigate('/')}
        >
          心晴<span className="text-sage-deep mx-1">·</span>
          <span className="text-ink text-base font-medium">Mind Flow</span>
        </div>

        <nav className="flex items-center gap-1">
          <NavLink to="/" end className={linkClass}>社区</NavLink>
          <NavLink to="/ai" className={linkClass}>AI 咨询</NavLink>
          <NavLink to="/knowledge" className={linkClass}>知识库</NavLink>
          <NavLink to="/messages" className={linkClass}>消息</NavLink>
          <NavLink to="/mine" className={linkClass}>我的</NavLink>
        </nav>

        <div className="ml-auto flex items-center gap-3">
          {isAdmin && (
            <a
              href="/admin/"
              target="_blank"
              rel="noopener"
              className="px-3 py-1.5 rounded-full text-xs bg-gold/15 text-clay border border-gold/30 hover:bg-gold/25 transition"
            >
              进入后台 →
            </a>
          )}
          <div className="flex items-center gap-2 px-2 py-1 rounded-full bg-cream-deep">
            <Avatar src={user.avatar} name={user.nickname || user.username} size={28} />
            <span className="text-sm pr-2">{user.nickname || user.username}</span>
          </div>
          <button
            onClick={logout}
            className="text-xs text-ink-soft hover:text-danger transition"
          >
            退出
          </button>
        </div>
      </div>
    </header>
  );
}
