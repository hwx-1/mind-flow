package com.mental.health.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("notification")
public class Notification {
    @TableId(type = IdType.AUTO) private Long id;
    private Long userId;
    private Long fromUser;
    private String type;       // like/comment/follow
    private Long targetId;
    private Integer targetType;
    private String content;
    private Integer isRead;
    private LocalDateTime createdAt;
}
