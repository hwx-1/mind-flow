# 🌟 心晴 (Mind Flow) — 基于 DeepSeek 大模型构建的 AI 心理健康社区平台

<div align="center">
  <p><strong>一个具备长期记忆（Personal RAG）与情感共鸣的数字心灵驿站</strong></p>
  <p>
    <a href="https://xsnbb.xyz" target="_blank">🌐 官方网站 (xsnbb.xyz)</a> | 
    <a href="https://xsnbb.xyz/api" target="_blank">🔌 后端 API 接口</a>
  </p>
  <p>
    <img src="https://img.shields.io/badge/React-18.3-blue?style=flat-square&logo=react" alt="React">
    <img src="https://img.shields.io/badge/TypeScript-5.0-blue?style=flat-square&logo=typescript" alt="TypeScript">
    <img src="https://img.shields.io/badge/Spring%20Boot-3.2-green?style=flat-square&logo=springboot" alt="Spring Boot">
    <img src="https://img.shields.io/badge/MySQL-8.0-orange?style=flat-square&logo=mysql" alt="MySQL">
    <img src="https://img.shields.io/badge/Redis-7.2-red?style=flat-square&logo=redis" alt="Redis">
    <img src="https://img.shields.io/badge/DeepSeek-API-black?style=flat-square" alt="DeepSeek">
  </p>
</div>

---

## 📖 1. 项目介绍 (Project Introduction)

### 1.1 项目背景与核心痛点
现代社会中，心理健康问题日益凸显，但传统的心理咨询面临着**费用高昂、隐私顾虑、资源分布不均**以及**时间空间受限**等核心痛点。
市面上现有的 AI 聊天机器人虽然能够提供 24 小时在线的即时回应，但绝大多数属于**无状态、单次交互**的通用模型，存在以下问题：
1. **缺乏长期记忆**：每次开启新对话，用户都需要重复解释自己的个人背景、性格特征和历史经历。
2. **缺乏社区共鸣**：纯粹的人机对话容易让用户产生技术孤立感，无法替代人与人之间真实的经历分享与情感互助。
3. **技术响应滞后**：传统全量文本返回造成长时间的白屏等待，严重破坏心理疏导过程中的对话流畅度。

### 1.2 创新定位：AI + 社区双融合生态
**心晴 (Mind Flow)** 创新性地提出了 **“AI专属咨询 + 社区倾诉互助 + 长期偏好记忆 + 好友即时社交”** 的全栈式双融合生态闭环：
* **智能双引擎**：基于 **DeepSeek** 大模型，定制心理咨询、学习辅导、综合聊天三个核心垂类场景，通过流式输出（SSE）提供近乎零延迟的共情对话体验。
* **Personal RAG（用户知识库记忆）**：自研轻量级全量长效记忆提取系统，自动沉淀用户的偏好、学业背景、情感经历。在对话中自动、动态地向大模型注入定制化上下文，让 AI 拥有“越聊越懂你”的长期记忆。
* **高内聚社区与实时社交**：内建完整的动态发布、点赞、收藏、关注流体系；基于 WebSocket 自研高并发即时通信架构，打通人机、人人之间的全方位连接，形成全方位的心理支持网络。

---

## 🏗️ 2. 系统、技术与功能架构设计

### 2.1 系统架构图 (System Architecture)
```text
+-----------------------------------------------------------------------------------+
|                                  客户端层 (Client)                                |
|   +----------------+    +----------------+    +----------------+                  |
|   |  Web 浏览器端  |    |   H5 移动端    |    |  Vercel 托管   |                  |
|   | (React/Vite/TS)|    | (响应式适配)   |    | (前端全球CDN)  |                  |
|   +-------+--------+    +-------+--------+    +-------+--------+                  |
+-----------|---------------------|---------------------|---------------------------+
            | HTTP / HTTPS        | Server-Sent Events  | WebSocket (ws/wss)
+-----------|---------------------|---------------------|---------------------------+
|                                接入层 (Gateway)                                   |
|   +---------------------------------------------------------------------------+   |
|   |                        Nginx (反向代理 / 负载均衡)                        |   |
|   |   [静态资源分发]    [CORS 跨域处理]    [SSE/WS 协议升级]    [SSL 证书卸载] |   |
|   +---------------------------------------------------------------------------+   |
+-----------|---------------------|---------------------|---------------------------+
|                                服务层 (Service - Spring Boot 3)                   |
|   +-------------------+    +-------------------+    +-------------------+         |
|   |    用户认证模块   |    |    AI 智能对话    |    |    社区互动模块   |         |
|   | (Security/JWT)    |    | (SSE/Personal RAG)|    | (Post/Comment)    |         |
|   +-------------------+    +-------------------+    +-------------------+         |
|   |    实时社交模块   |    |    通知推送中心   |    |    核心基础设施   |         |
|   | (WebSocket/Chat)  |    | (Unread Engine)   |    | (MyBatisPlus/Druid|         |
|   +-------------------+    +-------------------+    +-------------------+         |
+-----------|---------------------|---------------------|---------------------------+
            | SQL / Transactions  | Cache / Pub-Sub     | REST / Stream
+-----------|---------------------|---------------------|---------------------------+
|                                数据与第三方服务层 (Data & Third-Party)            |
|  +-------------------+  +-------------------+  +-------------------+  +---------+ |
|  |     MySQL 8.0     |  |     Redis 7.2     |  |   阿里云 OSS      |  |DeepSeek | |
|  | (结构化持久化数据) |  | (高频缓存/限流器) |  | (媒体资产管理)    |  |  API    | |
|  +-------------------+  +-------------------+  +-------------------+  +---------+ |
+-----------------------------------------------------------------------------------+
```

### 2.2 技术架构矩阵 (Tech Stack Matrix)
* **前端生态**：`React 18.3` + `TypeScript 5.0` + `Vite` 构建核心单页应用；`React Router v6` 负责多层级路由拦截；`Zustand` 处理无状态单向数据流与全局多端状态同步；`TailwindCSS` 负责原子化响应式布局；通信层采用 `Axios`（常规 REST 请求）+ `EventSource / Fetch Streams`（处理 SSE）+ `Native WebSocket`（双向实时聊天）。
* **后端生态**：`Java 17` 基于 `Spring Boot 3.2` 重构核心脚手架；`Spring Security` 结合自定义 `JWT Filter` 实现状态无感刷新的无状态认证；持久层依托 `MyBatis Plus 3.5` 快速构建，底层采用 `Druid` 进行线程池连接监控管理；业务支撑组件包含 `Hutool` 全家桶、`Spring WebSocket` 模块以及 `Spring Async` 异步线程隔离池；对象存储托管至`阿里云 OSS`。
* **数据缓存与中间件**：`MySQL 8.0` 作为核心关系型数据库（读写分离就绪）；`Redis 7.2` 提供分布式 Session 缓存、点赞高频计数去重、手机验证码高并发限流以及 WebSocket 多节点发布订阅（Pub/Sub）信道支撑。

### 2.3 功能架构图 (Functional Tree)
```text
心晴 (Mind Flow) 平台全景功能树
├── [用户中心]
│   ├── 注册/常规密码登录
│   ├── 手机短信验证码快捷登录
│   ├── JWT 无状态强认证拦截与过期处理
│   └── 用户资料卡片 (头像OSS上传、多维度个性化签名、情感状态设置)
├── [AI 心理咨询中心]
│   ├── 垂类模型切分 (1. 心理疏导向 2. 学习学业辅导 3. 综合树洞陪伴)
│   ├── DeepSeek-V3/DeepSeek-R1 核心引擎动态无感知切换
│   ├── Server-Sent Events (SSE) 逐 Token 打字机级流式高响应渲染
│   └── 历史会话管理 (无级瀑布流加载、重命名、批量逻辑软删除)
├── [Personal RAG（AI 知识库）]
│   ├── 个人偏好与事实事实抽取器 (Fact Extractor)
│   ├── 核心偏好信息增删改查管理面板
│   ├── 知识上下文注入总开关 (全局控制当前 Prompt 构造状态)
│   └── 动态 Prompt 自动注入机制 (System Directive Context Injection)
├── [社区互助广场]
│   ├── 多图文丰富动态发布 (OSS 存储分发、多规格图片压缩)
│   ├── 互动行为三件套 (一键点赞去重、动态收藏夹、多层级树状嵌套评论)
│   ├── 用户关注流系统 (关注、粉丝双向映射，动态生成关注时间线)
│   └── 统一用户主页 (聚合展现个人动态、赞过的帖子、收藏的合集)
├── [即时社交系统]
│   ├── 全局用户模糊搜索与推荐机制
│   ├── 好友申请状态机模型 (待处理 -> 同意/拒绝/忽略)
│   ├── 经典双向好友拓扑关系维护
│   ├── 私聊会话管理器 (多会话按最后一条消息时间线动态倒叙置顶)
│   └── WebSocket 高可靠点对点(P2P)即时消息投递系统 (带ACK机制)
└── [智能通知中心]
    ├── 四大通知分类 (点赞互动、评论回复、新增关注、好友申请与消息)
    ├── 基于 Redis 计数器的未读消息红点推送引擎
    └── 全局 WebSocket 异步通知弹窗实时提醒
```

---

## 📁 3. 项目目录结构 (Directory Structure)

### 3.1 前端项目目录结构
```text
mind-flow-frontend/
├── .env.development         # 开发环境环境变量配置
├── .env.production          # 生产环境发布变量配置
├── index.html               # SPA 入口 HTML 模板
├── package.json             # 依赖管理依赖包说明
├── tailwind.config.js       # TailwindCSS 原子化样式剪裁与主题定制
├── vite.config.ts           # Vite 构建核心插件与反向代理配置
└── src/
    ├── main.tsx             # 应用启动装载入口
    ├── App.tsx              # 根路由渲染树
    ├── index.css            # 全局样式与 Tailwind 指令注入
    ├── api/                 # 统一网络请求层
    │   ├── http.ts          # Axios 实例封装（带拦截器、自动携带 Token）
    │   ├── auth.ts          # 认证相关（登录、注册、验证码）
    │   ├── ai.ts            # AI 会话、消息、知识库接口
    │   └── community.ts     # 帖子、评论、互动社交接口
    ├── components/          # 跨页面级高内聚公共组件
    │   ├── Button/          # 定制化原子按钮
    │   ├── Modal/           # 通用遮罩弹窗组件
    │   ├── Toast/           # 全局异步通知浮层
    │   └── Layout/          # 侧边栏、顶部导航、核心容器骨架
    ├── hooks/               # 全局可复用自定义 Hook 集合
    │   ├── useSSE.ts        # SSE 流式数据接收与打字机状态转换逻辑
    │   ├── useWebSocket.ts  # 全局 WebSocket 自动重连与状态订阅管理
    │   └── useUpload.ts     # 阿里云 OSS 直传及前端图片压缩封装
    ├── pages/               # 视图组件（按业务模块垂直划分）
    │   ├── Auth/            # 登录与注册模块页面
    │   ├── AI/              # AI 对话工作台、知识库设置管理面板
    │   ├── Square/          # 社区广场主页、帖子详情、发布工作区
    │   ├── Social/          # 好友管理、即时聊天双栏对话框
    │   └── Profile/         # 用户个人主页、系统设置中心
    ├── store/               # 基于 Zustand 的轻量级单向数据流全局状态机
    │   ├── userStore.ts     # 用户认证状态、Token 续期及个人资料缓存
    │   ├── aiStore.ts       # 当前活跃 AI 会话、消息流、知识库状态
    │   └── chatStore.ts     # 实时私聊会话列表、未读消息数红点状态
    ├── types/               # 统一 TypeScript 强类型声明目录
    │   ├── api.d.ts         # 后端统一响应结构 Result<T> 声明
    │   ├── models.d.ts      # 核心实体类 (User, Post, Message) 类型化
    │   └── store.d.ts       # 状态机 Action 与 State 接口定义
    └── utils/               # 纯函数无状态工具箱
        ├── date.ts          # 时间语义化处理（如“3分钟前”、“昨天”）
        └── storage.ts       # LocalStorage 与 SessionStorage 安全存取封装
```

### 3.2 后端项目目录结构
```text
mind-flow-backend/
├── pom.xml                  # Maven 核心依赖及多模块构建管理配置
└── src/
    └── main/
        ├── java/com/mindflow/
        │   ├── MindFlowApplication.java   # Spring Boot 主应用启动入口
        │   ├── annotation/                # 自定义切面注解（如 @LogExecution, @RateLimit）
        │   ├── common/                    # 全局高通用性基类与静态定义
        │   │   ├── api/                   # ResultCode, CommonResult 统一响应结构
        │   │   ├── constant/              # RedisKeyConstants, AIConstants 静态常量
        │   │   ├── exception/             # GlobalExceptionHandler 全局捕获器与自定义业务异常
        │   │   └── enums/                 # 业务状态机枚举（FriendStatusEnum, TopicTypeEnum）
        │   ├── config/                    # 核心第三方框架中间件配置层
        │   │   ├── SecurityConfig.java    # Spring Security 过滤器链与密码加密器配置
        │   │   ├── RedisConfig.java       # RedisTemplate 序列化与过期机制定制
        │   │   ├── MybatisPlusConfig.java # 分页插件与 SQL 性能拦截器
        │   │   ├── WebSocketConfig.java   # Spring WebSocket 握手与端点注册
        │   │   └── OssConfig.java         # 阿里云 OSS 客户端单例注入
        │   ├── security/                  # 认证授权核心安全组件
        │   │   ├── JwtAuthenticationTokenFilter.java # JWT 逐请求解析校验过滤器
        │   │   └── RestAuthenticationEntryPoint.java # 匿名与未授权异常自定义处理器
        │   ├── controller/                # 表现层：严格遵循 RESTful API 设计规范
        │   │   ├── AuthController.java    # 账户注册、登录认证、验证码分发
        │   │   ├── AiController.java      # AI 流式会话控制、Personal RAG 交互端点
        │   │   ├── PostController.java    # 社区动态发布、互动（点赞收藏）处理
        │   │   └── ChatController.java    # 社交好友链路控制、历史消息同步
        │   ├── entity/                    # 数据域对象层
        │   │   ├── po/                    # 与数据库表严格一一对应的持久化对象 (DO)
        │   │   ├── dto/                   # 接收前端 RequestBody 的传输对象 (DTO)
        │   │   └── vo/                    # 返回前端 ResponseBody 的视图展现对象 (VO)
        │   ├── mapper/                    # 数据访问层：MyBatis 接口及复杂手写 SQL 绑定
        │   └── service/                   # 核心核心业务逻辑层
        │       ├── IAuthService.java      
        │       ├── IAiService.java        # 整合 DeepSeek 客户端、执行 RAG 上下文装配
        │       ├── IPostService.java      # 涵盖帖子高并发读写、Redis 缓存双写一致性处理
        │       ├── IChatService.java      # 负责好友申请状态流转与即时消息落库
        │       └── impl/                  # 所有 Service 接口的高内聚实现类目录
        └── resources/
            ├── application.yml            # 全局基础核心配置文件
            ├── application-dev.yml        # 本地开发环境环境配置
            ├── application-prod.yml       # 生产线线上运行环境配置
            └── mapper/                    # MyBatis 高级复杂映射 XML 映射文件目录
```

---

## 🗄️ 4. 数据库设计 (Database Design)

系统采用 MySQL 8.0 关系型数据库，采用高内聚、轻耦合的思想设计了 14 张核心表。

### 4.1 核心 DDL 建表脚本
```sql
CREATE DATABASE IF NOT EXISTS `mind_flow` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `mind_flow`;

-- 1. 用户表
CREATE TABLE `user` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `username` varchar(64) NOT NULL COMMENT '唯一用户名/手机号',
  `password` varchar(128) NOT NULL COMMENT '加密后的密码',
  `nickname` varchar(64) DEFAULT NULL COMMENT '用户昵称',
  `avatar` varchar(255) DEFAULT NULL COMMENT '阿里云OSS头像URL',
  `signature` varchar(255) DEFAULT NULL COMMENT '个性签名',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '账号状态 (0:禁用, 1:正常)',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 2. 帖子表
CREATE TABLE `post` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '帖子ID',
  `user_id` bigint NOT NULL COMMENT '发布者用户ID',
  `content` text NOT NULL COMMENT '帖子正文内容',
  `images` varchar(1024) DEFAULT NULL COMMENT '图片URL列表 (JSON数组存储)',
  `view_count` int NOT NULL DEFAULT '0' COMMENT '浏览量',
  `like_count` int NOT NULL DEFAULT '0' COMMENT '点赞总数',
  `comment_count` int NOT NULL DEFAULT '0' COMMENT '评论总数',
  `collect_count` int NOT NULL DEFAULT '0' COMMENT '收藏总数',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发布时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='帖子表';

-- 3. 评论表
CREATE TABLE `comment` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '评论ID',
  `post_id` bigint NOT NULL COMMENT '所属帖子ID',
  `user_id` bigint NOT NULL COMMENT '评论发表者ID',
  `parent_id` bigint DEFAULT NULL COMMENT '父级评论ID (二级评论用, 根评论为NULL)',
  `content` varchar(1024) NOT NULL COMMENT '评论内容',
  `like_count` int NOT NULL DEFAULT '0' COMMENT '点赞数',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发表时间',
  PRIMARY KEY (`id`),
  KEY `idx_post_id` (`post_id`),
  KEY `idx_parent_id` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='评论表';

-- 4. 点赞记录表
CREATE TABLE `like_record` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` bigint NOT NULL COMMENT '点赞用户ID',
  `target_id` bigint NOT NULL COMMENT '点赞目标ID (帖子ID或评论ID)',
  `target_type` tinyint NOT NULL COMMENT '目标类型 (1:帖子, 2:评论)',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '点赞时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_target` (`user_id`,`target_id`,`target_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='点赞记录表';

-- 5. 收藏记录表
CREATE TABLE `collect` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` bigint NOT NULL COMMENT '收藏用户ID',
  `post_id` bigint NOT NULL COMMENT '收藏帖子ID',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '收藏时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_post` (`user_id`,`post_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='收藏记录表';

-- 6. 关注表
CREATE TABLE `follow` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `follower_id` bigint NOT NULL COMMENT '发出关注的用户ID (粉丝)',
  `following_id` bigint NOT NULL COMMENT '被关注的用户ID (偶像)',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '关注建立时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_follower_following` (`follower_id`,`following_id`),
  KEY `idx_following_id` (`following_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='关注表';

-- 7. 好友申请表
CREATE TABLE `friend_request` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `sender_id` bigint NOT NULL COMMENT '申请发起人ID',
  `receiver_id` bigint NOT NULL COMMENT '申请接收人ID',
  `status` tinyint NOT NULL DEFAULT '0' COMMENT '状态 (0:待处理, 1:已同意, 2:已拒绝, 3:已忽略)',
  `reason` varchar(255) DEFAULT NULL COMMENT '附言/申请理由',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '申请时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '状态更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_receiver_status` (`receiver_id`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='好友申请表';

-- 8. 好友关系表
CREATE TABLE `friend_relation` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `friend_id` bigint NOT NULL COMMENT '好友的用户ID',
  `remark_name` varchar(64) DEFAULT NULL COMMENT '好友备注名称',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '成为好友时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_friend` (`user_id`,`friend_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='好友关系表';

-- 9. 私聊会话表
CREATE TABLE `chat_conversation` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '会话ID',
  `user1_id` bigint NOT NULL COMMENT '参与者用户ID1 (小的ID)',
  `user2_id` bigint NOT NULL COMMENT '参与者用户ID2 (大的ID)',
  `last_message_id` bigint DEFAULT NULL COMMENT '最后一条消息的ID',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '会话活跃更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_users` (`user1_id`,`user2_id`),
  KEY `idx_update_time` (`update_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='私聊会话表';

-- 10. 私聊消息表
CREATE TABLE `chat_message` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '消息ID',
  `conversation_id` bigint NOT NULL COMMENT '所属会话ID',
  `sender_id` bigint NOT NULL COMMENT '发送者ID',
  `content` text NOT NULL COMMENT '文本消息内容',
  `is_read` tinyint NOT NULL DEFAULT '0' COMMENT '是否已读 (0:未读, 1:已读)',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '投递时间',
  PRIMARY KEY (`id`),
  KEY `idx_conversation` (`conversation_id`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='私聊消息表';

-- 11. 通知表
CREATE TABLE `notification` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '通知ID',
  `receiver_id` bigint NOT NULL COMMENT '通知接收方ID',
  `sender_id` bigint NOT NULL COMMENT '触发动作源发起人ID',
  `type` tinyint NOT NULL COMMENT '类型 (1:点赞帖子, 2:评论回复, 3:新关注, 4:系统广播, 5:好友相关)',
  `content` varchar(512) NOT NULL COMMENT '通知文本摘要/附加数据',
  `target_id` bigint DEFAULT NULL COMMENT '跳转目标业务ID (如帖子ID)',
  `is_read` tinyint NOT NULL DEFAULT '0' COMMENT '读取状态 (0:未读, 1:已读)',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '通知时间',
  PRIMARY KEY (`id`),
  KEY `idx_receiver_read` (`receiver_id`,`is_read`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='通知表';

-- 12. AI知识库表 (Personal RAG核心)
CREATE TABLE `knowledge_base` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `user_id` bigint NOT NULL COMMENT '所属用户ID',
  `fact_key` varchar(128) NOT NULL COMMENT '属性类目 (如：学业状态/性格偏好/睡眠问题)',
  `fact_value` text NOT NULL COMMENT '具体的细节事实描述',
  `is_enabled` tinyint NOT NULL DEFAULT '1' COMMENT '当前知识是否激活注入 (0:关闭, 1:启用)',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '提取创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修正时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_enabled` (`user_id`,`is_enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI知识库表';

-- 13. AI会话表
CREATE TABLE `ai_session` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '会话ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `title` varchar(128) NOT NULL DEFAULT '新对话' COMMENT '会话标题',
  `topic_type` tinyint NOT NULL DEFAULT '1' COMMENT '场景类型 (1:心理咨询, 2:学习辅导, 3:综合聊天)',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '开启时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后聊天时间',
  `is_deleted` tinyint NOT NULL DEFAULT '0' COMMENT '逻辑软删除 (0:留存, 1:已删)',
  PRIMARY KEY (`id`),
  KEY `idx_user_deleted` (`user_id`,`is_deleted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI会话表';

-- 14. AI消息表
CREATE TABLE `ai_message` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '消息ID',
  `session_id` bigint NOT NULL COMMENT '关联AI会话ID',
  `role` varchar(16) NOT NULL COMMENT '角色类型 (user / assistant / system)',
  `content` text NOT NULL COMMENT '单条对话正文',
  `tokens` int NOT NULL DEFAULT '0' COMMENT '消耗的Token概数',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '投递时间',
  PRIMARY KEY (`id`),
  KEY `idx_session_id` (`session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI消息表';
```

---

## 🧠 5. AI 系统设计与 Personal RAG 实现

### 5.1 Personal RAG 上下文自动化注入原理
为克服大模型单次会话遗忘痛点，本项目设计了基于 RAG (Retrieval-Augmented Generation) 思路的个性化提示词框架：

```text
+-----------------------+      1. 动态拦截查询
|  User 发送请求消息    | ------------------------>  [knowledge_base 表]
+-----------------------+                              | 筛选 is_enabled=1
            |                                          |
            | 2. 取出用户偏好事实并格式化              v
            v                                  [获取到的事实切片数据]
+------------------------------------------------------+
| 3. System Prompt 编译器进行全量组装                  |
|                                                      |
|   "你是一个专业的心理健康顾问，请结合以下用户背景："  |
|   "- 偏好1: 计算机专业大三学生，近期在准备面试"       |
|   "- 偏好2: 伴随严重的间歇性焦虑与失眠"              |
+------------------------------------------------------+
            |
            | 4. 将系统 Prompt 与多轮 History 压入 Context 数组
            v
+-----------------------+      5. SSE 传输
|     DeepSeek API      | ────────────────────────>  前端极速渲染呈现
+-----------------------+
```

### 5.2 动态 Prompt 引擎组装核心 Java 实现
在 `AiServiceImpl.java` 中，通过在向下游大模型发送请求前动态读取知识库，拼接最完美的系统指令：

```java
@Service
public class AiServiceImpl implements IAiService {

    @Autowired
    private KnowledgeBaseMapper knowledgeBaseMapper;
    @Autowired
    private AiMessageMapper aiMessageMapper;

    public String buildSystemPrompt(Long userId, Long sessionId) {
        StringBuilder sb = new StringBuilder();
        sb.append("你是一个具备深厚心理学背景的 AI 心理健康顾问，你的名字叫‘心晴’。\n");
        sb.append("请使用共情、温和、非批判性的语气。多倾听，多引导用户表达内心真实感受，给予实际的心理疏导策略。\n");
        
        // 动态读取开启中的 Personal RAG 长期记忆知识库
        List<KnowledgeBase> facts = knowledgeBaseMapper.selectList(
            new LambdaQueryWrapper<KnowledgeBase>()
                .eq(KnowledgeBase::getUserId, userId)
                .eq(KnowledgeBase::getIsEnabled, 1)
        );
        
        if (!facts.isEmpty()) {
            sb.append("\n【非常重要：以下是你已知关于该用户的长期记忆与个人背景，请在回答中无感知地结合这些背景，不要暴露这是系统输入】：\n");
            for (KnowledgeBase fact : facts) {
                sb.append(String.format("- [%s]: %s\n", fact.getFactKey(), fact.getFactValue()));
            }
        }
        
        // 根据会话主题追加特定垂类规约
        AiSession session = aiSessionMapper.selectById(sessionId);
        if (session != null && session.getTopicType() == 2) { // 学习辅导场景
            sb.append("\n当前处于[学习学业辅导场景]。请在保持心理关怀的前提下，重点提供结构化的学习方法论、时间管理策略及压力拆解方案。\n");
        }
        
        return sb.toString();
    }
}
```

---

## ⚡ 6. 核心高并发网络通信设计 (SSE & WebSocket)

### 6.1 Server-Sent Events (SSE) 服务端与客户端全链路
为了保证大模型的 Token 输出像打字机一样平滑，不使用开销巨大的常规 HTTP 或者复杂的 Web-Socket，直接采用原生轻量的一维单向流 **SSE**。

#### 后端 Spring Boot 实现：`AiController.java`
```java
@RestController
@RequestMapping("/api/ai")
public class AiController {

    @Autowired
    private IAiService aiService;

    @PostMapping(value = "/chat/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter streamChat(@RequestBody AiChatRequestDTO request, @AuthenticationPrincipal UserDetails userDetails) {
        // 创建 10 分钟超长的 Emitter 实例，避免大模型长推理生成中断
        SseEmitter emitter = new SseEmitter(600_000L);
        Long userId = ((CustomUserPrincipal) userDetails).getId();

        // 异步线程处理，防止 Tomcat 核心工作线程池发生伪死锁阻塞
        CompletableFuture.runAsync(() -> {
            try {
                aiService.callDeepSeekStream(request, userId, new StreamResponseHandler() {
                    @Override
                    public void onChunk(String text) {
                        try {
                            // 严格按照 SSE 规范格式： data: {} 

 投递
                            emitter.send(SseEmitter.event().data(Map.of("content", text)));
                        } catch (Exception e) {
                            // 捕获客户端提前断开、关闭页面产生的异常
                        }
                    }

                    @Override
                    public void onComplete() {
                        try {
                            emitter.send(SseEmitter.event().name("complete").data("SUCCESS"));
                            emitter.complete();
                        } catch (Exception ignored) {}
                    }
                });
            } catch (Exception e) {
                emitter.completeWithError(e);
            }
        });
        return emitter;
    }
}
```

#### 前端 React 核心消费 Hook：`useSSE.ts`
```typescript
import { useState } from 'react';

export const useSSE = () => {
  const [isGenerating, setIsGenerating] = useState(false);

  const fetchAiStream = async (
    prompt: string, 
    sessionId: number, 
    onChunk: (text: string) => void
  ) => {
    setIsGenerating(true);
    const token = localStorage.getItem('token');
    
    try {
      const response = await fetch('/api/ai/chat/stream', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ prompt, sessionId, enableKnowledge: true })
      });

      if (!response.body) return;
      const reader = response.body.getReader();
      const decoder = new TextDecoder('utf-8');
      let buffer = '';

      while (true) {
        const { value, done } = await reader.read();
        if (done) break;
        
        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        
        // 留出最后一行不完整的 buffer
        buffer = lines.pop() || '';

        for (const line of lines) {
          const cleanedLine = line.trim();
          if (!cleanedLine) continue;
          
          if (cleanedLine.startsWith('data:')) {
            const rawJson = cleanedLine.replace('data:', '').trim();
            try {
              const parsed = JSON.parse(rawJson);
              if (parsed.content) {
                onChunk(parsed.content); // 触发打字机追加
              }
            } catch (e) {
              // 容错忽略 complete 标识或脏数据
            }
          }
        }
      }
    } catch (error) {
      console.error("SSE stream reading failed:", error);
    } finally {
      setIsGenerating(false);
    }
  };

  return { fetchAiStream, isGenerating };
};
```

### 6.2 WebSocket 双向通讯与实时通知推送
项目私聊、在线状态同步以及全局通知强依托于原生 WebSocket 通信。

#### 后端高可靠 WebSocket 控制器配置
```java
@Component
public class MindFlowWebSocketHandler extends TextWebSocketHandler {

    // 线程安全的高并发内存 Session 注册表
    private static final ConcurrentHashMap<Long, WebSocketSession> sessionPool = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        Long userId = getUserIdFromSession(session);
        if (userId != null) {
            sessionPool.put(userId, session);
        }
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        // 解析即时私聊 P2P 消息 payload
        ChatMessageDTO dto = JSONUtil.toBean(message.getPayload(), ChatMessageDTO.class);
        WebSocketSession targetSession = sessionPool.get(dto.getReceiverId());
        
        // 核心路由投递逻辑
        if (targetSession != null && targetSession.isOpen()) {
            // 目标在线：秒级投递
            targetSession.sendMessage(new TextMessage(JSONUtil.toJsonStr(dto)));
            // 更新落库且置为已读
            saveMessageToDb(dto, true);
        } else {
            // 目标离线：存入库中置为未读，触发 Redis 离线计数器
            saveMessageToDb(dto, false);
            incrementUnreadCounter(dto.getReceiverId());
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        Long userId = getUserIdFromSession(session);
        if (userId != null) {
            sessionPool.remove(userId);
        }
    }
}
```

---

## 🔌 7. RESTful API 接口规范拓扑 (API Docs Snapshot)

### 7.1 用户注册与 JWT 认证
* **接口地址**：`POST /api/auth/login`
* **请求载荷 (JSON)**：
  ```json
  {
    "username": "13800138000",
    "password": "RawPassword123",
    "loginType": "password" 
  }
  ```
* **正确返回结果**：
  ```json
  {
    "code": 200,
    "message": "登录认证成功",
    "data": {
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSw...[truncated]",
      "expireTime": 1785934000,
      "userSummary": {
        "id": 1,
        "nickname": "新速测试用户",
        "avatar": "https://xsnbb-oss.oss-cn-beijing.aliyuncs.com/avatar/default.png"
      }
    }
  }
  ```

### 7.2 社区动态发布
* **接口地址**：`POST /api/post/create`
* **认证级别**：需要携带 `Authorization: Bearer <JWT>`
* **请求载荷 (JSON)**：
  ```json
  {
    "content": "今天又是充满面试压力的一天，还好有心晴AI听我倾诉，感觉好多了！",
    "images": [
      "https://xsnbb-oss.oss-cn-beijing.aliyuncs.com/posts/img1.jpg"
    ]
  }
  ```
* **正确返回结果**：
  ```json
  {
    "code": 200,
    "message": "动态发布成功",
    "data": {
      "postId": 50123
    }
  }
  ```

---

## 🚀 8. 多环境全场景部署指南 (Deployment Guide)

### 8.1 方式一：Docker Compose 现代化容器编排一键启动
在生产机器任意目录新建 `docker-compose.yml` 文件：

```yaml
version: '3.8'

services:
  mind-flow-mysql:
    image: mysql:8.0
    container_name: mind-flow-mysql
    restart: always
    environment:
      MYSQL_DATABASE: mind_flow
      MYSQL_ROOT_PASSWORD: YourSecureRootPassword123
    ports:
      - "3306:3306"
    volumes:
      - ./mysql/data:/var/lib/mysql
      - ./mysql/init.sql:/docker-entrypoint-initdb.d/init.sql

  mind-flow-redis:
    image: redis:7.2-alpine
    container_name: mind-flow-redis
    restart: always
    command: redis-server --requirepass YourRedisPassword123
    ports:
      - "6379:6379"
    volumes:
      - ./redis/data:/data

  mind-flow-backend:
    image: openjdk:17-jdk-alpine
    container_name: mind-flow-backend
    restart: always
    volumes:
      - ./backend/mind-flow.jar:/app/app.jar
      - ./backend/logs:/app/logs
    command: ["java", "-jar", "/app/app.jar", "--spring.profiles.active=prod"]
    ports:
      - "8080:8080"
    depends_on:
      - mind-flow-mysql
      - mind-flow-redis
```

### 8.2 方式二：宝塔 Linux 面板标准常规部署
1. **基础设施准备**：在宝塔面板软件商店安装 `MySQL 8.0`、`Redis 7.x` 以及 `Nginx`。
2. **数据库导入**：创建名为 `mind_flow` 的数据库，将本文件的 `4.1` SQL 建表脚本复制并执行。
3. **后端发布**：
   * 本地 IDEA 开发环境运行 `mvn clean package`，在 `target` 目录生成 `mind-flow-backend.jar`。
   * 通过宝塔文件管理器上传 jar 包至独立运行目录 `/www/wwwroot/mind-flow-backend/`。
   * 进入宝塔【Java项目管理器】->【添加通用Java项目】，端口填写 `8080`，启动用户选择 `root`，开启守护进程。
4. **前端发布**：
   * 本地前端项目下，执行 `npm run build`，将编译后生成的 `dist` 静态资源目录压缩。
   * 在宝塔【网站】新建站点，域名绑定 `xsnbb.xyz`，将 `dist` 内部全量文件解压至该站点根目录中。

### 8.3 极其关键：Nginx 核心全量配置文件
为了彻底解决 **SSE 缓存白屏分段输出** 及 **WebSocket 连接秒级意外断开** 故障，必须在 Nginx 站点配置文件中覆盖应用以下高级配置：

```nginx
server {
    listen 80;
    listen 443 ssl http2;
    server_name xsnbb.xyz;

    ssl_certificate /www/server/panel/vhost/cert/xsnbb.xyz/fullchain.pem;
    ssl_certificate_key /www/server/panel/vhost/cert/xsnbb.xyz/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # 1. 前端 React SPA 静态目录托管
    location / {
        root /www/wwwroot/xsnbb.xyz;
        index index.html;
        try_files $uri $uri/ /index.html; # 支持 React Router 浏览器 History 模式刷新不 404
    }

    # 2. 后端核心 RESTful API 代理（含极致优化后的 SSE 流式网关配置）
    location /api/ {
        proxy_pass http://127.0.0.1:8080/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # 【必加】完美释放 SSE 实时推流限制的关键指令
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_buffering off;               # 必须关闭代理缓冲区，否则 Nginx 会积攒大模型 Token 全量才返回
        proxy_cache off;                   # 禁用缓存
        chunked_transfer_encoding on;      # 开启分块传输
        proxy_read_timeout 600s;           # 防止大模型 R1 深度思考时间过长引发 Nginx 主动断开
    }

    # 3. 高并发双向 WebSocket 端点代理
    location /ws/ {
        proxy_pass http://127.0.0.1:8080/ws/;
        
        # 【必加】支持 HTTP 协议无损升级至 WebSocket 双向长连接
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 3600s;          # 超长心跳保活周期，避免无活动时连接被强杀
    }
}
```

---

## 👨‍💻 9. 开发协作规范 (Development & Git Workflow)

为了保障项目多人协作下的代码整洁度与历史提交可追溯性，必须强制遵循以下规范：

### 9.1 Git Commit 规范 (Conventional Commits)
每次执行 `git commit -m` 的日志信息必须严格采用以下语义化前缀：
* `feat:` 新增任何全新的业务功能（例如：`feat: 增加 Personal RAG 启用开关`）。
* `fix:` 修复开发中或生产线上的 Bug（例如：`fix: 解决 Nginx 缓冲导致 SSE 断流问题`）。
* `docs:` 纯粹的文档更新、README 修正。
* `style:` 不影响业务逻辑的代码格式化、ESLint 格式自动对齐、无用空格清除。
* `refactor:` 代码重构（既不修复缺陷也不增加新功能的架构级代码更改）。

### 9.2 分支流转管理
* `main`: 生产环境绝对稳定分支，只接受从 `release` 或 `hotfix` 分支发起的 Pull Request，严禁在此分支进行直接 Commits。
* `dev`: 日常协同公共集成测试分支，所有新功能分支开发完毕后优先合并至此进行联合调试。
* `feature/*`: 个人独立特性分支，从最新 `dev` 检出，开发自测完毕后提测合入 `dev`。

---

## 🗺️ 10. 项目里程碑路线图 (Roadmap)

* [x] **第一阶段：基建建立与流式破局 (Phase 1)**
  * 完成基于 React 18 与 Spring Boot 3 的基本单页应用拓扑搭建。
  * 彻底调通 DeepSeek API，成功攻克前端流式 ReadableStream 解析与后端 SseEmitter 异步无阻塞推流技术。
* [x] **第二阶段：记忆唤醒与社区生态融合 (Phase 2)**
  * 实现完整的 14 张核心关系型数据库表关联与 MyBatis Plus 业务开发。
  * 成功上线 **Personal RAG 用户知识库管理**，大模型具备了根据用户的开启状态自动组合并消化长期背景数据的能力。
  * 完美落成社区广场所涉及的图文上传、交互三件套。
* [ ] **第三阶段：实时社交全覆盖与多端泛化 (Phase 3)**
  * 强化自研 WebSocket 即时通信网关，增加 ACK 消息可靠送达验证与高并发下离线红点通知推送。
  * 对前端进行全面渐进式网络应用 (PWA) 改造，并积极探索使用 **HarmonyOS 鸿蒙 ArkTS (Stage模型)** 重构移动端专属心理互助 App。
* [ ] **第四阶段：多模态感知与情感计算 (Phase 4)**
  * 计划引入音频信号帧处理，支持用户在咨询中直接进行连续语音输入。
  * 引入语音情绪情感分类模型，让大模型不仅能读懂文字，更能实时辨识用户声音中的焦虑、抑郁等微小情绪波动。

---

<div align="center">
  <p>如果你觉得 <strong>心晴 (Mind Flow)</strong> 为你的全栈大模型应用开发带来了启发，请在 GitHub 为本项目点亮一颗 ⭐️！</p>
  <p>版权所有 © 2026 新速开源研发团队。遵循 MIT 开源许可协议。</p>
</div>
