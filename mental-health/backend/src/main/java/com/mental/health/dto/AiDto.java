package com.mental.health.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

public class AiDto {
    @Data
    public static class CreateSession {
        @NotBlank public String business;  // mental/study/general
        public String title;
    }
    @Data
    public static class ChatReq {
        @NotNull public Long sessionId;
        @NotBlank public String content;
    }
}
