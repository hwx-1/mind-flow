package com.mental.health.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.mental.health.common.BizException;
import com.mental.health.dto.KnowledgeDto;
import com.mental.health.entity.KnowledgeBase;
import com.mental.health.entity.User;
import com.mental.health.mapper.KnowledgeBaseMapper;
import com.mental.health.mapper.UserMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class KnowledgeService {

    private final KnowledgeBaseMapper mapper;
    private final UserMapper userMapper;

    /** 用户最多 50 条私有条目;管理员的 global 不计入此限额 */
    private static final int USER_PRIVATE_LIMIT = 50;

    /**
     * 列出当前用户可见的所有条目:
     * - 全部 global (任何用户都看得到,但只有管理员能编辑)
     * - 自己创建的 private
     */
    public List<KnowledgeBase> list(Long uid) {
        // 全局条目
        List<KnowledgeBase> globals = mapper.selectList(new LambdaQueryWrapper<KnowledgeBase>()
                .eq(KnowledgeBase::getScope, "global")
                .orderByAsc(KnowledgeBase::getCreatedAt));
        // 私有条目
        List<KnowledgeBase> privates = mapper.selectList(new LambdaQueryWrapper<KnowledgeBase>()
                .eq(KnowledgeBase::getUserId, uid)
                .eq(KnowledgeBase::getScope, "private")
                .orderByAsc(KnowledgeBase::getCreatedAt));
        List<KnowledgeBase> result = new ArrayList<>(globals.size() + privates.size());
        result.addAll(globals);
        result.addAll(privates);
        return result;
    }

    public KnowledgeBase create(Long uid, KnowledgeDto.CreateReq req) {
        String scope = req.scope == null || req.scope.isBlank() ? "private" : req.scope.trim();
        if (!"private".equals(scope) && !"global".equals(scope)) {
            throw new BizException("scope 必须是 private 或 global");
        }
        // 仅管理员可建 global
        if ("global".equals(scope) && !isAdmin(uid)) {
            throw new BizException(403, "仅管理员可创建全局知识");
        }
        // 用户私有条目限额
        if ("private".equals(scope)) {
            long cnt = mapper.selectCount(new LambdaQueryWrapper<KnowledgeBase>()
                    .eq(KnowledgeBase::getUserId, uid)
                    .eq(KnowledgeBase::getScope, "private"));
            if (cnt >= USER_PRIVATE_LIMIT) {
                throw new BizException("个人知识库最多 " + USER_PRIVATE_LIMIT + " 条,请删除一些再添加");
            }
        }
        KnowledgeBase k = new KnowledgeBase();
        k.setUserId(uid);
        k.setScope(scope);
        k.setTitle(req.title.trim());
        k.setContent(req.content);
        k.setEnabled(1);
        mapper.insert(k);
        return k;
    }

    public KnowledgeBase update(Long uid, Long id, KnowledgeDto.UpdateReq req) {
        KnowledgeBase k = mapper.selectById(id);
        if (k == null) throw new BizException("知识不存在");
        checkOwnership(uid, k);
        if (req.title != null && !req.title.isBlank()) k.setTitle(req.title.trim());
        if (req.content != null && !req.content.isBlank()) k.setContent(req.content);
        if (req.enabled != null) k.setEnabled(req.enabled == 0 ? 0 : 1);
        mapper.updateById(k);
        return k;
    }

    public void delete(Long uid, Long id) {
        KnowledgeBase k = mapper.selectById(id);
        if (k == null) throw new BizException("知识不存在");
        checkOwnership(uid, k);
        mapper.deleteById(id);
    }

    /**
     * 权限检查:
     * - private: 只有创建者能改
     * - global:  只有管理员能改
     */
    private void checkOwnership(Long uid, KnowledgeBase k) {
        if ("global".equals(k.getScope())) {
            if (!isAdmin(uid)) throw new BizException(403, "仅管理员可编辑全局知识");
        } else {
            if (!k.getUserId().equals(uid)) throw new BizException(403, "无权操作");
        }
    }

    private boolean isAdmin(Long uid) {
        User u = userMapper.selectById(uid);
        return u != null && "admin".equals(u.getRole());
    }
}
