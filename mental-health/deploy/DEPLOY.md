# 宝塔部署指南（39.96.36.94）

> 目标：把 Spring Boot 后端 + MySQL + Redis + Nginx 跑在你的阿里云 39.96.36.94 上，
> 然后用鸿蒙端连上来。

---

## 0. 准备工作

- 阿里云服务器 39.96.36.94，CentOS 7 / Ubuntu 22 都行，建议 ≥ 2C4G
- 阿里云控制台 → 安全组放行端口：22 / 80 / 443 / 8080（开发期）
- 已安装宝塔面板：https://www.bt.cn/new/download.html

---

## 1. 宝塔里一键装环境

宝塔面板 → 软件商店，依次安装：

| 软件 | 版本 | 备注 |
| --- | --- | --- |
| **Nginx** | 1.24 | 反向代理 |
| **MySQL** | 8.0 | 数据库 |
| **Redis** | 7.x | 缓存 |
| **JDK** | 17 | 运行 Spring Boot |

JDK 没有的话，命令行装：
```bash
yum install -y java-17-openjdk java-17-openjdk-devel   # CentOS
# 或
apt install -y openjdk-17-jdk                          # Ubuntu
java -version
```

---

## 2. 数据库初始化

宝塔 → 数据库 → 添加数据库
- 数据库名：`mental_health`
- 用户名：`mental`
- 密码：自己设一个，记下来（替换到下面 application-prod.yml）

然后导入表结构：
- 宝塔 → 数据库 → 找到 `mental_health` → 导入
- 上传 `backend/sql/schema.sql`，执行

或者命令行：
```bash
mysql -umental -p mental_health < schema.sql
```

---

## 3. 打包后端

本地用 IDEA 或命令行打包：
```bash
cd backend
mvn clean package -DskipTests
# 产物：target/mental-health.jar
```

新建一个 `application-prod.yml`，覆盖生产配置：

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/mental_health?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai&useSSL=false
    username: mental
    password: 你设置的MySQL密码
  data:
    redis:
      host: localhost
      port: 6379
      password: ''

upload:
  path: /www/wwwroot/static
  url-prefix: http://39.96.36.94/static

ai:
  deepseek:
    api-key: sk-填入你的DeepSeek-key   # 去 https://platform.deepseek.com 申请
    base-url: https://api.deepseek.com
    model: deepseek-chat
```

---

## 4. 上传部署文件

宝塔 → 文件 → `/www/wwwroot/` 下新建目录 `mental-health/`，上传：

```
/www/wwwroot/mental-health/
├── mental-health.jar              # 后端 jar
└── application-prod.yml           # 生产配置
```

再建一个静态文件目录：
```bash
mkdir -p /www/wwwroot/static/{img,video}
chown -R www:www /www/wwwroot/static
chmod -R 755 /www/wwwroot/static
```

---

## 5. 注册成系统服务（推荐 systemd，重启自动启）

```bash
# 上传 deploy/mental-health.service 到服务器
cp mental-health.service /etc/systemd/system/

# 让 jar 跑起来
systemctl daemon-reload
systemctl enable mental-health
systemctl start mental-health
systemctl status mental-health

# 看日志
tail -f /www/wwwlogs/mental-health.out.log
tail -f /www/wwwlogs/mental-health.err.log
```

> 不想用 systemd？也可以宝塔 → 软件商店 → "Java项目管理器"，
> 选 SpringBoot 项目，把 jar 上传 → 一键启动，更傻瓜化。

---

## 6. 配置 Nginx 反代

宝塔 → 网站 → 添加站点（无需域名也行，绑定 IP 即可）
- 域名：39.96.36.94
- 不勾 PHP / 数据库

进入站点 → 配置文件，把整段 server { ... } 替换成 `deploy/nginx.conf` 的内容，保存。

```bash
nginx -t          # 检查语法
nginx -s reload   # 重载
```

测试：浏览器访问 `http://39.96.36.94`，看到 `mental-health server ok` 就 OK 了。
再测接口：`http://39.96.36.94/api/auth/login` （POST 一下应该返回参数缺失）。

---

## 7. 鸿蒙端连上来

打开 `harmony/entry/src/main/ets/constants/Const.ets`，确认地址：

```typescript
static readonly BASE_URL: string = 'http://39.96.36.94/api';
static readonly WS_URL: string   = 'ws://39.96.36.94/api/ws/im';
```

> 注意：上线后用域名 + HTTPS（`https://` / `wss://`），把 Nginx 申请免费 Let's Encrypt 证书。
> 调试期允许 http 明文，已在 `network_config.json` 里加 `cleartext-traffic-permitted: true`。

---

## 8. 验证全链路

1. 鸿蒙端启动 → 注册 → 登录 → 看到首页（社区 Tab）
2. 发一条带图片的帖子 → 看 `/www/wwwroot/static/img/yyyy-MM-dd/` 是否有文件
3. AI Tab → 选"心理咨询" → 输入消息，文字应该一段一段流出来（SSE 工作正常）
4. 用第二个账号给第一个账号的帖子点赞 / 评论 → 第一个账号"消息"Tab 看到红点
5. 两个账号互发私信 → WebSocket 立即推送（不用刷新）

---

## 9. 上 HTTPS（强烈建议正式上线时做）

宝塔 → 站点 → SSL → Let's Encrypt → 申请并部署，开启"强制 HTTPS"。
之后把 `Const.ets` 改成：
```typescript
static readonly BASE_URL: string = 'https://yourdomain.com/api';
static readonly WS_URL: string   = 'wss://yourdomain.com/api/ws/im';
```

---

## 10. 常见问题

**Q: 端口 8080 直接被访问到了**
A: 阿里云安全组把 8080 关掉，只放 80/443，让所有流量走 Nginx。

**Q: AI 流式没反应，等一会一次性返回**
A: Nginx 漏了 `proxy_buffering off;` —— 检查 `/api/ai/chat` 那段是不是按 `deploy/nginx.conf` 配的。

**Q: 上传大视频失败**
A: 三处都改大：`client_max_body_size`（Nginx）/ `spring.servlet.multipart.max-file-size`（Spring）/ `upload.path` 磁盘空间。

**Q: WebSocket 连不上**
A: 检查 Nginx 配置里 `Upgrade` 和 `Connection "upgrade"`；安全组放行；token 是不是过期。

**Q: 真机/模拟器无法访问 HTTP 明文接口**
A: 检查 `network_config.json` 是否在 `resources/base/profile/`，并在 `module.json5` 的 `metadata` 中引用（如未自动生效，DevEco Studio → 项目设置 → 网络配置选上）。
