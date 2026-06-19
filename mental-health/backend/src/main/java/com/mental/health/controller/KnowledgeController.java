package com.mental.health.controller;

import com.mental.health.common.R;
import com.mental.health.dto.KnowledgeDto;
import com.mental.health.entity.KnowledgeBase;
import com.mental.health.security.UserContext;
import com.mental.health.service.KnowledgeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/knowledge")
@RequiredArgsConstructor
public class KnowledgeController {

    private final KnowledgeService service;

    /** 列出我可见的所有知识 (全局 + 我自己的私有) */
    @GetMapping
    public R<List<KnowledgeBase>> list() {
        return R.ok(service.list(UserContext.require()));
    }

    /** 创建一条 */
    @PostMapping
    public R<KnowledgeBase> create(@Valid @RequestBody KnowledgeDto.CreateReq req) {
        return R.ok(service.create(UserContext.require(), req));
    }

    /** 更新 (改标题/内容/启用状态) */
    @PutMapping("/{id}")
    public R<KnowledgeBase> update(@PathVariable Long id, @Valid @RequestBody KnowledgeDto.UpdateReq req) {
        return R.ok(service.update(UserContext.require(), id, req));
    }

    /** 删除 */
    @DeleteMapping("/{id}")
    public R<?> delete(@PathVariable Long id) {
        service.delete(UserContext.require(), id);
        return R.ok();
    }
}
