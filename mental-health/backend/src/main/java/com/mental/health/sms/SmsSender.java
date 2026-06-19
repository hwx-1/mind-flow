package com.mental.health.sms;

/**
 * 短信发送接口 —— 可插拔
 * 实现类：MockSmsSender（默认，控制台打印）、IhuyiSmsSender（互亿无线）
 * 通过 application-prod.yml 的 sms.provider 切换
 */
public interface SmsSender {
    /**
     * 发送验证码
     * @param phone 手机号
     * @param code  验证码（4-6 位）
     * @return 是否发送成功
     */
    boolean sendCode(String phone, String code);
}
