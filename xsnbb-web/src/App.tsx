import { Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '@/store/auth';
import { TopNav } from '@/components/TopNav';
import { ToastContainer } from '@/components/Toast';
import { LoginPage } from '@/pages/LoginPage';
import { RegisterPage } from '@/pages/RegisterPage';
import { CommunityPage } from '@/pages/CommunityPage';
import { PostDetailPage } from '@/pages/PostDetailPage';
import { PublishPage } from '@/pages/PublishPage';
import { AiHomePage } from '@/pages/AiHomePage';
import { AiChatPage } from '@/pages/AiChatPage';
import { MinePage } from '@/pages/MinePage';
import { KnowledgePage } from '@/pages/KnowledgePage';
import { MyLikesPage } from '@/pages/MyLikesPage';
import { MyCommentsPage } from '@/pages/MyCommentsPage';
import { MessagesPage } from '@/pages/MessagesPage';
import { ChatRoomPage } from '@/pages/ChatRoomPage';
import { AddFriendPage } from '@/pages/AddFriendPage';
import { FriendRequestsPage } from '@/pages/FriendRequestsPage';
import { UserPage } from '@/pages/UserPage';
import { SettingsPage } from '@/pages/SettingsPage';
import { AdminAnnouncementsPage } from '@/pages/AdminAnnouncementsPage';
import { AnnouncementModal } from '@/components/AnnouncementModal';

function Protected({ children }: { children: React.ReactNode }) {
  const isLogin = useAuth((s) => s.isLogin)();
  const loc = useLocation();
  if (!isLogin) return <Navigate to="/login" state={{ from: loc.pathname }} replace />;
  return <>{children}</>;
}

function AdminOnly({ children }: { children: React.ReactNode }) {
  const isLogin = useAuth((s) => s.isLogin)();
  const isAdmin = useAuth((s) => s.isAdmin)();
  const loc = useLocation();
  if (!isLogin) return <Navigate to="/login" state={{ from: loc.pathname }} replace />;
  if (!isAdmin) return <Navigate to="/" replace />;
  return <>{children}</>;
}

export default function App() {
  return (
    <>
      <TopNav />
      <main className="max-w-5xl mx-auto px-4 sm:px-6 py-6">
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/register" element={<RegisterPage />} />
          <Route path="/" element={<Protected><CommunityPage /></Protected>} />
          <Route path="/post/:id" element={<Protected><PostDetailPage /></Protected>} />
          <Route path="/publish" element={<Protected><PublishPage /></Protected>} />
          <Route path="/ai" element={<Protected><AiHomePage /></Protected>} />
          <Route path="/ai/chat/:id" element={<Protected><AiChatPage /></Protected>} />
          <Route path="/mine" element={<Protected><MinePage /></Protected>} />
          <Route path="/mine/likes" element={<Protected><MyLikesPage /></Protected>} />
          <Route path="/mine/comments" element={<Protected><MyCommentsPage /></Protected>} />
          <Route path="/knowledge" element={<Protected><KnowledgePage /></Protected>} />
          <Route path="/messages" element={<Protected><MessagesPage /></Protected>} />
          <Route path="/chat/:userId" element={<Protected><ChatRoomPage /></Protected>} />
          <Route path="/friends/add" element={<Protected><AddFriendPage /></Protected>} />
          <Route path="/friends/requests" element={<Protected><FriendRequestsPage /></Protected>} />
          <Route path="/user/:id" element={<Protected><UserPage /></Protected>} />
          <Route path="/settings" element={<Protected><SettingsPage /></Protected>} />
          <Route path="/announcements/manage" element={<AdminOnly><AdminAnnouncementsPage /></AdminOnly>} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </main>
      <AnnouncementModal />
      <ToastContainer />
    </>
  );
}
