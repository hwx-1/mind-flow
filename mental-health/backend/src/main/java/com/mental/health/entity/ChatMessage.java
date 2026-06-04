package com.mental.health.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("chat_message")
public class ChatMessage {
    @TableId(type = IdType.AUTO) private Long id;
    private Long fromUser;
    private Long toUser;
    private String content;
    private String type;       // text/image
    private Integer isRead;
    private LocalDateTime createdAt;
}
