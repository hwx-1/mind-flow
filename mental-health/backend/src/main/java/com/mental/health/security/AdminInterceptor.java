package com.mental.health.security;

import com.mental.health.common.BizException;
import com.mental.health.entity.User;
import com.mental.health.mapper.UserMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * 管理后台权限拦截器：
 * 拦截所有 /admin/** 请求，确认当前登录用户的 role == 'admin'。
 * JwtFilter 已把 uid 放进 UserContext，这里查库确认角色。
 */
@Component
@RequiredArgsConstructor
public class AdminInterceptor implements HandlerInterceptor {

    private final UserMapper userMapper;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        // 放行预检
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) return true;

        Long uid = UserContext.get();
        if (uid == null) throw new BizException(401, "未登录");

        User u = userMapper.selectById(uid);
        if (u == null) throw new BizException(401, "用户不存在");
        if (!"admin".equals(u.getRole())) throw new BizException(403, "无管理后台权限");

        return true;
    }
}
