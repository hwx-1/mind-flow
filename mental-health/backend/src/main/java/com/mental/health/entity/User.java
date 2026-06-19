package com.mental.health.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("user")
public class User {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String username;
    private String password;
    private String phone;
    private String nickname;
    private String avatar;
    private String bio;
    private String profileStatus;
    private Integer gender;
    private LocalDate birthday;
    private Integer status;
    private String role;   // v2.3 新增：user / admin
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
