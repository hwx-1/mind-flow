package com.mental.health.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 公告。
 * 注意：全局逻辑删除字段为 status（1=上线/正常，0=下线）。
 * 因此 MyBatis-Plus 查询会自动只返回 status=1 的记录，下线公告不会被 App 拉取到。
 */
@Data
@TableName("announcement")
public class Announcement {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String title;
    private String content;
    private Integer status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
