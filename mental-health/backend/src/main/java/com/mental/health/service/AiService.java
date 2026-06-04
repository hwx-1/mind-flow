package com.mental.health.service;

import cn.hutool.core.util.StrUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.mental.health.ai.BusinessGuard;
import com.mental.health.ai.DeepSeekClient;
import com.mental.health.ai.KnowledgePromptBuilder;
import com.mental.health.ai.Prompts;
import com.mental.health.common.BizException;
import com.mental.health.dto.AiDto;
import com.mental.health.entity.AiMessage;
import com.mental.health.entity.AiSession;
import com.mental.health.mapper.AiMessageMapper;
import com.mental.health.mapper.AiSessionMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import reactor.core.publisher.Flux;

import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class AiService {

    private final AiSessionMapper sessionMapper;
    private final AiMessageMapper messageMapper;
    private final DeepSeekClient deepSeek;
    private final KnowledgePromptBuilder knowledgePromptBuilder;   // ★ 新增

    public List<AiSession> sessions(Long uid, String business) {
        LambdaQueryWrapper<AiSession> qw = new LambdaQueryWrapper<AiSession>()
                .eq(AiSession::getUserId, uid)
                .orderByDesc(AiSession::getUpdatedAt);
        if (StrUtil.isNotBlank(business)) qw.eq(AiSession::getBusiness, business);
        return sessionMapper.selectList(qw);
    }

    public AiSession createSession(Long uid, AiDto.CreateSession req) {
        if (!Set.of("mental", "study", "general").contains(req.business)) {
            throw new BizException("无效的业务方向");
        }
        AiSession s = new AiSession();
        s.setUserId(uid);
        s.setBusiness(req.business);
        s.setTitle(StrUtil.isBlank(req.title) ? defaultTitle(req.business) : req.title);
        sessionMapper.insert(s);
        return s;
    }

    public void deleteSession(Long uid, Long id) {
        AiSession s = sessionMapper.selectById(id);
        if (s == null) throw new BizException("会话不存在");
        if (!s.getUserId().equals(uid)) throw new BizException(403, "无权操作");
        sessionMapper.deleteById(id);
        messageMapper.delete(new LambdaQueryWrapper<AiMessage>().eq(AiMessage::getSessionId, id));
    }

    public List<AiMessage> messages(Long uid, Long sessionId) {
        AiSession s = sessionMapper.selectById(sessionId);
        if (s == null || !s.getUserId().equals(uid)) throw new BizException(403, "无权访问");
        return messageMapper.selectList(new LambdaQueryWrapper<AiMessage>()
                .eq(AiMessage::getSessionId, sessionId)
                .orderByAsc(AiMessage::getCreatedAt));
    }

    /**
     * 流式聊天 —— 业务边界守护 + 用户/全局知识库注入
     */
    public Flux<String> chat(Long uid, AiDto.ChatReq req) {
        AiSession s = sessionMapper.selectById(req.sessionId);
        if (s == null || !s.getUserId().equals(uid)) throw new BizException(403, "无权操作");

        // 写入用户消息
        AiMessage userMsg = new AiMessage();
        userMsg.setSessionId(req.sessionId);
        userMsg.setRole("user");
        userMsg.setContent(req.content);
        messageMapper.insert(userMsg);

        // ★ 业务边界守护：第 1 层关键词快速过滤
        BusinessGuard.GuardResult guard = BusinessGuard.check(s.getBusiness(), req.content);
        if (!guard.pass) {
            log.info("guard reject business={} content={}", s.getBusiness(),
                    StrUtil.maxLength(req.content, 30));
            persistAssistant(s, guard.refusalMessage);
            return Flux.just(guard.refusalMessage);
        }

        // 构造对话上下文
        List<Map<String, String>> ctx = new ArrayList<>();
        // 1) 业务边界 system prompt (放最前,优先级最高)
        ctx.add(Map.of("role", "system", "content", Prompts.of(s.getBusiness())));

        // 2) ★ 新增: 知识库 system 消息 (用户私有 + 全局,均生效)
        String kb = knowledgePromptBuilder.build(uid);
        if (kb != null && !kb.isBlank()) {
            ctx.add(Map.of("role", "system", "content", kb));
        }

        // 3) 历史消息
        List<AiMessage> history = messageMapper.selectList(new LambdaQueryWrapper<AiMessage>()
                .eq(AiMessage::getSessionId, req.sessionId)
                .orderByDesc(AiMessage::getCreatedAt).last("limit 20"));
        Collections.reverse(history);
        for (AiMessage h : history) ctx.add(Map.of("role", h.getRole(), "content", h.getContent()));

        StringBuilder full = new StringBuilder();
        return deepSeek.stream(ctx)
                .doOnNext(full::append)
                .doOnComplete(() -> persistAssistant(s, full.toString()));
    }

    @Transactional
    protected void persistAssistant(AiSession s, String content) {
        if (StrUtil.isBlank(content)) return;
        AiMessage a = new AiMessage();
        a.setSessionId(s.getId());
        a.setRole("assistant");
        a.setContent(content);
        messageMapper.insert(a);
        s.setLastMsg(StrUtil.maxLength(content, 60));
        sessionMapper.updateById(s);
    }

    private String defaultTitle(String b) {
        return switch (b) {
            case "mental" -> "心理咨询";
            case "study"  -> "学习辅导";
            default       -> "综合聊天";
        };
    }
}
