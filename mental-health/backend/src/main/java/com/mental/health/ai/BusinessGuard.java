package com.mental.health.ai;

import java.util.Arrays;
import java.util.List;
import java.util.regex.Pattern;

/**
 * 业务边界关键词守护
 * 在调用大模型之前先做一次粗筛，明显越界的直接拒答，省 token 省时间
 */
public class BusinessGuard {

    /** 心理咨询 —— 命中即放行 */
    private static final List<String> MENTAL_KEYWORDS = Arrays.asList(
            "情绪", "焦虑", "抑郁", "压力", "烦", "难过", "伤心", "痛苦", "孤独", "无助",
            "崩溃", "失眠", "睡不着", "做噩梦", "心情", "感受", "感情", "心理", "心累",
            "压抑", "委屈", "愤怒", "生气", "害怕", "恐惧", "担心", "迷茫", "空虚", "麻木",
            "自卑", "自责", "内疚", "羞愧", "自我", "性格", "原生家庭", "父母", "家人",
            "恋爱", "失恋", "分手", "前任", "暗恋", "喜欢", "爱情", "感情",
            "朋友", "友谊", "孤立", "排斥", "霸凌", "欺负", "矛盾", "冲突",
            "工作压力", "职场", "同事关系", "上司",
            "自杀", "自伤", "想死", "活着没意思", "不想活", "结束生命",
            "咨询", "倾诉", "陪我", "听我说", "和我聊聊",
            "冥想", "放松", "正念", "深呼吸", "调节",
            "你好", "嗨", "在吗", "有人吗"
    );

    /** 学习辅导 —— 命中即放行 */
    private static final List<String> STUDY_KEYWORDS = Arrays.asList(
            "学习", "学不会", "学不进", "学习方法", "怎么学", "怎么背", "记不住",
            "背单词", "英语", "语法", "翻译", "口语", "听力", "阅读", "写作", "作文",
            "数学", "公式", "函数", "方程", "几何", "代数", "概率", "微积分",
            "物理", "化学", "生物", "历史", "地理", "政治", "语文",
            "编程", "代码", "程序", "算法", "数据结构", "Python", "Java", "JavaScript",
            "C++", "C#", "Go", "Rust", "HTML", "CSS", "React", "Vue", "数据库", "SQL",
            "考试", "考研", "高考", "中考", "四六级", "雅思", "托福", "GRE", "GMAT",
            "复习", "刷题", "笔记", "知识点", "考点", "重点",
            "番茄钟", "费曼", "间隔重复", "记忆法",
            "时间管理", "学习计划", "课程表", "拖延", "专注", "效率",
            "解释", "讲解", "什么是", "为什么", "怎么", "原理", "区别", "对比",
            "你好", "嗨", "在吗"
    );

    /** 黑名单 —— 任何业务都拒答 */
    private static final List<String> BLACKLIST = Arrays.asList(
            "翻墙", "VPN破解", "色情", "黄色", "毒品", "赌博",
            "炸弹", "枪支", "杀人", "投毒"
    );

    /** 判断是否在业务范围内（粗筛） */
    public static GuardResult check(String business, String content) {
        if (content == null || content.isBlank()) {
            return new GuardResult(false, "消息为空");
        }
        String text = content.toLowerCase();

        // 黑名单优先
        for (String w : BLACKLIST) {
            if (text.contains(w.toLowerCase())) {
                return new GuardResult(false, refusalBlacklist());
            }
        }

        // 极短消息（如"你好"、"嗨"）放行，让大模型处理
        if (content.length() <= 6) return new GuardResult(true, null);

        // general 业务不做关键词过滤（除黑名单）
        if ("general".equals(business)) return new GuardResult(true, null);

        // mental 业务：命中心理关键词放行，命中学习关键词且没命中心理关键词 → 拒答
        if ("mental".equals(business)) {
            boolean hitMental = anyMatch(text, MENTAL_KEYWORDS);
            boolean hitStudy  = anyMatch(text, STUDY_KEYWORDS);
            if (hitStudy && !hitMental) {
                return new GuardResult(false, refusalMental(content));
            }
            return new GuardResult(true, null);
        }

        // study 业务
        if ("study".equals(business)) {
            boolean hitStudy  = anyMatch(text, STUDY_KEYWORDS);
            boolean hitMental = anyMatch(text, MENTAL_KEYWORDS);
            if (hitMental && !hitStudy) {
                return new GuardResult(false, refusalStudy(content));
            }
            return new GuardResult(true, null);
        }

        return new GuardResult(true, null);
    }

    private static boolean anyMatch(String text, List<String> words) {
        for (String w : words) {
            if (text.contains(w.toLowerCase())) return true;
        }
        return false;
    }

    private static String refusalMental(String content) {
        return "抱歉，我是心理咨询助手，主要陪你聊关于情绪、压力、人际关系这些心理方面的话题哦～\n\n"
             + "你刚才问的内容看起来更适合【学习辅导】或【综合聊天】助手。可以返回上一页切换试试。\n\n"
             + "如果你最近心情上有什么困扰，随时告诉我，我在这里 💗";
    }

    private static String refusalStudy(String content) {
        return "我是学习辅导助手，专门陪你攻克学习上的难题 📚\n\n"
             + "你问的这个话题看起来更适合【心理咨询】或【综合聊天】助手。可以返回上一页切换试试。\n\n"
             + "如果你在学习上有任何问题（方法、知识、计划、考试…），尽管来找我！";
    }

    private static String refusalBlacklist() {
        return "抱歉，这个话题我没法回答呢。我们聊点别的吧～";
    }

    /** 结果对象 */
    public static class GuardResult {
        public final boolean pass;
        public final String refusalMessage;
        public GuardResult(boolean pass, String refusalMessage) {
            this.pass = pass;
            this.refusalMessage = refusalMessage;
        }
    }
}
