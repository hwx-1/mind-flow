package com.mental.health.websocket;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Component
public class WsSessionRegistry {

    private final Map<Long, WebSocketSession> sessions = new ConcurrentHashMap<>();

    public void register(Long uid, WebSocketSession session) {
        WebSocketSession old = sessions.put(uid, session);
        if (old != null && old.isOpen()) {
            try { old.close(); } catch (IOException ignored) {}
        }
        log.info("ws register uid={} total={}", uid, sessions.size());
    }

    public void remove(Long uid) {
        sessions.remove(uid);
        log.info("ws remove uid={} total={}", uid, sessions.size());
    }

    public boolean isOnline(Long uid) {
        WebSocketSession session = sessions.get(uid);
        return session != null && session.isOpen();
    }

    public boolean sendTo(Long uid, String json) {
        WebSocketSession s = sessions.get(uid);
        if (s == null || !s.isOpen()) return false;
        try {
            synchronized (s) { s.sendMessage(new TextMessage(json)); }
            return true;
        } catch (IOException e) {
            log.warn("ws send fail uid={} {}", uid, e.getMessage());
            return false;
        }
    }
}
