package com.mental.health.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;

import java.util.*;

@Slf4j
@Component
public class DeepSeekClient {

    @Value("${ai.deepseek.api-key}")  private String apiKey;
    @Value("${ai.deepseek.base-url}") private String baseUrl;
    @Value("${ai.deepseek.model}")    private String model;

    private final ObjectMapper om = new ObjectMapper();
    private WebClient client;

    private WebClient client() {
        if (client == null) {
            client = WebClient.builder()
                    .baseUrl(baseUrl)
                    .defaultHeader(HttpHeaders.AUTHORIZATION, "Bearer " + apiKey)
                    .codecs(c -> c.defaultCodecs().maxInMemorySize(8 * 1024 * 1024))
                    .build();
        }
        return client;
    }

    /**
     * 流式对话，返回每次新增的 delta 字符串
     * messages: [{role: user/assistant/system, content: "..."}]
     */
    public Flux<String> stream(List<Map<String, String>> messages) {
        Map<String, Object> body = new HashMap<>();
        body.put("model", model);
        body.put("messages", messages);
        body.put("stream", true);
        body.put("temperature", 0.7);

        return client().post()
                .uri("/chat/completions")
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.TEXT_EVENT_STREAM)
                .bodyValue(body)
                .retrieve()
                .bodyToFlux(String.class)
                .filter(line -> line != null && !line.isBlank())
                .takeWhile(line -> !line.equals("[DONE]"))
                .mapNotNull(this::parseDelta)
                .doOnError(e -> log.error("deepseek stream error", e));
    }

    private String parseDelta(String chunk) {
        try {
            if (chunk.startsWith("data:")) {
                chunk = chunk.substring(5).trim();
            }
            if ("[DONE]".equals(chunk)) {
                return "";
            }
            JsonNode n = om.readTree(chunk);
            JsonNode delta = n.path("choices").path(0).path("delta").path("content");
            return delta.isMissingNode() || delta.isNull() ? "" : delta.asText();
        } catch (Exception e) {
            log.debug("skip chunk {}", chunk);
            return "";
        }
    }
}
