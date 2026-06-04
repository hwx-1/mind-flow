package com.mental.health.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public class PostDto {

    @Data
    public static class Publish {
        @NotBlank public String content;
        public List<String> images;
        public String video;
        public String topic;

        // ===== v2 新增：发帖地理位置 =====
        public String locationLabel;
        public BigDecimal latitude;
        public BigDecimal longitude;
        public String address;
        // ================================
    }

    @Data
    public static class CommentReq {
        @NotBlank public String content;
        public Long replyId;
    }

    @Data
    public static class Vo {
        public Long id;
        public Long userId;
        public String nickname;
        public String avatar;
        public String content;
        public List<String> images;
        public String video;
        public String topic;
        public Integer likeCount;
        public Integer commentCount;
        public Boolean liked;
        public Boolean collected;
        public LocalDateTime createdAt;

        // ===== v2 新增：返回地理位置给前端 =====
        public String locationLabel;
        public BigDecimal latitude;
        public BigDecimal longitude;
        // ====================================
    }
}
