export interface AnnouncementVo {
  id: number;
  title?: string;
  content: string;
  status?: number;
  createdAt?: string;
}

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
  followed?: boolean;
  followerCount?: number;
  followingCount?: number;
  friend?: boolean;
  friendRequestStatus?: number;
}

export interface FriendRequestVo {
  id: number;
  fromUser: number;
  toUser: number;
  message?: string;
  status: number;
  createdAt: string;
  nickname?: string;
  avatar?: string;
  uid?: string | number;
}

export interface FriendVo {
  id: number;
  uid?: string | number;
  username?: string;
  nickname?: string;
  avatar?: string;
  profileStatus?: string;
  online?: boolean;
  friendAt?: string;
}

export interface FollowResp {
  followed: boolean;
}

export interface PostVo {
  id: number;
  userId: number;
  locationLabel?: string;
  latitude?: number;
  longitude?: number;
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

// API请求参数接口
export interface RegisterReq {
  username: string;
  password: string;
  phone: string;
  code?: string;
}

export interface LoginReq {
  account: string;
  password: string;
}

export interface CodeLoginReq {
  phone: string;
  code: string;
}

export interface SendCodeReq {
  phone: string;
  scene?: string;
}

export interface OauthLoginReq {
  provider: string;
  authCode?: string;
}

export interface ChangePasswordReq {
  oldPassword: string;
  newPassword: string;
}

export interface FriendRequestReq {
  message: string;
}

export interface FriendRequestByUidReq {
  uid: string;
  message: string;
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

export interface CommentReq {
  content: string;
  replyId?: number;
}

export interface CreateSessionReq {
  business: string;
  title?: string;
}

export interface MarkReadReq {
  type: string;
  ids?: number[];
}

export interface SendMessageReq {
  toUserId: number;
  content: string;
  type: string;
}

export interface ChatReq {
  sessionId: number;
  content: string;
}

export interface WsChatPayload {
  toUserId: number;
  content: string;
  type: string;
}

export interface UserUpdateReq {
  nickname?: string;
  bio?: string;
  avatar?: string;
  profileStatus?: string;
  gender?: number;
}

// API响应接口
export interface PublishResp {
  id: number;
}

export interface LikeResp {
  liked: boolean;
}

export interface CollectResp {
  collected: boolean;
}

export interface CommentResp {
  id: number;
}

export interface UploadData {
  url: string;
}
