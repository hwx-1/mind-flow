package com.mental.health.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

public class AuthDto {

    @Data
    public static class Register {
        @NotBlank @Size(min = 3, max = 20) public String username;
        @NotBlank @Size(min = 6, max = 20) public String password;
        @NotBlank public String phone;
        public String code;
    }

    @Data
    public static class Login {
        @NotBlank public String account;
        @NotBlank public String password;
    }

    @Data
    public static class Refresh {
        @NotBlank public String refreshToken;
    }

    @Data
    public static class LoginResp {
        public String token;
        public String refreshToken;
        public Object user;
    }

    // ===== v2 新增 =====

    /** 验证码登录请求 */
    @Data
    public static class CodeLogin {
        @NotBlank @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号格式不正确")
        public String phone;
        @NotBlank @Size(min = 4, max = 6, message = "验证码长度不正确")
        public String code;
    }

    /** 发送验证码请求 */
    @Data
    public static class SendCode {
        @NotBlank @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号格式不正确")
        public String phone;
        /** login / register / reset_pwd，默认 login */
        public String scene;
    }

    /** 第三方登录请求 */
    @Data
    public static class OauthLogin {
        public String provider;
        public String authCode;
    }
}
