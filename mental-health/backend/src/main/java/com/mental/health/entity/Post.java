package com.mental.health.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("post")
public class Post {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long userId;
    private String content;
    private String images;   // JSON
    private String video;
    private String topic;

    // ===== v2 新增：地理位置 =====
    private String locationLabel;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private String address;
    // ============================

    private Integer likeCount;
    private Integer commentCount;
    private Integer viewCount;
    private Integer status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
