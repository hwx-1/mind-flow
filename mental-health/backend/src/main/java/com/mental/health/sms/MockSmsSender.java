package com.mental.health.sms;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * 演示版：不真的发短信，只在日志打印
 * 当 sms.provider=mock 时启用（默认）
 */
@Slf4j
@Component
@ConditionalOnProperty(name = "sms.provider", havingValue = "mock", matchIfMissing = true)
public class MockSmsSender implements SmsSender {
    @Override
    public boolean sendCode(String phone, String code) {
        log.info("==================================================");
        log.info("  [Mock 短信] 发送给 {}：你的验证码是 {}", phone, code);
        log.info("==================================================");
        return true;
    }
}
