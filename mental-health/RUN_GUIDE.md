# 从零到跑通 · 操作清单

按下面的顺序做，每一步做完再做下一步，保证一遍通过。

---

## 一、本地环境（10 分钟）

| 工具 | 版本 | 用途 |
|---|---|---|
| JDK | 17 | 编译/运行后端 |
| Maven | 3.8+ | 后端打包（用 IDEA 内置也行） |
| MySQL | 8.0 | 数据库 |
| Redis | 7.x | 缓存 |
| IntelliJ IDEA | 2023.3+ | 后端开发 |
| DevEco Studio | **5.0.5 Release 或更新** | 鸿蒙端 |
| Node.js | 18+ | DevEco 用 |

> Windows 用户：把上述工具用官方安装包装一遍即可。
> Mac 用户：`brew install openjdk@17 mysql redis maven`。

---

## 二、跑后端（约 15 分钟）

### 1. 建库
```bash
mysql -uroot -p
```
```sql
CREATE DATABASE mental_health DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'mental'@'%' IDENTIFIED BY 'ChangeMe_2026!';
GRANT ALL ON mental_health.* TO 'mental'@'%';
FLUSH PRIVILEGES;
```
然后在 IDEA 里打开 `backend/sql/schema.sql`，连到 MySQL 跑一遍，10 张表全部建好。

### 2. 启动 Redis
```bash
redis-server &
redis-cli ping   # 看到 PONG 即可
```

### 3. 申请 DeepSeek Key
访问 https://platform.deepseek.com → 注册 → API Keys → 创建 → 复制 `sk-xxxxx`。
新用户有几块钱免费额度，调试够用。

### 4. 改配置
打开 `backend/src/main/resources/application.yml`：
- `spring.datasource.password` 改成你的 MySQL 密码
- `ai.deepseek.api-key` 填入刚才复制的 key
- `upload.path` 本地调试可改成你的本机目录，如 `D:/upload` 或 `/tmp/upload`

### 5. 启动
用 IDEA 打开 `backend/` 目录 → 等待 Maven 拉依赖 → 右键 `MentalHealthApplication` → Run。

看到 `Started MentalHealthApplication in xxx seconds` 就成功了，默认 8080 端口。

### 5.1 阿里云 OSS 上传配置
当前后端默认使用 OSS 上传，密钥不要写进 `application-prod.yml`，在宝塔 Java 项目的环境变量里配置：

```bash
UPLOAD_STORAGE=oss
ALIYUN_OSS_ENDPOINT=https://oss-cn-beijing-internal.aliyuncs.com
ALIYUN_OSS_PUBLIC_ENDPOINT=https://mental-healthy.oss-cn-beijing.aliyuncs.com
ALIYUN_OSS_BUCKET=mental-healthy
ALIYUN_OSS_ACCESS_KEY_ID=你的RAM用户AccessKeyId
ALIYUN_OSS_ACCESS_KEY_SECRET=你的RAM用户AccessKeySecret
ALIYUN_OSS_PREFIX=mental-health/
```

服务器在阿里云华北2北京时，上传使用内网 Endpoint；接口返回给 App 的地址使用公网默认域名。

如果临时想切回本地目录上传，把 `UPLOAD_STORAGE` 改成 `local`。

### 6. 自测
```bash
# 注册
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"alice","password":"123456","phone":"13800138001"}'

# 应该返回 {"code":0,"msg":"ok","data":{"token":"eyJxxx...","user":{...}}}

# 用上面返回的 token 调取个人资料
curl http://localhost:8080/api/user/profile \
  -H "Authorization: Bearer eyJxxx..."
```

---

## 三、把接口文档导入 Apifox（5 分钟）

1. 打开 Apifox 客户端 → 新建项目
2. 项目设置 → 数据管理 → **导入数据** → OpenAPI/Swagger
3. 选 `docs/openapi.yaml` → 全选 → 确认
4. 在 Apifox 里把"环境"切到本地：`http://localhost:8080/api`
5. 跑一遍 Auth 分组里的注册和登录，应该能调通

> 这一步是给你自己用的：以后接口改了，你也能用 Apifox 直接联调和 Mock。

---

## 四、跑鸿蒙端（约 20 分钟）

### 1. 装 DevEco Studio
https://developer.huawei.com/consumer/cn/deveco-studio/

第一次启动会让你装 SDK，选 **HarmonyOS 5.0 / API 12** 及以上。

### 2. 打开项目
DevEco Studio → File → Open → 选 `harmony/` 目录（**不是 harmony 下的 entry**）。

第一次会自动拉 hvigor + oh_modules，耐心等 5-10 分钟。

### 3. 改后端地址
打开 `entry/src/main/ets/constants/Const.ets`：

**本地调试用真机/平板**（手机和电脑在同一个 WiFi）：
```typescript
static readonly BASE_URL: string = 'http://你电脑的局域网IP:8080/api';
static readonly WS_URL: string   = 'ws://你电脑的局域网IP:8080/api/ws/im';
```

**本地调试用模拟器**（DevEco 自带的）：
```typescript
static readonly BASE_URL: string = 'http://10.0.2.2:8080/api';
static readonly WS_URL: string   = 'ws://10.0.2.2:8080/api/ws/im';
```

**部署到服务器后**：
```typescript
static readonly BASE_URL: string = 'http://39.96.36.94/api';
static readonly WS_URL: string   = 'ws://39.96.36.94/api/ws/im';
```

### 4. 准备图标资源
DevEco 默认 `entry/src/main/resources/base/media/` 里要有 `icon.png`（图标）。
**底部 Tab 我用了这些资源 ID**，你需要把对应 PNG 放进去：

```
entry/src/main/resources/base/media/
├── icon.png             # App 图标（DevEco 自带）
├── tab_community.png    # 24x24 灰色图标
├── tab_ai.png
├── tab_message.png
└── tab_mine.png
```

懒得做的话，把 `pages/Index.ets` 里 4 个 `$r('app.media.tab_xxx')` 临时替换成系统图标：
- `$r('sys.media.ohos_ic_public_albums')`  → 社区
- `$r('sys.media.ohos_ic_public_robot')`   → AI
- `$r('sys.media.ohos_ic_public_message')` → 消息
- `$r('sys.media.ohos_ic_public_contacts')`→ 我的

### 5. 真机调试
- 鸿蒙手机/平板 → 设置 → 关于本机 → 连点 7 次"版本号" → 开发者模式
- USB 连电脑 → DevEco 右上角设备列表选你的设备 → ▶ Run
- 第一次会提示登录华为账号申请调试签名，按引导走完

**没鸿蒙设备**？用 DevEco 自带的 Emulator：Tools → Device Manager → 创建一个 Phone API 12 模拟器。

### 6. 验证全流程
1. 启动后看到登录页 → 点"立即注册" → 填用户名/手机号/密码 → 注册
2. 跳到主页 → 默认社区 Tab，可能是空的 → 右上角 + 号发一条带图片的帖子
3. 看后端 `upload.path` 配置的目录，应该有图片
4. 切到 AI Tab → 点"心理咨询" → 创建会话 → 发"我最近很焦虑" → 流式回答
5. 切到我的 → 资料编辑 → 改昵称、传头像 → 保存
6. 用另一台设备/账号给你的帖子点赞 → 切到消息 Tab → 看到通知

---

## 五、上线到服务器 39.96.36.94

按 `deploy/DEPLOY.md` 一步步做：

1. 宝塔装 Nginx / MySQL 8 / Redis 7 / JDK 17
2. 宝塔建数据库 `mental_health`，导入 `schema.sql`
3. 本地 `mvn clean package -DskipTests` 得到 `mental-health.jar`
4. 用宝塔文件管理上传到 `/www/wwwroot/mental-health/`
5. 上传 `application-prod.yml`（替换数据库密码和 DeepSeek key）
6. 用 systemd 启动 jar（或宝塔 Java 项目管理器）
7. 宝塔加站点绑定 IP → 配置文件用 `deploy/nginx.conf` 替换
8. 阿里云安全组放行 80/443
9. 鸿蒙端改 `Const.ets` → 上线地址 → 重新打包
10. （可选）申请域名 + SSL → 切 https/wss

---

## 六、常用调试技巧

### 后端日志
```bash
# 本地：看 IDEA 控制台
# 服务器：
tail -f /www/wwwlogs/mental-health.out.log
tail -f /www/wwwlogs/mental-health.err.log
```

### 鸿蒙端日志
DevEco 下方 Log 窗口 → 过滤关键字 `console` 或 `http`，可以看到所有 `console.error/log` 输出。

### 想看接口请求
```bash
# 服务器抓包
tcpdump -i any -A -s0 'port 8080'
```

### 接口出 401
- 看请求头有没有带 `Authorization: Bearer xxx`
- 看 token 是否过期（默认 1 天），过期了重新登录
- `application.yml` 里的 `jwt.secret` 改了之后老 token 都失效，需要重新登录

### SSE 没流式效果，一下子全出来
- 用 Nginx 必须配 `proxy_buffering off;`
- 直连 `localhost:8080` 没有这个问题
- 客户端关 gzip 自动解压（默认就关的）

### WebSocket 连不上
- token 是否带在 URL `?token=xxx`
- 用 Nginx 反代必须有：
  ```
  proxy_http_version 1.1;
  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header Connection "upgrade";
  ```
- 防火墙端口

---

## 七、改造方向（按需）

| 想做 | 怎么做 |
|---|---|
| 换 AI 模型为 Kimi | 改 `ai.deepseek.base-url` 为 `https://api.moonshot.cn/v1`，`model` 改 `moonshot-v1-8k`，同协议直接通 |
| 加华为推送（离线消息） | 集成 Push Kit，在 `notify()` 里加推送调用 |
| 视频做封面 | 后端用 ffmpeg 抽第一帧存为 `_thumb.jpg` |
| 图片做压缩 | 后端 `UploadService.image()` 里加 Thumbnailator |
| 加点赞列表/收藏列表 | controller 加两个查 `like_record` / `collect` 的接口，前端"我的"加 Tab |
| 加搜索 | 帖子表加全文索引，新增 `/post/search?q=xxx` |
| 加注册时邮箱 | User 表加 email 列，AuthDto 加 email 字段，注册逻辑加校验 |
| 加好友关系 | 已经有 `follow` 表了，加 controller 把它暴露出来 |

---

到这一步你已经有了：
- **可联调的本地后端**
- **可下载的 OpenAPI 文档**
- **可运行的鸿蒙端**
- **可上线的部署方案**

剩下的就是按业务需要继续往上加东西了。
