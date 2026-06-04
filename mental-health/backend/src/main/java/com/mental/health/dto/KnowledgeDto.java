package com.mental.health.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

public class KnowledgeDto {

    @Data
    public static class CreateReq {
        @NotBlank @Size(max = 80, message = "标题不超过 80 字")
        public String title;

        @NotBlank @Size(max = 2000, message = "内容不超过 2000 字")
        public String content;

        /** private / global  — global 仅管理员可设 */
        public String scope;
    }

    @Data
    public static class UpdateReq {
        @Size(max = 80, message = "标题不超过 80 字")
        public String title;

        @Size(max = 2000, message = "内容不超过 2000 字")
        public String content;

        public Integer enabled;
    }
}
