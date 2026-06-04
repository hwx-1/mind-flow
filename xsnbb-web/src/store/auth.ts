import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { UserVo } from '@/types';

interface AuthState {
  token: string;
  refreshToken: string;
  user: UserVo | null;
  setAuth: (token: string, refreshToken: string, user: UserVo) => void;
  setUser: (user: UserVo) => void;
  clear: () => void;
  isLogin: () => boolean;
  isAdmin: () => boolean;
}

export const useAuth = create<AuthState>()(
  persist(
    (set, get) => ({
      token: '',
      refreshToken: '',
      user: null,
      setAuth: (token, refreshToken, user) => set({ token, refreshToken, user }),
      setUser: (user) => set({ user }),
      clear: () => set({ token: '', refreshToken: '', user: null }),
      isLogin: () => !!get().token,
      isAdmin: () => get().user?.role === 'admin',
    }),
    { name: 'xsnbb-auth' }
  )
);
