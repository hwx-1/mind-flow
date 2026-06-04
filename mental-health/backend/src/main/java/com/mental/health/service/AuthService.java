package com.mental.health.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.mental.health.common.BizException;
import com.mental.health.dto.AuthDto;
import com.mental.health.entity.User;
import com.mental.health.mapper.UserMapper;
import com.mental.health.security.JwtUtil;
import com.mental.health.util.MediaUrlUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserMapper userMapper;
    private final PasswordEncoder encoder;
    private final JwtUtil jwtUtil;
    private final SmsService smsService;

    public AuthDto.LoginResp register(AuthDto.Register req) {
        Long exists = userMapper.selectCount(new LambdaQueryWrapper<User>()
                .eq(User::getUsername, req.username));
        if (exists > 0) throw new BizException("用户名已存在");
        Long phoneExists = userMapper.selectCount(new LambdaQueryWrapper<User>()
                .eq(User::getPhone, req.phone));
        if (phoneExists > 0) throw new BizException("手机号已注册");

        // 如果鸿蒙端注册时传了验证码，做校验；没传则不校验（兼容旧版）
        if (req.code != null && !req.code.isBlank()) {
            boolean ok = smsService.verify(req.phone, req.code, "register");
            if (!ok) throw new BizException("验证码错误或已过期");
        }

        User u = new User();
        u.setUsername(req.username);
        u.setPassword(encoder.encode(req.password));
        u.setPhone(req.phone);
        u.setNickname(req.username);
        u.setAvatar("");
        u.setStatus(1);
        userMapper.insert(u);
        return token(u);
    }

    public AuthDto.LoginResp login(AuthDto.Login req) {
        User u = userMapper.selectOne(new LambdaQueryWrapper<User>()
                .eq(User::getUsername, req.account)
                .or().eq(User::getPhone, req.account));
        if (u == null) throw new BizException("用户不存在");
        if (!encoder.matches(req.password, u.getPassword())) throw new BizException("密码错误");
        if (u.getStatus() == 0) throw new BizException("账号已被禁用");
        return token(u);
    }

    /**
     * 验证码登录（v2 新增）
     * - 验证码正确后，如果手机号没注册过，自动创建一个匿名用户
     */
    public AuthDto.LoginResp loginByCode(AuthDto.CodeLogin req) {
        boolean ok = smsService.verify(req.phone, req.code, "login");
        if (!ok) throw new BizException("验证码错误或已过期");

        User u = userMapper.selectOne(new LambdaQueryWrapper<User>()
                .eq(User::getPhone, req.phone));
        if (u == null) {
            // 自动注册一个用户（手机号登录的常规做法）
            u = new User();
            u.setUsername("u_" + req.phone);
            u.setPassword(encoder.encode(UUID.randomUUID().toString()));  // 随机密码
            u.setPhone(req.phone);
            u.setNickname("心晴用户" + req.phone.substring(req.phone.length() - 4));
            u.setAvatar("");
            u.setStatus(1);
            userMapper.insert(u);
            log.info("auto register by code, phone={}, uid={}", req.phone, u.getId());
        } else if (u.getStatus() == 0) {
            throw new BizException("账号已被禁用");
        }
        return token(u);
    }

    /**
     * 社交登录（v2 占位）
     * 微信/QQ 登录暂未对接 SDK，直接返回业务错误
     */
    public AuthDto.LoginResp socialLogin(String provider, AuthDto.OauthLogin req) {
        log.warn("social login not implemented yet, provider={}", provider);
        throw new BizException(503, provider + " 登录功能暂未开放，请使用其他方式登录");
    }

    private AuthDto.LoginResp token(User u) {
        AuthDto.LoginResp r = new AuthDto.LoginResp();
        r.token = jwtUtil.create(u.getId(), u.getUsername());
        r.refreshToken = jwtUtil.createRefresh(u.getId());
        u.setPassword(null);
        u.setAvatar(MediaUrlUtil.avatar(u.getAvatar()));
        r.user = u;
        return r;
    }

    public AuthDto.LoginResp refresh(String refreshToken) {
        try {
            Long uid = Long.valueOf(jwtUtil.parse(refreshToken).getSubject());
            User u = userMapper.selectById(uid);
            if (u == null) throw new BizException("用户不存在");
            return token(u);
        } catch (Exception e) {
            throw new BizException(401, "refresh token 无效");
        }
    }
}
