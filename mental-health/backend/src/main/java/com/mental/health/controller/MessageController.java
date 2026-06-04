package com.mental.health.controller;

import com.mental.health.common.R;
import com.mental.health.security.UserContext;
import com.mental.health.service.MessageService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/message")
@RequiredArgsConstructor
public class MessageController {

    private final MessageService messageService;

    @GetMapping("/notifications")
    public R<?> notifications(@RequestParam(defaultValue = "all") String type,
                              @RequestParam(defaultValue = "1") int page,
                              @RequestParam(defaultValue = "20") int size) {
        return R.ok(messageService.notifications(UserContext.require(), type, page, size));
    }

    @GetMapping("/unread-count")
    public R<?> unreadCount() {
        return R.ok(messageService.unreadCount(UserContext.require()));
    }

    @PostMapping("/read")
    public R<?> read(@RequestBody Map<String, Object> body) {
        String type = (String) body.getOrDefault("type", "all");
        @SuppressWarnings("unchecked")
        List<Number> rawIds = (List<Number>) body.get("ids");
        List<Long> ids = rawIds == null ? null : rawIds.stream().map(Number::longValue).toList();
        messageService.markRead(UserContext.require(), type, ids);
        return R.ok();
    }

    @GetMapping("/chats")
    public R<?> chats() {
        return R.ok(messageService.chats(UserContext.require()));
    }

    @GetMapping("/chats/{userId}")
    public R<?> chatWith(@PathVariable Long userId) {
        return R.ok(messageService.chatWith(UserContext.require(), userId));
    }

    @PostMapping("/send")
    public R<?> send(@RequestBody Map<String, Object> body) {
        Long toUserId = Long.valueOf(body.get("toUserId").toString());
        String content = (String) body.get("content");
        String type = (String) body.getOrDefault("type", "text");
        return R.ok(messageService.send(UserContext.require(), toUserId, content, type));
    }
}
