package com.mental.health.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.mental.health.common.R;
import com.mental.health.entity.AiMessage;
import com.mental.health.entity.Announcement;
import com.mental.health.entity.User;
import com.mental.health.mapper.AnnouncementMapper;
import com.mental.health.service.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 管理后台接口，全部以 /admin 开头。
 * 权限：AdminInterceptor 已拦截 /admin/**，确保只有 role=admin 能访问。
 */
@RestController
@RequestMapping("/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;
    private final AnnouncementMapper announcementMapper;

    // ===== 公告管理 =====
    /** 发布公告（status=1 上线） */
    @PostMapping("/announcements")
    public R<Announcement> publishAnnouncement(@RequestBody Map<String, String> body) {
        String content = body.get("content");
        if (content == null || content.isBlank()) {
            return R.fail("公告内容不能为空");
        }
        Announcement a = new Announcement();
        a.setTitle(body.getOrDefault("title", ""));
        a.setContent(content);
        a.setStatus(1);
        announcementMapper.insert(a);
        return R.ok(a);
    }

    /** 公告列表（仅上线，按时间倒序） */
    @GetMapping("/announcements")
    public R<List<Announcement>> announcements() {
        return R.ok(announcementMapper.selectList(
                new LambdaQueryWrapper<Announcement>().orderByDesc(Announcement::getId)));
    }

    /** 下线公告（逻辑删除：status=0） */
    @PostMapping("/announcements/{id}/offline")
    public R<?> offlineAnnouncement(@PathVariable Long id) {
        announcementMapper.deleteById(id);
        return R.ok();
    }

    // ===== 概览 =====
    @GetMapping("/stats")
    public R<Map<String, Object>> stats() {
        return R.ok(adminService.stats());
    }

    @GetMapping("/trend")
    public R<Map<String, Object>> trend() {
        return R.ok(adminService.trend());
    }

    // ===== 用户管理 =====
    @GetMapping("/users")
    public R<Page<User>> users(@RequestParam(defaultValue = "1") int page,
                               @RequestParam(defaultValue = "10") int size,
                               @RequestParam(required = false) String keyword) {
        return R.ok(adminService.userList(page, size, keyword));
    }

    @PostMapping("/users/{id}/ban")
    public R<?> banUser(@PathVariable Long id) {
        adminService.setUserStatus(id, 0);
        return R.ok();
    }

    @PostMapping("/users/{id}/unban")
    public R<?> unbanUser(@PathVariable Long id) {
        adminService.setUserStatus(id, 1);
        return R.ok();
    }

    // ===== 帖子管理 =====
    @GetMapping("/posts")
    public R<Page<Map<String, Object>>> posts(@RequestParam(defaultValue = "1") int page,
                                              @RequestParam(defaultValue = "10") int size,
                                              @RequestParam(required = false) String keyword,
                                              @RequestParam(required = false) Integer status) {
        return R.ok(adminService.postList(page, size, keyword, status));
    }

    @PostMapping("/posts/{id}/offline")
    public R<?> offlinePost(@PathVariable Long id) {
        adminService.setPostStatus(id, 0);
        return R.ok();
    }

    @PostMapping("/posts/{id}/online")
    public R<?> onlinePost(@PathVariable Long id) {
        adminService.setPostStatus(id, 1);
        return R.ok();
    }

    // ===== 评论管理 =====
    @GetMapping("/comments")
    public R<Page<Map<String, Object>>> comments(@RequestParam(defaultValue = "1") int page,
                                                 @RequestParam(defaultValue = "10") int size,
                                                 @RequestParam(required = false) String keyword) {
        return R.ok(adminService.commentList(page, size, keyword));
    }

    @PostMapping("/comments/{id}/delete")
    public R<?> deleteComment(@PathVariable Long id) {
        adminService.deleteComment(id);
        return R.ok();
    }

    // ===== AI 会话管理 =====
    @GetMapping("/ai/sessions")
    public R<Page<Map<String, Object>>> aiSessions(@RequestParam(defaultValue = "1") int page,
                                                   @RequestParam(defaultValue = "10") int size,
                                                   @RequestParam(required = false) String business) {
        return R.ok(adminService.aiSessionList(page, size, business));
    }

    @GetMapping("/ai/sessions/{id}/messages")
    public R<List<AiMessage>> aiMessages(@PathVariable Long id) {
        return R.ok(adminService.aiMessages(id));
    }

    // ===== 消息 / 通知 =====
    @GetMapping("/chats")
    public R<Page<Map<String, Object>>> chats(@RequestParam(defaultValue = "1") int page,
                                              @RequestParam(defaultValue = "10") int size) {
        return R.ok(adminService.chatList(page, size));
    }

    @GetMapping("/notifications")
    public R<Page<Map<String, Object>>> notifications(@RequestParam(defaultValue = "1") int page,
                                                      @RequestParam(defaultValue = "10") int size,
                                                      @RequestParam(required = false) String type) {
        return R.ok(adminService.notificationList(page, size, type));
    }
}
