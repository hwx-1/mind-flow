package com.mental.health.websocket;

import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.mental.health.common.BizException;
import com.mental.health.entity.ChatMessage;
import com.mental.health.security.JwtUtil;
import com.mental.health.service.MessageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

@Slf4j
@Component
@RequiredArgsConstructor
public class ImWebSocketHandler extends TextWebSocketHandler {

    private final WsSessionRegistry registry;
    private final JwtUtil jwtUtil;
    private final MessageService messageService;

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        Long uid = (Long) session.getAttributes().get("uid");
        if (uid == null) {
            try { session.close(CloseStatus.NOT_ACCEPTABLE); } catch (Exception ignored) {}
            return;
        }
        registry.register(uid, session);
    }

    /**
     * 客户端 -> 服务端：
     *   {"action":"chat","toUserId":2,"content":"你好","type":"text"}
     *   {"action":"ping"}
     */
    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        Long uid = (Long) session.getAttributes().get("uid");
        if (uid == null) return;
        try {
            JSONObject obj = JSONUtil.parseObj(message.getPayload());
            String action = obj.getStr("action", "");
            switch (action) {
                case "chat" -> {
                    Long to = obj.getLong("toUserId");
                    String content = obj.getStr("content");
                    String type = obj.getStr("type", "text");
                    if (to == null || content == null || content.isBlank()) return;
                    ChatMessage saved = messageService.send(uid, to, content, type);
                    // 推送给对方
                    JSONObject push = new JSONObject();
                    push.set("event", "chat");
                    push.set("data", saved);
                    registry.sendTo(to, push.toString());
                    // 回执给自己
                    JSONObject ack = new JSONObject();
                    ack.set("event", "ack");
                    ack.set("data", saved);
                    session.sendMessage(new TextMessage(ack.toString()));
                }
                case "ping" -> session.sendMessage(new TextMessage("{\"event\":\"pong\"}"));
                default -> log.debug("unknown action {}", action);
            }
        } catch (BizException e) {
            try {
                JSONObject err = new JSONObject();
                err.set("event", "error");
                JSONObject data = new JSONObject();
                data.set("message", e.getMessage());
                err.set("data", data);
                session.sendMessage(new TextMessage(err.toString()));
            } catch (Exception ignored) {}
        } catch (Exception e) {
            log.error("ws handle error", e);
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        Long uid = (Long) session.getAttributes().get("uid");
        if (uid != null) registry.remove(uid);
    }
}
