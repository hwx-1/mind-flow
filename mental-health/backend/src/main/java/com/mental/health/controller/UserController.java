package com.mental.health.controller;

import com.mental.health.common.R;
import com.mental.health.entity.User;
import com.mental.health.security.UserContext;
import com.mental.health.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/profile")
    public R<?> mine() { return R.ok(userService.profile(UserContext.require(), UserContext.require())); }

    @GetMapping("/profile/{userId}")
    public R<?> other(@PathVariable Long userId) {
        return R.ok(userService.profile(UserContext.get(), userId));
    }

    @GetMapping("/search")
    public R<?> search(@RequestParam String keyword) {
        return R.ok(userService.search(UserContext.require(), keyword));
    }

    @PutMapping("/update")
    public R<?> update(@RequestBody User patch) {
        userService.update(UserContext.require(), patch);
        return R.ok();
    }

    @PutMapping("/password")
    public R<?> password(@RequestBody Map<String, String> body) {
        userService.changePassword(UserContext.require(), body.get("oldPassword"), body.get("newPassword"));
        return R.ok();
    }

    @PostMapping("/{userId}/follow")
    public R<?> follow(@PathVariable Long userId) {
        boolean followed = userService.toggleFollow(UserContext.require(), userId);
        return R.ok(Map.of("followed", followed));
    }

    @PostMapping("/{userId}/friend/request")
    public R<?> requestFriend(@PathVariable Long userId, @RequestBody(required = false) Map<String, Object> body) {
        String message = bodyString(body, "message");
        userService.requestFriend(UserContext.require(), userId, message);
        return R.ok();
    }

    @PostMapping("/friend/request-by-uid")
    public R<?> requestFriendByUid(@RequestBody Map<String, Object> body) {
        Object rawUid = body.get("uid");
        if (rawUid == null || String.valueOf(rawUid).isBlank()) {
            throw new com.mental.health.common.BizException(400, "UID不能为空");
        }
        Long targetUid;
        try {
            targetUid = Long.valueOf(String.valueOf(rawUid).trim());
        } catch (NumberFormatException e) {
            throw new com.mental.health.common.BizException(400, "UID格式不正确");
        }
        String message = bodyString(body, "message");
        userService.requestFriend(UserContext.require(), targetUid, message);
        return R.ok();
    }

    @GetMapping("/friend/requests")
    public R<?> friendRequests() {
        return R.ok(userService.friendRequests(UserContext.require()));
    }

    @GetMapping("/friends")
    public R<?> friends() {
        return R.ok(userService.friends(UserContext.require()));
    }

    @PostMapping("/friend/requests/{id}/accept")
    public R<?> acceptFriend(@PathVariable Long id) {
        userService.acceptFriend(UserContext.require(), id);
        return R.ok();
    }

    private String bodyString(Map<String, Object> body, String key) {
        if (body == null) {
            return "";
        }
        Object value = body.get(key);
        return value == null ? "" : String.valueOf(value);
    }
}
