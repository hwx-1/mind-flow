package com.mental.health.security;

public class UserContext {
    private static final ThreadLocal<Long> CTX = new ThreadLocal<>();
    public static void set(Long uid) { CTX.set(uid); }
    public static Long get() { return CTX.get(); }
    public static Long require() {
        Long uid = CTX.get();
        if (uid == null) throw new com.mental.health.common.BizException(401, "未登录");
        return uid;
    }
    public static void clear() { CTX.remove(); }
}
