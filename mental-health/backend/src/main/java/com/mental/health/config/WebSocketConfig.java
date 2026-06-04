package com.mental.health.config;

import com.mental.health.websocket.ImWebSocketHandler;
import com.mental.health.websocket.WsAuthInterceptor;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketConfigurer {

    private final ImWebSocketHandler handler;
    private final WsAuthInterceptor interceptor;

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(handler, "/ws/im")
                .addInterceptors(interceptor)
                .setAllowedOriginPatterns("*");
    }
}
