package com.mental.health.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Data
@Component
@ConfigurationProperties(prefix = "upload")
public class UploadProperties {
    private String storage = "local";
    private String path = "/www/wwwroot/static";
    private String urlPrefix = "http://39.96.36.94/static";
    private Oss oss = new Oss();

    public boolean ossEnabled() {
        return "oss".equalsIgnoreCase(storage);
    }

    @Data
    public static class Oss {
        private String endpoint = "https://oss-cn-beijing-internal.aliyuncs.com";
        private String publicEndpoint = "https://mental-healthy.oss-cn-beijing.aliyuncs.com";
        private String bucket = "mental-healthy";
        private String accessKeyId = "";
        private String accessKeySecret = "";
        private String prefix = "mental-health/";
    }
}
