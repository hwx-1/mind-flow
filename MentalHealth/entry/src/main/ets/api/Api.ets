import { Http } from './HttpClient';
import {
  UserVo, PostVo, CommentVo, AiSessionVo, AiMessageVo,
  NotificationVo, ChatConvVo, ChatMsgVo, LoginResp, PageVo,
  RegisterReq, LoginReq, CodeLoginReq, SendCodeReq, OauthLoginReq, ChangePasswordReq,
  PublishPostReq, CommentReq, CreateSessionReq, MarkReadReq,
  SendMessageReq, PublishResp, LikeResp, CollectResp, CommentResp, FriendRequestVo, FriendVo, FollowResp,
  FriendRequestReq, FriendRequestByUidReq, AnnouncementVo
} from '../model/Models';

export class AnnouncementApi {
  /** 最新一条上线公告，无则为 null */
  static latest(): Promise<AnnouncementVo | null> {
    return Http.get<AnnouncementVo | null>('/announcement/latest');
  }
}

export class AuthApi {
  static register(username: string, password: string, phone: string, code?: string): Promise<LoginResp> {
    const req: RegisterReq = { username, password, phone, code };
    return Http.post<LoginResp>('/auth/register', req);
  }
  static login(account: string, password: string): Promise<LoginResp> {
    return AuthApi.loginByPassword(account, password);
  }
  static loginByPassword(account: string, password: string): Promise<LoginResp> {
    const req: LoginReq = { account, password };
    return Http.post<LoginResp>('/auth/login', req);
  }
  static loginByCode(phone: string, code: string): Promise<LoginResp> {
    const req: CodeLoginReq = { phone, code };
    return Http.post<LoginResp>('/auth/login/code', req);
  }
  static sendCode(phone: string, scene: string = 'login'): Promise<object> {
    const req: SendCodeReq = { phone, scene };
    return Http.post('/auth/code', req);
  }
  static socialLogin(provider: string, authCode?: string): Promise<LoginResp> {
    const req: OauthLoginReq = { provider, authCode };
    return Http.post<LoginResp>(`/auth/oauth/${provider}`, req);
  }
}

export class UserApi {
  static profile(): Promise<UserVo>            { return Http.get<UserVo>('/user/profile'); }
  static profileOf(id: number): Promise<UserVo>{ return Http.get<UserVo>(`/user/profile/${id}`); }
  static search(keyword: string): Promise<UserVo[]> {
    return Http.get<UserVo[]>(`/user/search?keyword=${encodeURIComponent(keyword)}`);
  }
  static update(patch: object): Promise<object>{ return Http.put('/user/update', patch); }
  static changePassword(oldPassword: string, newPassword: string): Promise<object> {
    const req: ChangePasswordReq = { oldPassword, newPassword };
    return Http.put('/user/password', req);
  }
  static follow(userId: number): Promise<FollowResp> { return Http.post<FollowResp>(`/user/${userId}/follow`); }
  static requestFriend(userId: number, message: string): Promise<object> {
    const req: FriendRequestReq = { message };
    return Http.post(`/user/${userId}/friend/request`, req);
  }
  static requestFriendByUid(uid: string, message: string): Promise<object> {
    const req: FriendRequestByUidReq = { uid, message };
    return Http.post('/user/friend/request-by-uid', req);
  }
  static friendRequests(): Promise<FriendRequestVo[]> { return Http.get<FriendRequestVo[]>('/user/friend/requests'); }
  static friends(): Promise<FriendVo[]> { return Http.get<FriendVo[]>('/user/friends'); }
  static acceptFriend(id: number): Promise<object> { return Http.post(`/user/friend/requests/${id}/accept`); }
}

export class PostApi {
  static list(type: string, page: number, size: number): Promise<PageVo<PostVo>> {
    return Http.get<PageVo<PostVo>>(`/post/list?type=${type}&page=${page}&size=${size}`);
  }
  static search(keyword: string, page: number, size: number): Promise<PageVo<PostVo>> {
    return Http.get<PageVo<PostVo>>(`/post/search?keyword=${encodeURIComponent(keyword)}&page=${page}&size=${size}`);
  }
  static detail(id: number): Promise<PostVo>           { return Http.get<PostVo>(`/post/${id}`); }
  static publish(body: object): Promise<PublishResp>  { return Http.post(`/post/publish`, body); }
  static del(id: number): Promise<object>              { return Http.del(`/post/${id}/delete`); }
  static like(id: number): Promise<LikeResp>           { return Http.post(`/post/${id}/like`); }
  static collect(id: number): Promise<CollectResp>     { return Http.post(`/post/${id}/collect`); }
  static comments(id: number, page: number = 1): Promise<CommentVo[]> {
    return Http.get<CommentVo[]>(`/post/${id}/comments?page=${page}`);
  }
  static comment(id: number, content: string, replyId?: number): Promise<CommentResp> {
    const req: CommentReq = { content, replyId };
    return Http.post(`/post/${id}/comment`, req);
  }
  static my(page: number, size: number): Promise<PageVo<PostVo>> {
    return Http.get<PageVo<PostVo>>(`/post/my?page=${page}&size=${size}`);
  }
  static userPosts(userId: number, page: number, size: number): Promise<PageVo<PostVo>> {
    return Http.get<PageVo<PostVo>>(`/post/user/${userId}?page=${page}&size=${size}`);
  }
  static myLikes(page: number = 1, size: number = 20): Promise<PageVo<PostVo>> {
    return Http.get<PageVo<PostVo>>(`/post/my-likes?page=${page}&size=${size}`);
  }
  static myComments(): Promise<object[]> { return Http.get<object[]>('/post/my-comments'); }
}

export class AiApi {
  static sessions(business?: string): Promise<AiSessionVo[]> {
    return Http.get<AiSessionVo[]>(business ? `/ai/sessions?business=${business}` : '/ai/sessions');
  }
  static createSession(business: string, title?: string): Promise<AiSessionVo> {
    const req: CreateSessionReq = { business, title };
    return Http.post<AiSessionVo>('/ai/sessions', req);
  }
  static deleteSession(id: number): Promise<object>           { return Http.del(`/ai/sessions/${id}`); }
  static messages(id: number): Promise<AiMessageVo[]>         { return Http.get<AiMessageVo[]>(`/ai/sessions/${id}/messages`); }
}

export class MessageApi {
  static notifications(type: string, page: number = 1): Promise<NotificationVo[]> {
    return Http.get<NotificationVo[]>(`/message/notifications?type=${type}&page=${page}`);
  }
  static unreadCount(): Promise<Record<string, number>> {
    return Http.get<Record<string, number>>('/message/unread-count');
  }
  static markRead(type: string, ids?: number[]): Promise<object> {
    const req: MarkReadReq = { type, ids };
    return Http.post('/message/read', req);
  }
  static chats(): Promise<ChatConvVo[]>                       { return Http.get<ChatConvVo[]>('/message/chats'); }
  static chatWith(userId: number): Promise<ChatMsgVo[]>       { return Http.get<ChatMsgVo[]>(`/message/chats/${userId}`); }
  static send(toUserId: number, content: string, type: string = 'text'): Promise<ChatMsgVo> {
    const req: SendMessageReq = { toUserId, content, type };
    return Http.post<ChatMsgVo>('/message/send', req);
  }
}
