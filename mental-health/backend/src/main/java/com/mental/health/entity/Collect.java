package com.mental.health.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("collect")
public class Collect {
    @TableId(type = IdType.AUTO) private Long id;
    private Long userId;
    private Long postId;
    private LocalDateTime createdAt;
}
