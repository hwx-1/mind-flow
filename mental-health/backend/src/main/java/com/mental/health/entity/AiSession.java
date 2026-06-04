package com.mental.health.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("ai_session")
public class AiSession {
    @TableId(type = IdType.AUTO) private Long id;
    private Long userId;
    private String business; // mental/study/general
    private String title;
    private String lastMsg;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
