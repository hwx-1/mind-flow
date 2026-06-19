export interface UserVo {
  id: number;
  username: string;
  nickname?: string;
  avatar?: string;
  bio?: string;
  gender?: number;
  birthday?: string;
  phone?: string;
}

export interface PostVo {
  id: number;
  userId: number;
  nickname: string;
  avatar: string;
  content: string;
  images?: string[];
  video?: string;
  topic?: string;
  likeCount: number;
  commentCount: number;
  liked: boolean;
  collected: boolean;
  createdAt: string;
}

export interface CommentVo {
  id: number;
  nickname?: string;
  avatar?: string;
  content: string;
  replyId?: number;
  createdAt: string;
}

export interface AiSessionVo {
  id: number;
  business: string;
  title: string;
  lastMsg?: string;
  updatedAt: string;
}

export interface AiMessageVo {
  id: number;
  sessionId: number;
  role: string;        // user / assistant
  content: string;
  createdAt: string;
}

export interface NotificationVo {
  id: number;
  type: string;        // like / comment / follow
  content: string;
  targetId?: number;
  isRead: number;
  nickname?: string;
  avatar?: string;
  createdAt: string;
}

export interface ChatConvVo {
  userId: number;
  nickname?: string;
  avatar?: string;
  lastMessage?: string;
  unreadCount?: number;
  updatedAt: string;
}

export interface ChatMsgVo {
  id: number;
  fromUser: number;
  toUser: number;
  content: string;
  type: string;
  createdAt: string;
}

export interface LoginResp {
  token: string;
  refreshToken: string;
  user: UserVo;
}

export interface PageVo<T> {
  total: number;
  list: T[];
}
