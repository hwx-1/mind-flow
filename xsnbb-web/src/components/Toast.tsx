import { create } from 'zustand';

interface Toast {
  id: number;
  msg: string;
  kind: 'info' | 'error' | 'ok';
}
interface ToastState {
  list: Toast[];
  push: (msg: string, kind?: Toast['kind']) => void;
  remove: (id: number) => void;
}

let seed = 0;
export const useToast = create<ToastState>((set, get) => ({
  list: [],
  push: (msg, kind = 'info') => {
    const id = ++seed;
    set({ list: [...get().list, { id, msg, kind }] });
    setTimeout(() => get().remove(id), 2800);
  },
  remove: (id) => set({ list: get().list.filter((t) => t.id !== id) }),
}));

export function ToastContainer() {
  const list = useToast((s) => s.list);
  if (!list.length) return null;
  return (
    <div className="fixed top-6 left-1/2 -translate-x-1/2 z-[300] flex flex-col gap-2 items-center">
      {list.map((t) => (
        <div
          key={t.id}
          className={`px-5 py-2.5 rounded-full text-sm shadow-soft-lg backdrop-blur-sm
            ${t.kind === 'error' ? 'bg-danger/95 text-white' :
              t.kind === 'ok' ? 'bg-sage-deep/95 text-white' :
              'bg-ink/85 text-white'}`}
        >
          {t.msg}
        </div>
      ))}
    </div>
  );
}
