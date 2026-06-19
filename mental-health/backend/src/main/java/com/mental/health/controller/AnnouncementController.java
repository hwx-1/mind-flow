package com.mental.health.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.mental.health.common.R;
import com.mental.health.entity.Announcement;
import com.mental.health.mapper.AnnouncementMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 公告接口（App 端读取）。
 * 公告由网页版管理后台(PHP)写入同一张 announcement 表，App 与网页共享。
 * status 为全局逻辑删除字段，查询自动过滤为仅 status=1（上线）的记录。
 */
@RestController
@RequestMapping("/announcement")
@RequiredArgsConstructor
public class AnnouncementController {

    private final AnnouncementMapper announcementMapper;

    /** 最新一条上线公告；无则返回 null。 */
    @GetMapping("/latest")
    public R<Announcement> latest() {
        Announcement latest = announcementMapper.selectOne(
                new LambdaQueryWrapper<Announcement>()
                        .orderByDesc(Announcement::getId)
                        .last("LIMIT 1"));
        return R.ok(latest);
    }
}
