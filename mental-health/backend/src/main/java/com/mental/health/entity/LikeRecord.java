package com.mental.health.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("like_record")
public class LikeRecord {
    @TableId(type = IdType.AUTO) private Long id;
    private Long userId;
    private Long targetId;
    private Integer targetType; // 1 post, 2 comment
    private LocalDateTime createdAt;
}
