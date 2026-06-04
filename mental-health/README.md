# AI 心理健康助手 · 鸿蒙端 + 后端

> 基于 HarmonyOS Next（API 12+）的 AI 心理健康助手 App，配套 Spring Boot 后端、
> OpenAPI 3.0 接口文档和宝塔部署方案。

## 目录结构

```
mental-health/
├── docs/
│   └── openapi.yaml             # ★ 可直接导入 Apifox 的接口文档
├── backend/                     # ★ Spring Boot 3.2 + MyBatis-Plus + JWT + DeepSeek
│   ├── pom.xml
│   ├── sql/schema.sql           # 数据库表结构（10 张表）
│   └── src/main/
│       ├── java/com/mental/health/
│       │   ├── MentalHealthApplication.java
│       │   ├── ai/              # DeepSeek 客户端 + 三业务 Prompt
│       │   ├── common/          # 统一 R / 异常
│       │   ├── config/          # Security / WebSocket / MyBatis-Plus
│       │   ├── controller/      # 7 个 REST 控制器
│       │   ├── dto/
│       │   ├── entity/          # 10 个实体
│       │   ├── mapper/          # 10 个 Mapper
│       │   ├── security/        # JWT + Filter + UserContext
│       │   ├── service/         # 6 个 Service
│       │   └── websocket/       # 私信实时推送
│       └── resources/application.yml
├── harmony/                     # ★ HarmonyOS Next 鸿蒙端
│   ├── AppScope/app.json5
│   ├── build-profile.json5
│   ├── oh-package.json5
│   └── entry/
│       ├── build-profile.json5
│       ├── oh-package.json5
│       └── src/main/
│           ├── module.json5
│           ├── ets/
│           │   ├── entryability/EntryAbility.ets
│           │   ├── pages/Index.ets               # 底部 4 Tab 容器
│           │   ├── view/
│           │   │   ├── auth/                     # 登录 / 注册
│           │   │   ├── community/                # 社区 / 详情 / 发帖
│           │   │   ├── ai/                       # AI 主页 / 对话 / 历史
│           │   │   ├── message/                  # 消息 / 一对一聊天
│           │   │   ├── mine/                     # 我的 / 编辑 / 设置 / 发布 / 评论
│           │   │   └── common/PostCard.ets
│           │   ├── api/                          # HttpClient / SSE / WebSocket / 业务 API
│           │   ├── store/Auth.ets
│           │   ├── model/Models.ets
│           │   ├── utils/                        # 上传 / 时间
│           │   └── constants/Const.ets           # ★ 改这里改后端地址
│           └── resources/...
└── deploy/                      # ★ 宝塔部署
    ├── DEPLOY.md                # 从 0 到上线的完整教程
    ├── nginx.conf
    └── mental-health.service
```

## 快速开始

### 后端
1. 装 JDK 17、MySQL 8、Redis
2. 建库 `mental_health`，跑 `backend/sql/schema.sql`
3. 改 `application.yml` 数据库密码 + DeepSeek key
4. `mvn spring-boot:run` 或 `mvn package` + `java -jar`

### 鸿蒙端
1. 用 DevEco Studio 5.0+ 打开 `harmony/`
2. 改 `entry/src/main/ets/constants/Const.ets` 里的 `BASE_URL`
3. 真机或模拟器运行

### 上线部署
参考 `deploy/DEPLOY.md`，**手把手 10 步**搞定宝塔部署。

## 技术栈

| 端 | 技术 |
|---|---|
| 鸿蒙端 | HarmonyOS Next API 12+ · ArkTS · @ohos.net.http · WebSocket · SSE |
| 后端 | Spring Boot 3.2 · MyBatis-Plus · Spring Security · JWT · WebFlux(SSE) · WebSocket |
| 存储 | MySQL 8 · Redis 7 · 本地文件 |
| AI | DeepSeek Chat（流式） |
| 部署 | 宝塔面板 · Nginx · systemd |

## 接口文档导入 Apifox 的方法
1. Apifox → 项目 → 设置 → 数据管理 → 导入数据 → OpenAPI/Swagger
2. 选择 `docs/openapi.yaml` → 导入
3. 全部接口自动生成，可联调可 mock
