package com.mental.health.ai;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.mental.health.entity.KnowledgeBase;
import com.mental.health.mapper.KnowledgeBaseMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

/**
 * 把用户启用的知识库条目 + 全局启用的知识库条目,组装成 system prompt
 * 注入到 AI 对话上下文,使 DeepSeek 回答时遵循用户自定义的边界。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class KnowledgePromptBuilder {

    private final KnowledgeBaseMapper mapper;

    /** 单条最大长度,与 DTO 校验一致 */
    private static final int MAX_PER_ITEM = 2000;
    /** 总长度上限,避免 token 爆炸 */
    private static final int MAX_TOTAL = 20_000;

    /**
     * 构造知识库 system 消息内容
     * @param userId 当前用户
     * @return 如果没有任何启用条目,返回 null;否则返回拼好的 prompt 文本
     */
    public String build(Long userId) {
        // 全局条目 (任何用户都生效)
        List<KnowledgeBase> globals = mapper.selectList(new LambdaQueryWrapper<KnowledgeBase>()
                .eq(KnowledgeBase::getScope, "global")
                .eq(KnowledgeBase::getEnabled, 1)
                .orderByAsc(KnowledgeBase::getCreatedAt));

        // 用户私有条目
        List<KnowledgeBase> privates = mapper.selectList(new LambdaQueryWrapper<KnowledgeBase>()
                .eq(KnowledgeBase::getUserId, userId)
                .eq(KnowledgeBase::getScope, "private")
                .eq(KnowledgeBase::getEnabled, 1)
                .orderByAsc(KnowledgeBase::getCreatedAt));

        if (globals.isEmpty() && privates.isEmpty()) return null;

        StringBuilder sb = new StringBuilder();
        sb.append("以下是用户和管理员提供的补充知识/偏好,请在不违反基本对话准则的前提下参考并体现:\n\n");

        int total = sb.length();
        List<KnowledgeBase> merged = new ArrayList<>(globals.size() + privates.size());
        merged.addAll(globals);
        merged.addAll(privates);

        int idx = 1;
        for (KnowledgeBase k : merged) {
            String item = String.format("[%d] %s\n%s\n\n",
                    idx++,
                    truncate(k.getTitle(), 80),
                    truncate(k.getContent(), MAX_PER_ITEM));
            if (total + item.length() > MAX_TOTAL) {
                log.info("knowledge prompt truncated at item {}, total={} bytes", idx - 1, total);
                break;
            }
            sb.append(item);
            total += item.length();
        }
        return sb.toString();
    }

    private String truncate(String s, int max) {
        if (s == null) return "";
        return s.length() <= max ? s : s.substring(0, max);
    }
}
