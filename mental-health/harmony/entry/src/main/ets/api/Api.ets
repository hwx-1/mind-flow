import { Http } from './HttpClient';
import {
  UserVo, PostVo, CommentVo, AiSessionVo, AiMessageVo,
  NotificationVo, ChatConvVo, ChatMsgVo, LoginResp, PageVo
} from '../model/Models';

export class AuthApi {
  static register(username: string, password: string, phone: string, code?: string): Promise<LoginResp> {
    return Http.post<LoginResp>('/auth/register', { username, password, phone, code });
  }
  static login(account: string, password: string): Promise<LoginResp> {
    return Http.post<LoginResp>('/auth/login', { account, password });
  }
  static sendCode(phone: string): Promise<object> {
    return Http.post('/auth/code', { phone });
  }
}

export class UserApi {
  static profile(): Promise<UserVo>            { return Http.get<UserVo>('/user/profile'); }
  static profileOf(id: number): Promise<UserVo>{ return Http.get<UserVo>(`/user/profile/${id}`); }
  static update(patch: object): Promise<object>{ return Http.put('/user/update', patch); }
  static changePassword(oldPassword: string, newPassword: string): Promise<object> {
    return Http.put('/user/password', { oldPassword, newPassword });
  }
}

export class PostApi {
  static list(type: string, page: number, size: number): Promise<PageVo<PostVo>> {
    return Http.get<PageVo<PostVo>>(`/post/list?type=${type}&page=${page}&size=${size}`);
  }
  static detail(id: number): Promise<PostVo>           { return Http.get<PostVo>(`/post/${id}`); }
  static publish(body: object): Promise<{ id: number }>{ return Http.post(`/post/publish`, body); }
  static del(id: number): Promise<object>              { return Http.del(`/post/${id}/delete`); }
  static like(id: number): Promise<{ liked: boolean }> { return Http.post(`/post/${id}/like`); }
  static collect(id: number): Promise<{ collected: boolean }> { return Http.post(`/post/${id}/collect`); }
  static comments(id: number, page: number = 1): Promise<CommentVo[]> {
    return Http.get<CommentVo[]>(`/post/${id}/comments?page=${page}`);
  }
  static comment(id: number, content: string, replyId?: number): Promise<{ id: number }> {
    return Http.post(`/post/${id}/comment`, { content, replyId });
  }
  static my(page: number, size: number): Promise<PageVo<PostVo>> {
    return Http.get<PageVo<PostVo>>(`/post/my?page=${page}&size=${size}`);
  }
  static myComments(): Promise<object[]> { return Http.get<object[]>('/post/my-comments'); }
}

export class AiApi {
  static sessions(business?: string): Promise<AiSessionVo[]> {
    return Http.get<AiSessionVo[]>(business ? `/ai/sessions?business=${business}` : '/ai/sessions');
  }
  static createSession(business: string, title?: string): Promise<AiSessionVo> {
    return Http.post<AiSessionVo>('/ai/sessions', { business, title });
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
    return Http.post('/message/read', { type, ids });
  }
  static chats(): Promise<ChatConvVo[]>                       { return Http.get<ChatConvVo[]>('/message/chats'); }
  static chatWith(userId: number): Promise<ChatMsgVo[]>       { return Http.get<ChatMsgVo[]>(`/message/chats/${userId}`); }
  static send(toUserId: number, content: string, type: string = 'text'): Promise<ChatMsgVo> {
    return Http.post<ChatMsgVo>('/message/send', { toUserId, content, type });
  }
}
