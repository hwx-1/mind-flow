package com.mental.health.controller;

import com.mental.health.common.R;
import com.mental.health.dto.AiDto;
import com.mental.health.entity.AiMessage;
import com.mental.health.entity.AiSession;
import com.mental.health.security.UserContext;
import com.mental.health.service.AiService;
import jakarta.validation.Valid;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;

import java.time.Duration;
import java.util.List;

@RestController
@RequestMapping("/ai")
@RequiredArgsConstructor
public class AiController {

    private final AiService aiService;

    @GetMapping("/sessions")
    public R<List<AiSession>> sessions(@RequestParam(required = false) String business) {
        return R.ok(aiService.sessions(UserContext.require(), business));
    }

    @PostMapping("/sessions")
    public R<AiSession> create(@Valid @RequestBody AiDto.CreateSession req) {
        return R.ok(aiService.createSession(UserContext.require(), req));
    }

    @DeleteMapping("/sessions/{id}")
    public R<?> delete(@PathVariable Long id) {
        aiService.deleteSession(UserContext.require(), id);
        return R.ok();
    }

    @GetMapping("/sessions/{id}/messages")
    public R<List<AiMessage>> messages(@PathVariable Long id) {
        return R.ok(aiService.messages(UserContext.require(), id));
    }

    /**
     * SSE 流式对话
     * 客户端用 fetch + ReadableStream 或 EventSource 接收。
     * 每帧：data: {"delta":"片段"}
     * 结束：data: [DONE]
     */
    @PostMapping(value = "/chat", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<ServerSentEvent<String>> chat(@Valid @RequestBody AiDto.ChatReq req,
                                              HttpServletResponse response) {
        response.setHeader("Cache-Control", "no-cache");
        response.setHeader("Connection", "keep-alive");
        response.setHeader("X-Accel-Buffering", "no");
        Long uid = UserContext.require();
        Flux<ServerSentEvent<String>> data = aiService.chat(uid, req)
                .filter(s -> s != null && !s.isEmpty())
                .map(delta -> ServerSentEvent.<String>builder()
                        .data("{\"delta\":" + jsonEscape(delta) + "}")
                        .build());
        Flux<ServerSentEvent<String>> done = Flux.just(
                ServerSentEvent.<String>builder().data("[DONE]").build());
        // 防止连接长时间挂起：每 30s 一个心跳
        Flux<ServerSentEvent<String>> heartbeat = Flux.interval(Duration.ofSeconds(30))
                .map(i -> ServerSentEvent.<String>builder().comment("hb").build());
        return Flux.merge(data.concatWith(done), heartbeat).takeUntil(e -> "[DONE]".equals(e.data()));
    }

    private String jsonEscape(String s) {
        StringBuilder sb = new StringBuilder("\"");
        for (char c : s.toCharArray()) {
            switch (c) {
                case '\\' -> sb.append("\\\\");
                case '"'  -> sb.append("\\\"");
                case '\n' -> sb.append("\\n");
                case '\r' -> sb.append("\\r");
                case '\t' -> sb.append("\\t");
                case '\b' -> sb.append("\\b");
                case '\f' -> sb.append("\\f");
                default -> {
                    if (c < 0x20) sb.append(String.format("\\u%04x", (int) c));
                    else sb.append(c);
                }
            }
        }
        return sb.append('"').toString();
    }
}
