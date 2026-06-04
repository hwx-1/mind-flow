package com.mental.health.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("chat_conversation")
public class ChatConversation {
    @TableId(type = IdType.AUTO) private Long id;
    private Long userId;
    private Long otherUser;
    private String lastMessage;
    private Integer unreadCount;
    private LocalDateTime updatedAt;
}
