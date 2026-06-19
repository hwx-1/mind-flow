package com.mental.health.service;

import cn.hutool.core.util.StrUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.mental.health.entity.*;
import com.mental.health.mapper.*;
import com.mental.health.util.MediaUrlUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MessageService {

    private final NotificationMapper notificationMapper;
    private final ChatMessageMapper chatMapper;
    private final ChatConversationMapper convMapper;
    private final UserMapper userMapper;
    private final UserService userService;

    public List<Map<String, Object>> notifications(Long uid, String type, int page, int size) {
        Page<Notification> p = new Page<>(page, size);
        LambdaQueryWrapper<Notification> qw = new LambdaQueryWrapper<Notification>()
                .eq(Notification::getUserId, uid)
                .orderByDesc(Notification::getCreatedAt);
        if (StrUtil.isNotBlank(type) && !"all".equals(type)) qw.eq(Notification::getType, type);
        notificationMapper.selectPage(p, qw);

        if (p.getRecords().isEmpty()) return List.of();
        Set<Long> uids = p.getRecords().stream().map(Notification::getFromUser).collect(Collectors.toSet());
        Map<Long, User> userMap = userMapper.selectBatchIds(uids).stream()
                .collect(Collectors.toMap(User::getId, u -> u));

        return p.getRecords().stream().map(n -> {
            Map<String, Object> m = new HashMap<>();
            m.put("id", n.getId());
            m.put("type", n.getType());
            m.put("content", n.getContent());
            m.put("targetId", n.getTargetId());
            m.put("isRead", n.getIsRead());
            m.put("createdAt", n.getCreatedAt());
            User u = userMap.get(n.getFromUser());
            if (u != null) { m.put("nickname", u.getNickname()); m.put("avatar", MediaUrlUtil.avatar(u.getAvatar())); }
            return m;
        }).toList();
    }

    public Map<String, Integer> unreadCount(Long uid) {
        Map<String, Integer> r = new HashMap<>();
        for (String t : List.of("like", "comment", "follow", "friend")) {
            Long c = notificationMapper.selectCount(new LambdaQueryWrapper<Notification>()
                    .eq(Notification::getUserId, uid).eq(Notification::getType, t).eq(Notification::getIsRead, 0));
            r.put(t, c.intValue());
        }
        Long chat = convMapper.selectList(new LambdaQueryWrapper<ChatConversation>()
                .eq(ChatConversation::getUserId, uid)).stream()
                .mapToLong(c -> c.getUnreadCount() == null ? 0 : c.getUnreadCount()).sum();
        r.put("chat", (int) chat.longValue());
        return r;
    }

    public void markRead(Long uid, String type, List<Long> ids) {
        LambdaQueryWrapper<Notification> qw = new LambdaQueryWrapper<Notification>()
                .eq(Notification::getUserId, uid);
        if (StrUtil.isNotBlank(type) && !"all".equals(type)) qw.eq(Notification::getType, type);
        if (ids != null && !ids.isEmpty()) qw.in(Notification::getId, ids);
        Notification patch = new Notification(); patch.setIsRead(1);
        notificationMapper.update(patch, qw);
    }

    public List<Map<String, Object>> chats(Long uid) {
        List<ChatConversation> list = convMapper.selectList(new LambdaQueryWrapper<ChatConversation>()
                .eq(ChatConversation::getUserId, uid).orderByDesc(ChatConversation::getUpdatedAt));
        if (list.isEmpty()) return List.of();
        Set<Long> others = list.stream().map(ChatConversation::getOtherUser).collect(Collectors.toSet());
        Map<Long, User> userMap = userMapper.selectBatchIds(others).stream()
                .collect(Collectors.toMap(User::getId, u -> u));
        return list.stream().map(c -> {
            Map<String, Object> m = new HashMap<>();
            m.put("userId", c.getOtherUser());
            m.put("lastMessage", c.getLastMessage());
            m.put("unreadCount", c.getUnreadCount());
            m.put("updatedAt", c.getUpdatedAt());
            User u = userMap.get(c.getOtherUser());
            if (u != null) { m.put("nickname", u.getNickname()); m.put("avatar", MediaUrlUtil.avatar(u.getAvatar())); }
            return m;
        }).toList();
    }

    public List<ChatMessage> chatWith(Long uid, Long otherId) {
        // 标记已读
        ChatConversation c = convMapper.selectOne(new LambdaQueryWrapper<ChatConversation>()
                .eq(ChatConversation::getUserId, uid).eq(ChatConversation::getOtherUser, otherId));
        if (c != null && c.getUnreadCount() != null && c.getUnreadCount() > 0) {
            c.setUnreadCount(0); convMapper.updateById(c);
        }
        return chatMapper.selectList(new LambdaQueryWrapper<ChatMessage>()
                .and(w -> w.and(x -> x.eq(ChatMessage::getFromUser, uid).eq(ChatMessage::getToUser, otherId))
                          .or(x -> x.eq(ChatMessage::getFromUser, otherId).eq(ChatMessage::getToUser, uid)))
                .orderByAsc(ChatMessage::getCreatedAt).last("limit 200"));
    }

    @Transactional
    public ChatMessage send(Long uid, Long toId, String content, String type) {
        guardStrangerGreeting(uid, toId);
        ChatMessage m = new ChatMessage();
        m.setFromUser(uid); m.setToUser(toId);
        m.setContent(content); m.setType(type == null ? "text" : type);
        m.setIsRead(0);
        chatMapper.insert(m);
        upsertConv(uid, toId, content, false);
        upsertConv(toId, uid, content, true);
        return m;
    }

    private void guardStrangerGreeting(Long uid, Long toId) {
        if (userService.isFriend(uid, toId)) return;
        Long sentByMe = chatMapper.selectCount(new LambdaQueryWrapper<ChatMessage>()
                .eq(ChatMessage::getFromUser, uid)
                .eq(ChatMessage::getToUser, toId));
        Long repliedByOther = chatMapper.selectCount(new LambdaQueryWrapper<ChatMessage>()
                .eq(ChatMessage::getFromUser, toId)
                .eq(ChatMessage::getToUser, uid));
        if (sentByMe > 0 && repliedByOther == 0) {
            throw new com.mental.health.common.BizException(403, "对方回复前只能发送一句打招呼");
        }
    }

    private void upsertConv(Long owner, Long other, String last, boolean addUnread) {
        ChatConversation c = convMapper.selectOne(new LambdaQueryWrapper<ChatConversation>()
                .eq(ChatConversation::getUserId, owner).eq(ChatConversation::getOtherUser, other));
        if (c == null) {
            c = new ChatConversation();
            c.setUserId(owner); c.setOtherUser(other);
            c.setLastMessage(StrUtil.maxLength(last, 100));
            c.setUnreadCount(addUnread ? 1 : 0);
            convMapper.insert(c);
        } else {
            c.setLastMessage(StrUtil.maxLength(last, 100));
            if (addUnread) c.setUnreadCount((c.getUnreadCount() == null ? 0 : c.getUnreadCount()) + 1);
            convMapper.updateById(c);
        }
    }
}
