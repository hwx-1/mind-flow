package com.mental.health.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("friend_request")
public class FriendRequest {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long fromUser;
    private Long toUser;
    private String message;
    @TableField("status")
    private Integer requestStatus;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
