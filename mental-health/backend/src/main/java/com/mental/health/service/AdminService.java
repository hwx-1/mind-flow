package com.mental.health.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.mental.health.common.BizException;
import com.mental.health.entity.*;
import com.mental.health.mapper.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 管理后台服务：统计 + 用户/帖子/评论/AI/消息 的查询与管理。
 * 全部基于 MyBatis-Plus BaseMapper，不依赖自定义 SQL。
 */
@Service
@RequiredArgsConstructor
public class AdminService {

    private final UserMapper userMapper;
    private final PostMapper postMapper;
    private final CommentMapper commentMapper;
    private final AiSessionMapper aiSessionMapper;
    private final AiMessageMapper aiMessageMapper;
    private final NotificationMapper notificationMapper;
    private final LikeRecordMapper likeRecordMapper;
    private final ChatMessageMapper chatMessageMapper;

    // ============ 概览统计 ============
    public Map<String, Object> stats() {
        Map<String, Object> m = new HashMap<>();
        LocalDateTime todayStart = LocalDate.now().atStartOfDay();

        long userTotal = userMapper.selectCount(null);
        long postTotal = postMapper.selectCount(new LambdaQueryWrapper<Post>().eq(Post::getStatus, 1));
        long commentTotal = commentMapper.selectCount(new LambdaQueryWrapper<Comment>().eq(Comment::getStatus, 1));
        long aiSessionTotal = aiSessionMapper.selectCount(null);
        long aiMsgTotal = aiMessageMapper.selectCount(null);
        long likeTotal = likeRecordMapper.selectCount(null);
        long chatTotal = chatMessageMapper.selectCount(null);

        long newUserToday = userMapper.selectCount(new LambdaQueryWrapper<User>().ge(User::getCreatedAt, todayStart));
        long newPostToday = postMapper.selectCount(new LambdaQueryWrapper<Post>().ge(Post::getCreatedAt, todayStart).eq(Post::getStatus, 1));
        long newAiToday = aiSessionMapper.selectCount(new LambdaQueryWrapper<AiSession>().ge(AiSession::getCreatedAt, todayStart));

        m.put("userTotal", userTotal);
        m.put("postTotal", postTotal);
        m.put("commentTotal", commentTotal);
        m.put("aiSessionTotal", aiSessionTotal);
        m.put("aiMessageTotal", aiMsgTotal);
        m.put("interactionTotal", likeTotal + commentTotal);
        m.put("chatTotal", chatTotal);
        m.put("newUserToday", newUserToday);
        m.put("newPostToday", newPostToday);
        m.put("newAiToday", newAiToday);
        return m;
    }

    /** 近 7 天每日新增（用户/帖子/AI会话），给折线图用 */
    public Map<String, Object> trend() {
        List<String> days = new ArrayList<>();
        List<Long> users = new ArrayList<>();
        List<Long> posts = new ArrayList<>();
        List<Long> ai = new ArrayList<>();
        for (int i = 6; i >= 0; i--) {
            LocalDate d = LocalDate.now().minusDays(i);
            LocalDateTime s = d.atStartOfDay();
            LocalDateTime e = d.plusDays(1).atStartOfDay();
            days.add(d.toString().substring(5)); // MM-dd
            users.add(userMapper.selectCount(new LambdaQueryWrapper<User>().ge(User::getCreatedAt, s).lt(User::getCreatedAt, e)));
            posts.add(postMapper.selectCount(new LambdaQueryWrapper<Post>().ge(Post::getCreatedAt, s).lt(Post::getCreatedAt, e)));
            ai.add(aiSessionMapper.selectCount(new LambdaQueryWrapper<AiSession>().ge(AiSession::getCreatedAt, s).lt(AiSession::getCreatedAt, e)));
        }
        Map<String, Object> m = new HashMap<>();
        m.put("days", days);
        m.put("users", users);
        m.put("posts", posts);
        m.put("aiSessions", ai);
        return m;
    }

    // ============ 用户管理 ============
    public Page<User> userList(int page, int size, String keyword) {
        Page<User> p = new Page<>(page, size);
        LambdaQueryWrapper<User> qw = new LambdaQueryWrapper<User>().orderByDesc(User::getCreatedAt);
        if (keyword != null && !keyword.isBlank()) {
            qw.and(w -> w.like(User::getUsername, keyword)
                    .or().like(User::getNickname, keyword)
                    .or().like(User::getPhone, keyword));
        }
        userMapper.selectPage(p, qw);
        p.getRecords().forEach(u -> u.setPassword(null));
        return p;
    }

    @Transactional
    public void setUserStatus(Long userId, int status) {
        User u = userMapper.selectById(userId);
        if (u == null) throw new BizException("用户不存在");
        if ("admin".equals(u.getRole())) throw new BizException(403, "不能封禁管理员账号");
        u.setStatus(status); // 1 正常 0 封禁
        userMapper.updateById(u);
    }

    // ============ 帖子管理 ============
    public Page<Map<String, Object>> postList(int page, int size, String keyword, Integer status) {
        Page<Post> p = new Page<>(page, size);
        LambdaQueryWrapper<Post> qw = new LambdaQueryWrapper<Post>().orderByDesc(Post::getCreatedAt);
        if (status != null) qw.eq(Post::getStatus, status);
        if (keyword != null && !keyword.isBlank()) qw.like(Post::getContent, keyword);
        postMapper.selectPage(p, qw);

        Set<Long> uids = p.getRecords().stream().map(Post::getUserId).collect(Collectors.toSet());
        Map<Long, User> userMap = uids.isEmpty() ? Map.of()
                : userMapper.selectBatchIds(uids).stream().collect(Collectors.toMap(User::getId, u -> u));

        Page<Map<String, Object>> vo = new Page<>(page, size, p.getTotal());
        vo.setRecords(p.getRecords().stream().map(post -> {
            Map<String, Object> m = new HashMap<>();
            m.put("id", post.getId());
            m.put("userId", post.getUserId());
            m.put("content", post.getContent());
            m.put("images", post.getImages());
            m.put("locationLabel", post.getLocationLabel());
            m.put("likeCount", post.getLikeCount());
            m.put("commentCount", post.getCommentCount());
            m.put("status", post.getStatus());
            m.put("createdAt", post.getCreatedAt());
            User u = userMap.get(post.getUserId());
            if (u != null) { m.put("nickname", u.getNickname()); m.put("avatar", u.getAvatar()); }
            return m;
        }).collect(Collectors.toList()));
        return vo;
    }

    @Transactional
    public void setPostStatus(Long postId, int status) {
        Post p = postMapper.selectById(postId);
        if (p == null) throw new BizException("帖子不存在");
        p.setStatus(status); // 1 正常 0 下架
        postMapper.updateById(p);
    }

    // ============ 评论管理 ============
    public Page<Map<String, Object>> commentList(int page, int size, String keyword) {
        Page<Comment> p = new Page<>(page, size);
        LambdaQueryWrapper<Comment> qw = new LambdaQueryWrapper<Comment>().orderByDesc(Comment::getCreatedAt);
        if (keyword != null && !keyword.isBlank()) qw.like(Comment::getContent, keyword);
        commentMapper.selectPage(p, qw);

        Set<Long> uids = p.getRecords().stream().map(Comment::getUserId).collect(Collectors.toSet());
        Map<Long, User> userMap = uids.isEmpty() ? Map.of()
                : userMapper.selectBatchIds(uids).stream().collect(Collectors.toMap(User::getId, u -> u));

        Page<Map<String, Object>> vo = new Page<>(page, size, p.getTotal());
        vo.setRecords(p.getRecords().stream().map(c -> {
            Map<String, Object> m = new HashMap<>();
            m.put("id", c.getId());
            m.put("postId", c.getPostId());
            m.put("userId", c.getUserId());
            m.put("content", c.getContent());
            m.put("status", c.getStatus());
            m.put("createdAt", c.getCreatedAt());
            User u = userMap.get(c.getUserId());
            if (u != null) { m.put("nickname", u.getNickname()); m.put("avatar", u.getAvatar()); }
            return m;
        }).collect(Collectors.toList()));
        return vo;
    }

    @Transactional
    public void deleteComment(Long commentId) {
        Comment c = commentMapper.selectById(commentId);
        if (c == null) throw new BizException("评论不存在");
        c.setStatus(0);
        commentMapper.updateById(c);
        // 帖子评论数 -1
        Post p = postMapper.selectById(c.getPostId());
        if (p != null && p.getCommentCount() != null && p.getCommentCount() > 0) {
            p.setCommentCount(p.getCommentCount() - 1);
            postMapper.updateById(p);
        }
    }

    // ============ AI 会话管理 ============
    public Page<Map<String, Object>> aiSessionList(int page, int size, String business) {
        Page<AiSession> p = new Page<>(page, size);
        LambdaQueryWrapper<AiSession> qw = new LambdaQueryWrapper<AiSession>().orderByDesc(AiSession::getUpdatedAt);
        if (business != null && !business.isBlank()) qw.eq(AiSession::getBusiness, business);
        aiSessionMapper.selectPage(p, qw);

        Set<Long> uids = p.getRecords().stream().map(AiSession::getUserId).collect(Collectors.toSet());
        Map<Long, User> userMap = uids.isEmpty() ? Map.of()
                : userMapper.selectBatchIds(uids).stream().collect(Collectors.toMap(User::getId, u -> u));

        Page<Map<String, Object>> vo = new Page<>(page, size, p.getTotal());
        vo.setRecords(p.getRecords().stream().map(s -> {
            Map<String, Object> m = new HashMap<>();
            m.put("id", s.getId());
            m.put("userId", s.getUserId());
            m.put("business", s.getBusiness());
            m.put("title", s.getTitle());
            m.put("lastMsg", s.getLastMsg());
            m.put("updatedAt", s.getUpdatedAt());
            User u = userMap.get(s.getUserId());
            if (u != null) { m.put("nickname", u.getNickname()); m.put("avatar", u.getAvatar()); }
            return m;
        }).collect(Collectors.toList()));
        return vo;
    }

    /** 查看某会话的消息记录 */
    public List<AiMessage> aiMessages(Long sessionId) {
        return aiMessageMapper.selectList(new LambdaQueryWrapper<AiMessage>()
                .eq(AiMessage::getSessionId, sessionId)
                .orderByAsc(AiMessage::getCreatedAt));
    }

    // ============ 消息通知管理 ============
    public Page<Map<String, Object>> chatList(int page, int size) {
        Page<ChatMessage> p = new Page<>(page, size);
        chatMessageMapper.selectPage(p, new LambdaQueryWrapper<ChatMessage>().orderByDesc(ChatMessage::getCreatedAt));

        Set<Long> uids = new HashSet<>();
        p.getRecords().forEach(c -> { uids.add(c.getFromUser()); uids.add(c.getToUser()); });
        Map<Long, User> userMap = uids.isEmpty() ? Map.of()
                : userMapper.selectBatchIds(uids).stream().collect(Collectors.toMap(User::getId, u -> u));

        Page<Map<String, Object>> vo = new Page<>(page, size, p.getTotal());
        vo.setRecords(p.getRecords().stream().map(c -> {
            Map<String, Object> m = new HashMap<>();
            m.put("id", c.getId());
            m.put("fromUser", c.getFromUser());
            m.put("toUser", c.getToUser());
            m.put("content", c.getContent());
            m.put("type", c.getType());
            m.put("isRead", c.getIsRead());
            m.put("createdAt", c.getCreatedAt());
            User from = userMap.get(c.getFromUser());
            User to = userMap.get(c.getToUser());
            if (from != null) m.put("fromNickname", from.getNickname());
            if (to != null) m.put("toNickname", to.getNickname());
            return m;
        }).collect(Collectors.toList()));
        return vo;
    }

    public Page<Map<String, Object>> notificationList(int page, int size, String type) {
        Page<Notification> p = new Page<>(page, size);
        LambdaQueryWrapper<Notification> qw = new LambdaQueryWrapper<Notification>().orderByDesc(Notification::getCreatedAt);
        if (type != null && !type.isBlank()) qw.eq(Notification::getType, type);
        notificationMapper.selectPage(p, qw);

        Page<Map<String, Object>> vo = new Page<>(page, size, p.getTotal());
        vo.setRecords(p.getRecords().stream().map(n -> {
            Map<String, Object> m = new HashMap<>();
            m.put("id", n.getId());
            m.put("userId", n.getUserId());
            m.put("fromUser", n.getFromUser());
            m.put("type", n.getType());
            m.put("content", n.getContent());
            m.put("isRead", n.getIsRead());
            m.put("createdAt", n.getCreatedAt());
            return m;
        }).collect(Collectors.toList()));
        return vo;
    }
}
