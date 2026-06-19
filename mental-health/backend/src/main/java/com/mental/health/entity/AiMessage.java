package com.mental.health.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("ai_message")
public class AiMessage {
    @TableId(type = IdType.AUTO) private Long id;
    private Long sessionId;
    private String role; // user/assistant
    private String content;
    private Integer tokens;
    private LocalDateTime createdAt;
}
