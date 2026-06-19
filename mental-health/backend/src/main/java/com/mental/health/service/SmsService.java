package com.mental.health.service;

import com.mental.health.common.BizException;
import com.mental.health.sms.SmsSender;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.util.Random;
import java.util.concurrent.TimeUnit;

/**
 * 验证码服务：
 * - 生成 4 位数字验证码
 * - 存 Redis，5 分钟过期
 * - 60 秒防刷限频
 * - 校验时一次性使用（成功后立即删除）
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SmsService {

    private final StringRedisTemplate redis;
    private final SmsSender smsSender;

    private static final long CODE_TTL_SECONDS  = 5 * 60;  // 验证码有效期 5 分钟
    private static final long FREQ_LIMIT_SECONDS = 60;     // 同一手机号 60 秒内只能发一次
    private static final Random RNG = new Random();

    /**
     * 发送验证码
     * @param phone 手机号
     * @param scene login / register / reset_pwd 不同场景独立 key
     */
    public void send(String phone, String scene) {
        String s = (scene == null || scene.isBlank()) ? "login" : scene;
        String freqKey = freqKey(phone, s);
        String codeKey = codeKey(phone, s);

        // 限频检查
        Boolean firstSet = redis.opsForValue().setIfAbsent(freqKey, "1", FREQ_LIMIT_SECONDS, TimeUnit.SECONDS);
        if (Boolean.FALSE.equals(firstSet)) {
            Long ttl = redis.getExpire(freqKey, TimeUnit.SECONDS);
            throw new BizException("发送太频繁，请 " + (ttl == null ? FREQ_LIMIT_SECONDS : ttl) + " 秒后再试");
        }

        // 生成验证码
        String code = String.format("%04d", RNG.nextInt(10000));

        // 调用厂商发送
        boolean ok = smsSender.sendCode(phone, code);
        if (!ok) {
            // 发送失败，回收限频窗口
            redis.delete(freqKey);
            throw new BizException("短信发送失败，请稍后重试");
        }

        // 存 Redis
        redis.opsForValue().set(codeKey, code, CODE_TTL_SECONDS, TimeUnit.SECONDS);
        log.info("sms code stored, phone={}, scene={}", phone, s);
    }

    /**
     * 校验验证码，成功后立即删除（一次性使用）
     * @return true=匹配，false=不匹配或已过期
     */
    public boolean verify(String phone, String code, String scene) {
        String s = (scene == null || scene.isBlank()) ? "login" : scene;
        String codeKey = codeKey(phone, s);
        String saved = redis.opsForValue().get(codeKey);
        if (saved == null) return false;
        if (!saved.equals(code)) return false;
        redis.delete(codeKey);  // 验证成功立即销毁
        return true;
    }

    private String codeKey(String phone, String scene) {
        return "sms:code:" + scene + ":" + phone;
    }

    private String freqKey(String phone, String scene) {
        return "sms:freq:" + scene + ":" + phone;
    }
}
