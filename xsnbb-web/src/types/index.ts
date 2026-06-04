// 统一响应
export interface ApiResult<T> {
  code: number;
  msg: string;
  data: T;
}

export interface PageVo<T> {
  total: number;
  list?: T[];
  records?: T[];  // MyBatis-Plus 分页用 records,业务接口用 list,两者都兼容
}

// 公告
export interface AnnouncementVo {
  id: number;
  title?: string;
  content: string;
  status?: number;
  createdAt?: string;
}

// User
export interface UserVo {
  id: number;
  uid?: string | number;
  username: string;
  nickname?: string;
  avatar?: string;
  bio?: string;
  profileStatus?: string;
  gender?: number;
  birthday?: string;
  phone?: string;
  role?: 'admin' | 'user';
  status?: number;
  followed?: boolean;
  followerCount?: number;
  followingCount?: number;
  friend?: boolean;
  friendRequestStatus?: number;
}

// Auth
export interface LoginResp {
  token: string;
  refreshToken: string;
  user: UserVo;
}

// Post
export interface PostVo {
  id: number;
  userId: number;
  nickname?: string;
  avatar?: string;
  content: string;
  images?: string[];
  video?: string;
  topic?: string;
  locationLabel?: string;
  latitude?: number;
  longitude?: number;
  likeCount: number;
  commentCount: number;
  liked?: boolean;
  collected?: boolean;
  createdAt: string;
  status?: number;
}

export interface CommentVo {
  id: number;
  nickname?: string;
  avatar?: string;
  content: string;
  replyId?: number;
  createdAt: string;
}

export interface PublishPostReq {
  content: string;
  topic?: string;
  images?: string[];
  video?: string;
  locationLabel?: string;
  latitude?: number;
  longitude?: number;
  address?: string;
}

// AI
export interface AiSessionVo {
  id: number;
  business: 'mental' | 'study' | 'general';
  title: string;
  lastMsg?: string;
  updatedAt: string;
  createdAt?: string;
}

export interface AiMessageVo {
  id: number;
  role: 'user' | 'assistant' | 'system';
  content: string;
  createdAt: string;
}

// ★ 阶段 2 新增: 知识库
export interface KnowledgeBaseVo {
  id: number;
  userId: number;
  scope: 'private' | 'global';
  title: string;
  content: string;
  enabled: number;
  createdAt: string;
  updatedAt: string;
}

export interface CreateKnowledgeReq {
  title: string;
  content: string;
  scope?: 'private' | 'global';
}

export interface UpdateKnowledgeReq {
  title?: string;
  content?: string;
  enabled?: number;
}

// ★ 阶段 3 新增
export interface NotificationVo {
  id: number;
  type: string;        // like / comment / follow / friend
  fromUser?: number;
  nickname?: string;
  avatar?: string;
  content: string;
  targetId?: number;
  isRead: number;
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
  isRead?: number;
  createdAt: string;
}

export interface FriendRequestVo {
  id: number;
  fromUser: number;
  nickname?: string;
  avatar?: string;
  message: string;
  status: number;       // 0 待处理 / 1 已通过 / 2 已拒绝
  createdAt: string;
}

export interface UnreadCount {
  like?: number;
  comment?: number;
  follow?: number;
  friend?: number;
  chat?: number;
  [k: string]: number | undefined;
}

// 业务通用
export interface LikeResp { liked: boolean; }
export interface CollectResp { collected: boolean; }
export interface FollowResp { followed: boolean; }
