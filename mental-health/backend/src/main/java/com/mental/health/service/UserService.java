package com.mental.health.service;

import cn.hutool.core.util.StrUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.mental.health.common.BizException;
import com.mental.health.dto.UserDto;
import com.mental.health.entity.Follow;
import com.mental.health.entity.FriendRelation;
import com.mental.health.entity.FriendRequest;
import com.mental.health.entity.Notification;
import com.mental.health.entity.User;
import com.mental.health.mapper.FollowMapper;
import com.mental.health.mapper.FriendRelationMapper;
import com.mental.health.mapper.FriendRequestMapper;
import com.mental.health.mapper.NotificationMapper;
import com.mental.health.mapper.UserMapper;
import com.mental.health.util.MediaUrlUtil;
import com.mental.health.websocket.WsSessionRegistry;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserMapper userMapper;
    private final PasswordEncoder encoder;
    private final FollowMapper followMapper;
    private final FriendRequestMapper friendRequestMapper;
    private final FriendRelationMapper friendRelationMapper;
    private final NotificationMapper notificationMapper;
    private final WsSessionRegistry wsSessionRegistry;

    public User findById(Long id) {
        User u = userMapper.selectById(id);
        if (u == null) throw new BizException("用户不存在");
        u.setPassword(null);
        return u;
    }

    public UserDto.ProfileVo profile(Long currentUid, Long userId) {
        User u = findById(userId);
        UserDto.ProfileVo vo = toProfile(u);
        if (currentUid == null || !currentUid.equals(userId)) {
            vo.phone = null;
        }
        if (currentUid != null && !currentUid.equals(userId)) {
            vo.followed = isFollowing(currentUid, userId);
            vo.friend = isFriend(currentUid, userId);
            FriendRequest pending = friendRequestMapper.selectOne(new LambdaQueryWrapper<FriendRequest>()
                    .eq(FriendRequest::getFromUser, currentUid)
                    .eq(FriendRequest::getToUser, userId)
                    .eq(FriendRequest::getRequestStatus, 0)
                    .last("limit 1"));
            vo.friendRequestStatus = pending == null ? null : pending.getRequestStatus();
        } else {
            vo.followed = false;
            vo.friend = false;
        }
        vo.followerCount = followMapper.selectCount(new LambdaQueryWrapper<Follow>()
                .eq(Follow::getFollowId, userId)).intValue();
        vo.followingCount = followMapper.selectCount(new LambdaQueryWrapper<Follow>()
                .eq(Follow::getUserId, userId)).intValue();
        return vo;
    }

    public List<UserDto.ProfileVo> search(Long currentUid, String keyword) {
        String q = StrUtil.trimToEmpty(keyword);
        if (q.isEmpty()) return List.of();
        LambdaQueryWrapper<User> qw = new LambdaQueryWrapper<User>()
                .eq(User::getStatus, 1)
                .and(w -> w.like(User::getNickname, q)
                        .or().like(User::getUsername, q)
                        .or().eq(User::getId, parseLongOrNull(q)))
                .last("limit 30");
        return userMapper.selectList(qw).stream()
                .map(u -> profile(currentUid, u.getId()))
                .toList();
    }

    public List<UserDto.FriendVo> friends(Long uid) {
        List<FriendRelation> relations = friendRelationMapper.selectList(new LambdaQueryWrapper<FriendRelation>()
                .eq(FriendRelation::getUserId, uid)
                .orderByDesc(FriendRelation::getCreatedAt));
        if (relations.isEmpty()) return List.of();

        Set<Long> friendIds = relations.stream().map(FriendRelation::getFriendId).collect(Collectors.toSet());
        Map<Long, User> userMap = userMapper.selectBatchIds(friendIds).stream()
                .filter(u -> u.getStatus() == null || u.getStatus() == 1)
                .collect(Collectors.toMap(User::getId, Function.identity()));

        return relations.stream()
                .map(rel -> toFriendVo(rel, userMap.get(rel.getFriendId())))
                .filter(vo -> vo != null)
                .sorted(Comparator.comparing((UserDto.FriendVo vo) -> StrUtil.blankToDefault(vo.nickname, vo.username)))
                .toList();
    }

    public void update(Long uid, User patch) {
        patch.setId(uid);
        patch.setUsername(null);
        patch.setPassword(null);
        patch.setPhone(null);
        patch.setStatus(null);
        patch.setRole(null);   // v2.3 防止用户通过资料接口给自己提权成 admin
        userMapper.updateById(patch);
    }

    public void changePassword(Long uid, String oldPwd, String newPwd) {
        User u = userMapper.selectById(uid);
        if (!encoder.matches(oldPwd, u.getPassword())) throw new BizException("原密码错误");
        u.setPassword(encoder.encode(newPwd));
        userMapper.updateById(u);
    }

    @Transactional
    public boolean toggleFollow(Long uid, Long targetId) {
        if (uid.equals(targetId)) throw new BizException("不能关注自己");
        if (userMapper.selectById(targetId) == null) throw new BizException("用户不存在");
        Follow exist = followMapper.selectOne(new LambdaQueryWrapper<Follow>()
                .eq(Follow::getUserId, uid)
                .eq(Follow::getFollowId, targetId));
        if (exist != null) {
            followMapper.deleteById(exist.getId());
            return false;
        }
        Follow f = new Follow();
        f.setUserId(uid);
        f.setFollowId(targetId);
        followMapper.insert(f);
        notify(targetId, uid, "follow", uid, 3, "关注了你");
        return true;
    }

    public boolean isFriend(Long uid, Long otherId) {
        if (uid == null || otherId == null) return false;
        return friendRelationMapper.selectCount(new LambdaQueryWrapper<FriendRelation>()
                .eq(FriendRelation::getUserId, uid)
                .eq(FriendRelation::getFriendId, otherId)) > 0;
    }

    @Transactional
    public void requestFriend(Long uid, Long targetId, String message) {
        if (uid.equals(targetId)) throw new BizException("不能添加自己");
        if (userMapper.selectById(targetId) == null) throw new BizException("用户不存在");
        if (isFriend(uid, targetId)) throw new BizException("已经是好友");
        FriendRequest exist = friendRequestMapper.selectOne(new LambdaQueryWrapper<FriendRequest>()
                .eq(FriendRequest::getFromUser, uid)
                .eq(FriendRequest::getToUser, targetId)
                .eq(FriendRequest::getRequestStatus, 0)
                .last("limit 1"));
        if (exist != null) throw new BizException("已发送申请，等待对方同意");
        FriendRequest req = new FriendRequest();
        req.setFromUser(uid);
        req.setToUser(targetId);
        req.setMessage(StrUtil.maxLength(StrUtil.blankToDefault(message, "请求添加你为好友"), 80));
        req.setRequestStatus(0);
        friendRequestMapper.insert(req);
        notify(targetId, uid, "friend", req.getId(), 4, req.getMessage());
    }

    public List<UserDto.FriendRequestVo> friendRequests(Long uid) {
        return friendRequestMapper.selectList(new LambdaQueryWrapper<FriendRequest>()
                        .eq(FriendRequest::getToUser, uid)
                        .eq(FriendRequest::getRequestStatus, 0)
                        .orderByDesc(FriendRequest::getCreatedAt)).stream()
                .map(req -> {
                    User from = userMapper.selectById(req.getFromUser());
                    UserDto.FriendRequestVo vo = new UserDto.FriendRequestVo();
                    vo.id = req.getId();
                    vo.fromUser = req.getFromUser();
                    vo.toUser = req.getToUser();
                    vo.message = req.getMessage();
                    vo.status = req.getRequestStatus();
                    vo.createdAt = req.getCreatedAt();
                    if (from != null) {
                        vo.nickname = from.getNickname();
                        vo.avatar = MediaUrlUtil.avatar(from.getAvatar());
                        vo.uid = from.getId();
                    }
                    return vo;
                }).toList();
    }

    @Transactional
    public void acceptFriend(Long uid, Long requestId) {
        FriendRequest req = friendRequestMapper.selectById(requestId);
        if (req == null || !uid.equals(req.getToUser())) throw new BizException("好友申请不存在");
        if (req.getRequestStatus() != null && req.getRequestStatus() != 0) throw new BizException("申请已处理");
        req.setRequestStatus(1);
        friendRequestMapper.updateById(req);
        addFriendPair(req.getFromUser(), req.getToUser());
        notify(req.getFromUser(), uid, "friend", req.getId(), 4, "已同意你的好友申请");
    }

    private void addFriendPair(Long a, Long b) {
        addFriend(a, b);
        addFriend(b, a);
    }

    private void addFriend(Long uid, Long friendId) {
        if (isFriend(uid, friendId)) return;
        FriendRelation rel = new FriendRelation();
        rel.setUserId(uid);
        rel.setFriendId(friendId);
        friendRelationMapper.insert(rel);
    }

    private boolean isFollowing(Long uid, Long targetId) {
        return followMapper.selectCount(new LambdaQueryWrapper<Follow>()
                .eq(Follow::getUserId, uid)
                .eq(Follow::getFollowId, targetId)) > 0;
    }

    private UserDto.ProfileVo toProfile(User u) {
        UserDto.ProfileVo vo = new UserDto.ProfileVo();
        vo.id = u.getId();
        vo.uid = u.getId();
        vo.username = u.getUsername();
        vo.phone = u.getPhone();
        vo.nickname = u.getNickname();
        vo.avatar = MediaUrlUtil.avatar(u.getAvatar());
        vo.bio = u.getBio();
        vo.profileStatus = u.getProfileStatus();
        vo.gender = u.getGender();
        return vo;
    }

    private UserDto.FriendVo toFriendVo(FriendRelation rel, User u) {
        if (u == null) return null;
        UserDto.FriendVo vo = new UserDto.FriendVo();
        vo.id = u.getId();
        vo.uid = u.getId();
        vo.username = u.getUsername();
        vo.nickname = u.getNickname();
        vo.avatar = MediaUrlUtil.avatar(u.getAvatar());
        vo.profileStatus = StrUtil.blankToDefault(u.getProfileStatus(), "在线");
        vo.online = wsSessionRegistry.isOnline(u.getId()) && !"隐身".equals(vo.profileStatus);
        vo.friendAt = rel.getCreatedAt();
        return vo;
    }

    private Long parseLongOrNull(String value) {
        try {
            return Long.valueOf(value);
        } catch (Exception e) {
            return -1L;
        }
    }

    private void notify(Long to, Long from, String type, Long targetId, int targetType, String content) {
        Notification n = new Notification();
        n.setUserId(to);
        n.setFromUser(from);
        n.setType(type);
        n.setTargetId(targetId);
        n.setTargetType(targetType);
        n.setContent(content);
        n.setIsRead(0);
        notificationMapper.insert(n);
    }
}
