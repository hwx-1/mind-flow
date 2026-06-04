package com.mental.health.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Data
@Component
@ConfigurationProperties(prefix = "sms.ihuyi")
public class IhuyiSmsProperties {
    private boolean enabled = true;
    private String url = "https://api.ihuyi.com/sms/Submit.json";
    private String account;
    private String password;
    private String templateId = "1";
    private int ttlSeconds = 300;
    private int minIntervalSeconds = 60;
}
