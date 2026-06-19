package com.mental.health.dto;

import lombok.Data;

import java.time.LocalDateTime;

public class UserDto {

    @Data
    public static class ProfileVo {
        public Long id;
        public Long uid;
        public String username;
        public String phone;
        public String nickname;
        public String avatar;
        public String bio;
        public String profileStatus;
        public Integer gender;
        public Boolean followed;
        public Integer followerCount;
        public Integer followingCount;
        public Boolean friend;
        public Integer friendRequestStatus;
    }

    @Data
    public static class FriendRequestVo {
        public Long id;
        public Long fromUser;
        public Long toUser;
        public String message;
        public Integer status;
        public LocalDateTime createdAt;
        public String nickname;
        public String avatar;
        public Long uid;
    }

    @Data
    public static class FriendVo {
        public Long id;
        public Long uid;
        public String username;
        public String nickname;
        public String avatar;
        public String profileStatus;
        public Boolean online;
        public LocalDateTime friendAt;
    }
}
