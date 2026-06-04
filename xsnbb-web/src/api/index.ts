import { http, uploadFile } from './http';
import type {
  LoginResp, UserVo, PostVo, CommentVo, PageVo,
  AiSessionVo, AiMessageVo, PublishPostReq, LikeResp, CollectResp,
  KnowledgeBaseVo, CreateKnowledgeReq, UpdateKnowledgeReq,
  NotificationVo, ChatConvVo, ChatMsgVo, FriendRequestVo, UnreadCount, FollowResp,
  AnnouncementVo,
} from '@/types';

export const AnnouncementApi = {
  /** 最新一条上线公告（公开），无则 null */
  latest: () => http.get<AnnouncementVo | null>('/announcement/latest'),
  /** 公告列表（管理员） */
  list: () => http.get<AnnouncementVo[]>('/admin/announcements'),
  /** 发布公告（管理员） */
  publish: (title: string, content: string) =>
    http.post<AnnouncementVo>('/admin/announcements', { title, content }),
  /** 下线公告（管理员） */
  offline: (id: number) => http.post<unknown>(`/admin/announcements/${id}/offline`),
};

export const AuthApi = {
  loginByPassword: (account: string, password: string) =>
    http.post<LoginResp>('/auth/login', { account, password }),
  loginByCode: (phone: string, code: string) =>
    http.post<LoginResp>('/auth/login/code', { phone, code }),
  sendCode: (phone: string, scene = 'login') =>
    http.post<unknown>('/auth/code', { phone, scene }),
  register: (username: string, password: string, phone: string, code?: string) =>
    http.post<LoginResp>('/auth/register', { username, password, phone, code }),
};

export const UserApi = {
  profile: () => http.get<UserVo>('/user/profile'),
  profileOf: (id: number) => http.get<UserVo>(`/user/profile/${id}`),
  update: (patch: Partial<UserVo>) => http.put<unknown>('/user/update', patch),
  search: (keyword: string) =>
    http.get<UserVo[]>(`/user/search?keyword=${encodeURIComponent(keyword)}`),
  follow: (userId: number) => http.post<FollowResp>(`/user/${userId}/follow`),
  changePassword: (oldPassword: string, newPassword: string) =>
    http.put<unknown>('/user/password', { oldPassword, newPassword }),
  requestFriend: (userId: number, message: string) =>
    http.post<unknown>(`/user/${userId}/friend/request`, { message }),
  requestFriendByUid: (uid: string, message: string) =>
    http.post<unknown>('/user/friend/request-by-uid', { uid, message }),
  friendRequests: () => http.get<FriendRequestVo[]>('/user/friend/requests'),
  acceptFriend: (id: number) => http.post<unknown>(`/user/friend/requests/${id}/accept`),
};

export const PostApi = {
  list: (type: string, page: number, size: number) =>
    http.get<PageVo<PostVo>>(`/post/list?type=${type}&page=${page}&size=${size}`),
  detail: (id: number) => http.get<PostVo>(`/post/${id}`),
  publish: (body: PublishPostReq) =>
    http.post<{ id: number }>('/post/publish', body),
  like: (id: number) => http.post<LikeResp>(`/post/${id}/like`),
  collect: (id: number) => http.post<CollectResp>(`/post/${id}/collect`),
  comments: (id: number, page = 1) =>
    http.get<CommentVo[]>(`/post/${id}/comments?page=${page}`),
  comment: (id: number, content: string, replyId?: number) =>
    http.post<{ id: number }>(`/post/${id}/comment`, { content, replyId }),
  my: (page: number, size: number) =>
    http.get<PageVo<PostVo>>(`/post/my?page=${page}&size=${size}`),
  myLikes: (page = 1, size = 20) =>
    http.get<PageVo<PostVo>>(`/post/my-likes?page=${page}&size=${size}`),
  myComments: () => http.get<Record<string, unknown>[]>('/post/my-comments'),
  userPosts: (userId: number, page: number, size: number) =>
    http.get<PageVo<PostVo>>(`/post/user/${userId}?page=${page}&size=${size}`),
};

export const MessageApi = {
  notifications: (type: string, page = 1) =>
    http.get<NotificationVo[]>(`/message/notifications?type=${type}&page=${page}`),
  unreadCount: () => http.get<UnreadCount>('/message/unread-count'),
  markRead: (type: string, ids?: number[]) =>
    http.post<unknown>('/message/read', { type, ids }),
  chats: () => http.get<ChatConvVo[]>('/message/chats'),
  chatWith: (userId: number) => http.get<ChatMsgVo[]>(`/message/chats/${userId}`),
  send: (toUserId: number, content: string, type = 'text') =>
    http.post<ChatMsgVo>('/message/send', { toUserId, content, type }),
};

export const AiApi = {
  sessions: (business?: string) =>
    http.get<AiSessionVo[]>(business ? `/ai/sessions?business=${business}` : '/ai/sessions'),
  createSession: (business: string, title?: string) =>
    http.post<AiSessionVo>('/ai/sessions', { business, title }),
  deleteSession: (id: number) => http.del<unknown>(`/ai/sessions/${id}`),
  messages: (id: number) => http.get<AiMessageVo[]>(`/ai/sessions/${id}/messages`),
};

export const UploadApi = {
  image: (file: File) => uploadFile('/upload/image', file),
};

// ★ 阶段 2 新增
export const KnowledgeApi = {
  list: () => http.get<KnowledgeBaseVo[]>('/knowledge'),
  create: (req: CreateKnowledgeReq) => http.post<KnowledgeBaseVo>('/knowledge', req),
  update: (id: number, req: UpdateKnowledgeReq) =>
    http.put<KnowledgeBaseVo>(`/knowledge/${id}`, req),
  delete: (id: number) => http.del<unknown>(`/knowledge/${id}`),
};
