package com.mental.health.sms;

import cn.hutool.crypto.digest.DigestUtil;
import cn.hutool.http.HttpRequest;
import cn.hutool.http.HttpResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 互亿无线短信实现
 * 文档：https://www.ihuyi.com/api/sms.html
 * 接口：POST https://106.ihuyi.com/webservice/sms.php?method=Submit
 *
 * application-prod.yml 配置：
 *   sms:
 *     provider: ihuyi
 *     ihuyi:
 *       api-id: xxxxx       # 互亿无线后台的 APIID
 *       api-key: xxxxx      # 互亿无线后台的 APIKEY（明文，代码内 MD5 加密后传）
 *       sign-name: "【达信通】"   # 仅日志展示用，互亿会自动给短信加签名
 *       template: "您的验证码是：{code}。请不要把验证码泄露给其他人。"   # 必须与后台报备模板一字不差
 *
 * 重要：content 里不能再带签名，否则会报 4072"短信内容必须与报备模板格式匹配"。
 */
@Slf4j
@Component
@ConditionalOnProperty(name = "sms.provider", havingValue = "ihuyi")
public class IhuyiSmsSender implements SmsSender {

    private static final String API_URL = "https://106.ihuyi.com/webservice/sms.php?method=Submit";
    private static final Pattern CODE_PATTERN = Pattern.compile("<code>(-?\\d+)</code>");
    private static final Pattern MSG_PATTERN  = Pattern.compile("<msg>(.+?)</msg>");

    @Value("${sms.ihuyi.api-id}")
    private String apiId;

    @Value("${sms.ihuyi.api-key}")
    private String apiKey;

    @Value("${sms.ihuyi.sign-name:【达信通】}")
    private String signName;  // 仅用于日志展示，互亿会自动给短信加签名

    @Value("${sms.ihuyi.template:您的验证码是：{code}。请不要把验证码泄露给其他人。}")
    private String template;

    @Override
    public boolean sendCode(String phone, String code) {
        // 注意：互亿无线会自动给短信加上你后台报备的签名（如【达信通】），
        // 因此 content 里 *不要* 再写一遍签名，否则报错 4072
        String content = template.replace("{code}", code);

        Map<String, Object> params = new HashMap<>();
        params.put("account", apiId);
        // 互亿要求 API 密码用 MD5 加密
        params.put("password", DigestUtil.md5Hex(apiKey));
        params.put("mobile", phone);
        params.put("content", content);
        params.put("format", "xml");

        try (HttpResponse resp = HttpRequest.post(API_URL)
                .form(params)
                .timeout(10000)
                .execute()) {
            String body = resp.body();
            log.info("ihuyi sms resp: {}", body);

            int statusCode = parseInt(body, CODE_PATTERN);
            String msg = parseString(body, MSG_PATTERN);

            if (statusCode == 2) {
                log.info("ihuyi sms success, phone={}, msg={}", phone, msg);
                return true;
            } else {
                log.error("ihuyi sms fail, phone={}, code={}, msg={}", phone, statusCode, msg);
                return false;
            }
        } catch (Exception e) {
            log.error("ihuyi sms exception, phone={}", phone, e);
            return false;
        }
    }

    private int parseInt(String xml, Pattern p) {
        Matcher m = p.matcher(xml);
        if (m.find()) {
            try { return Integer.parseInt(m.group(1)); } catch (NumberFormatException e) { return -1; }
        }
        return -1;
    }

    private String parseString(String xml, Pattern p) {
        Matcher m = p.matcher(xml);
        return m.find() ? m.group(1) : "";
    }
}
