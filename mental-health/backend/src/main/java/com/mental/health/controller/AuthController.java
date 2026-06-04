package com.mental.health.controller;

import com.mental.health.common.R;
import com.mental.health.dto.AuthDto;
import com.mental.health.service.AuthService;
import com.mental.health.service.SmsService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final SmsService smsService;

    @PostMapping("/register")
    public R<AuthDto.LoginResp> register(@Valid @RequestBody AuthDto.Register req) {
        return R.ok(authService.register(req));
    }

    @PostMapping("/login")
    public R<AuthDto.LoginResp> login(@Valid @RequestBody AuthDto.Login req) {
        return R.ok(authService.login(req));
    }

    @PostMapping("/refresh")
    public R<AuthDto.LoginResp> refresh(@Valid @RequestBody AuthDto.Refresh req) {
        return R.ok(authService.refresh(req.refreshToken));
    }

    /** 发送短信验证码 */
    @PostMapping("/code")
    public R<?> code(@Valid @RequestBody AuthDto.SendCode req) {
        smsService.send(req.phone, req.scene);
        return R.ok();
    }

    /** 验证码登录 */
    @PostMapping("/login/code")
    public R<AuthDto.LoginResp> loginByCode(@Valid @RequestBody AuthDto.CodeLogin req) {
        return R.ok(authService.loginByCode(req));
    }

    /** 社交登录（演示版返回未开放） */
    @PostMapping("/oauth/{provider}")
    public R<AuthDto.LoginResp> oauth(@PathVariable String provider,
                                       @RequestBody AuthDto.OauthLogin req) {
        return R.ok(authService.socialLogin(provider, req));
    }
}
