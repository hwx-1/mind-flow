package com.mental.health.service;

import cn.hutool.core.util.StrUtil;
import cn.hutool.json.JSONUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.mental.health.common.BizException;
import com.mental.health.dto.PostDto;
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
public class PostService {

    private final PostMapper postMapper;
    private final CommentMapper commentMapper;
    private final LikeRecordMapper likeMapper;
    private final CollectMapper collectMapper;
    private final UserMapper userMapper;
    private final NotificationMapper notificationMapper;
    private final FollowMapper followMapper;

    public Page<PostDto.Vo> list(Long currentUid, String type, int page, int size) {
        Page<Post> p = new Page<>(page, size);
        LambdaQueryWrapper<Post> qw = new LambdaQueryWrapper<Post>()
                .eq(Post::getStatus, 1);
        if ("follow".equals(type) && currentUid != null) {
            List<Long> followIds = followMapper.selectList(new LambdaQueryWrapper<Follow>()
                    .eq(Follow::getUserId, currentUid)).stream()
                    .map(Follow::getFollowId)
                    .toList();
            if (followIds.isEmpty()) {
                Page<PostDto.Vo> vo = new Page<>(page, size, 0);
                vo.setRecords(List.of());
                return vo;
            }
            qw.in(Post::getUserId, followIds);
        }
        qw.orderByDesc(Post::getCreatedAt);
        postMapper.selectPage(p, qw);

        Page<PostDto.Vo> vo = new Page<>(page, size, p.getTotal());
        vo.setRecords(enrich(p.getRecords(), currentUid));
        return vo;
    }

    public Page<PostDto.Vo> search(Long currentUid, String keyword, int page, int size) {
        String q = StrUtil.trimToEmpty(keyword);
        Page<Post> p = new Page<>(page, size);
        postMapper.selectPage(p, new LambdaQueryWrapper<Post>()
                .eq(Post::getStatus, 1)
                .like(Post::getContent, q)
                .orderByDesc(Post::getCreatedAt));
        Page<PostDto.Vo> vo = new Page<>(page, size, p.getTotal());
        vo.setRecords(enrich(p.getRecords(), currentUid));
        return vo;
    }

    public PostDto.Vo detail(Long id, Long currentUid) {
        Post p = postMapper.selectById(id);
        if (p == null || p.getStatus() == 0) throw new BizException("帖子不存在");
        return enrich(List.of(p), currentUid).get(0);
    }

    @Transactional
    public Long publish(Long uid, PostDto.Publish req) {
        Post p = new Post();
        p.setUserId(uid);
        p.setContent(req.content);
        p.setImages(req.images != null ? JSONUtil.toJsonStr(req.images) : null);
        p.setVideo(req.video);
        p.setTopic(req.topic);

        // v2: 接收 location 字段
        p.setLocationLabel(req.locationLabel);
        p.setLatitude(req.latitude);
        p.setLongitude(req.longitude);
        p.setAddress(req.address);

        p.setLikeCount(0); p.setCommentCount(0); p.setViewCount(0); p.setStatus(1);
        postMapper.insert(p);
        return p.getId();
    }

    @Transactional
    public void delete(Long uid, Long id) {
        Post p = postMapper.selectById(id);
        if (p == null) throw new BizException("帖子不存在");
        if (!p.getUserId().equals(uid)) throw new BizException(403, "无权删除");
        p.setStatus(0);
        postMapper.updateById(p);
    }

    @Transactional
    public boolean toggleLike(Long uid, Long postId) {
        Post p = postMapper.selectById(postId);
        if (p == null) throw new BizException("帖子不存在");
        LikeRecord exist = likeMapper.selectOne(new LambdaQueryWrapper<LikeRecord>()
                .eq(LikeRecord::getUserId, uid)
                .eq(LikeRecord::getTargetId, postId)
                .eq(LikeRecord::getTargetType, 1));
        boolean liked;
        if (exist != null) {
            likeMapper.deleteById(exist.getId());
            p.setLikeCount(Math.max(0, p.getLikeCount() - 1));
            liked = false;
        } else {
            LikeRecord lr = new LikeRecord();
            lr.setUserId(uid); lr.setTargetId(postId); lr.setTargetType(1);
            likeMapper.insert(lr);
            p.setLikeCount(p.getLikeCount() + 1);
            liked = true;
            if (!uid.equals(p.getUserId())) notify(p.getUserId(), uid, "like", postId, 1, "赞了你的帖子");
        }
        postMapper.updateById(p);
        return liked;
    }

    @Transactional
    public boolean toggleCollect(Long uid, Long postId) {
        Collect exist = collectMapper.selectOne(new LambdaQueryWrapper<Collect>()
                .eq(Collect::getUserId, uid).eq(Collect::getPostId, postId));
        if (exist != null) { collectMapper.deleteById(exist.getId()); return false; }
        Collect c = new Collect(); c.setUserId(uid); c.setPostId(postId);
        collectMapper.insert(c); return true;
    }

    @Transactional
    public Long comment(Long uid, Long postId, PostDto.CommentReq req) {
        Post p = postMapper.selectById(postId);
        if (p == null) throw new BizException("帖子不存在");
        Comment c = new Comment();
        c.setPostId(postId); c.setUserId(uid); c.setContent(req.content);
        c.setReplyId(req.replyId); c.setLikeCount(0); c.setStatus(1);
        if (req.replyId != null) {
            Comment r = commentMapper.selectById(req.replyId);
            if (r != null) c.setReplyUser(r.getUserId());
        }
        commentMapper.insert(c);
        p.setCommentCount(p.getCommentCount() + 1);
        postMapper.updateById(p);
        if (!uid.equals(p.getUserId())) notify(p.getUserId(), uid, "comment", postId, 1, "评论了你: " + StrUtil.maxLength(req.content, 30));
        return c.getId();
    }

    public List<Map<String, Object>> comments(Long postId, int page, int size) {
        Page<Comment> p = new Page<>(page, size);
        commentMapper.selectPage(p, new LambdaQueryWrapper<Comment>()
                .eq(Comment::getPostId, postId).eq(Comment::getStatus, 1)
                .orderByDesc(Comment::getCreatedAt));
        if (p.getRecords().isEmpty()) return List.of();
        Set<Long> uids = p.getRecords().stream().map(Comment::getUserId).collect(Collectors.toSet());
        Map<Long, User> userMap = userMapper.selectBatchIds(uids).stream()
                .collect(Collectors.toMap(User::getId, u -> u));
        return p.getRecords().stream().map(c -> {
            Map<String, Object> m = new HashMap<>();
            m.put("id", c.getId());
            m.put("content", c.getContent());
            m.put("createdAt", c.getCreatedAt());
            m.put("replyId", c.getReplyId());
            User u = userMap.get(c.getUserId());
            if (u != null) { m.put("nickname", u.getNickname()); m.put("avatar", MediaUrlUtil.avatar(u.getAvatar())); }
            return m;
        }).toList();
    }

    public Page<PostDto.Vo> myPosts(Long uid, int page, int size) {
        return userPosts(uid, uid, page, size);
    }

    public Page<PostDto.Vo> userPosts(Long targetUid, Long currentUid, int page, int size) {
        Page<Post> p = new Page<>(page, size);
        postMapper.selectPage(p, new LambdaQueryWrapper<Post>()
                .eq(Post::getUserId, targetUid).eq(Post::getStatus, 1)
                .orderByDesc(Post::getCreatedAt));
        Page<PostDto.Vo> vo = new Page<>(page, size, p.getTotal());
        vo.setRecords(enrich(p.getRecords(), currentUid));
        return vo;
    }

    public List<Map<String, Object>> myComments(Long uid) {
        List<Comment> list = commentMapper.selectList(new LambdaQueryWrapper<Comment>()
                .eq(Comment::getUserId, uid).eq(Comment::getStatus, 1)
                .orderByDesc(Comment::getCreatedAt).last("limit 100"));
        if (list.isEmpty()) return List.of();
        Set<Long> postIds = list.stream().map(Comment::getPostId).collect(Collectors.toSet());
        Map<Long, Post> postMap = postMapper.selectBatchIds(postIds).stream()
                .collect(Collectors.toMap(Post::getId, x -> x));
        return list.stream().map(c -> {
            Map<String, Object> m = new HashMap<>();
            m.put("id", c.getId());
            m.put("content", c.getContent());
            m.put("createdAt", c.getCreatedAt());
            Post p = postMap.get(c.getPostId());
            if (p != null) {
                m.put("postId", p.getId());
                m.put("postContent", StrUtil.maxLength(p.getContent(), 80));
            }
            return m;
        }).toList();
    }

    public Page<PostDto.Vo> myLikes(Long uid, int page, int size) {
        Page<LikeRecord> likePage = new Page<>(page, size);
        likeMapper.selectPage(likePage, new LambdaQueryWrapper<LikeRecord>()
                .eq(LikeRecord::getUserId, uid)
                .eq(LikeRecord::getTargetType, 1)
                .orderByDesc(LikeRecord::getCreatedAt));

        Page<PostDto.Vo> vo = new Page<>(page, size, likePage.getTotal());
        if (likePage.getRecords().isEmpty()) {
            vo.setRecords(List.of());
            return vo;
        }

        List<Long> postIds = likePage.getRecords().stream()
                .map(LikeRecord::getTargetId)
                .toList();
        Map<Long, Post> postMap = postMapper.selectBatchIds(postIds).stream()
                .filter(p -> p.getStatus() != null && p.getStatus() == 1)
                .collect(Collectors.toMap(Post::getId, p -> p));
        List<Post> posts = postIds.stream()
                .map(postMap::get)
                .filter(Objects::nonNull)
                .toList();
        vo.setRecords(enrich(posts, uid));
        return vo;
    }

    private List<PostDto.Vo> enrich(List<Post> posts, Long currentUid) {
        if (posts == null || posts.isEmpty()) return List.of();
        Set<Long> uids = posts.stream().map(Post::getUserId).collect(Collectors.toSet());
        Map<Long, User> userMap = userMapper.selectBatchIds(uids).stream()
                .collect(Collectors.toMap(User::getId, u -> u));
        Set<Long> postIds = posts.stream().map(Post::getId).collect(Collectors.toSet());

        Set<Long> likedIds = new HashSet<>();
        Set<Long> collectedIds = new HashSet<>();
        if (currentUid != null && !postIds.isEmpty()) {
            likedIds = likeMapper.selectList(new LambdaQueryWrapper<LikeRecord>()
                    .eq(LikeRecord::getUserId, currentUid)
                    .eq(LikeRecord::getTargetType, 1)
                    .in(LikeRecord::getTargetId, postIds)).stream()
                    .map(LikeRecord::getTargetId).collect(Collectors.toSet());
            collectedIds = collectMapper.selectList(new LambdaQueryWrapper<Collect>()
                    .eq(Collect::getUserId, currentUid)
                    .in(Collect::getPostId, postIds)).stream()
                    .map(Collect::getPostId).collect(Collectors.toSet());
        }
        Set<Long> finalLiked = likedIds;
        Set<Long> finalCollected = collectedIds;
        return posts.stream().map(p -> {
            PostDto.Vo v = new PostDto.Vo();
            v.id = p.getId(); v.userId = p.getUserId();
            v.content = p.getContent(); v.video = p.getVideo(); v.topic = p.getTopic();
            v.likeCount = p.getLikeCount(); v.commentCount = p.getCommentCount();
            v.createdAt = p.getCreatedAt();
            if (StrUtil.isNotBlank(p.getImages())) v.images = JSONUtil.toList(p.getImages(), String.class);
            User u = userMap.get(p.getUserId());
            if (u != null) { v.nickname = u.getNickname(); v.avatar = MediaUrlUtil.avatar(u.getAvatar()); }
            v.liked = finalLiked.contains(p.getId());
            v.collected = finalCollected.contains(p.getId());

            // v2: 返回 location 给前端
            v.locationLabel = p.getLocationLabel();
            v.latitude = p.getLatitude();
            v.longitude = p.getLongitude();
            return v;
        }).toList();
    }

    private void notify(Long to, Long from, String type, Long targetId, int targetType, String content) {
        Notification n = new Notification();
        n.setUserId(to); n.setFromUser(from); n.setType(type);
        n.setTargetId(targetId); n.setTargetType(targetType);
        n.setContent(content); n.setIsRead(0);
        notificationMapper.insert(n);
    }
}
