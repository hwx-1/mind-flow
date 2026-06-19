# 心晴 · Web · 阶段 1

React + Vite + TypeScript + Tailwind 实现的网页端,已对接你现有的后端接口。

## 完成范围

- ✅ 项目脚手架(Vite + React 18 + TS + Tailwind + React Router + zustand)
- ✅ 鉴权:登录(密码 + 验证码两种方式)、token 持久化、401 自动登出
- ✅ **3 大核心页**:
  - **社区**:推荐/热门/关注 三 Tab、帖子列表、点赞、跳详情
  - **帖子详情**:正文、图片、点赞、评论(可发评论、看评论)
  - **发帖**:文字 + 多图上传(走 /upload/image)+ 话题
  - **AI 首页**:心理咨询/学习辅导/综合聊天 三入口、最近会话列表、删除会话
  - **AI 对话页**:SSE 流式逐字回复、停止生成、消息历史
  - **我的**:资料展示(含 profileStatus 状态徽章)、编辑资料弹窗(昵称/简介/状态)、我发布的帖子列表
- ✅ Admin 分流:用户 role=admin 时,顶部和"我的"页都有「进入后台」按钮 → 跳到 `/admin/`(你现有的 index.html)
- ✅ 暖色治愈系视觉:陶土色 + 鼠尾草绿 + 暖纸感、圆润卡片

## 不在本阶段(留给下次)

- ❌ 知识库功能(阶段 2,要加后端表和接口)
- ❌ 注册页(可加,但鸿蒙端验证码登录已能自动建账号,网页同理)
- ❌ 消息/聊天/添加好友
- ❌ 我的点赞/我的评论
- ❌ 关注/取关、用户搜索、帖子搜索

## 本地开发

```bash
cd web
npm install
npm run dev          # 默认 5173 端口,会自动代理 /api → https://xsnbb.xyz/api
```

## 构建

```bash
npm run build        # 产物在 dist/
```

## 部署到宝塔

**1. 上传产物到服务器**

```bash
# Mac 上构建
cd web
npm run build

# 把 dist 目录传到服务器
scp -r dist/* root@39.96.36.94:/www/wwwroot/xsnbb.xyz/
```

**2. 关键:把现有 index.html(管理后台壳子)挪到 /admin/**

因为 React 网页接管了 `/`,而 admin 后台壳子要放到 `/admin/`:

```bash
ssh root@39.96.36.94
cd /www/wwwroot/xsnbb.xyz/

# 备份当前 index.html(现在是 admin 后台壳子)
mkdir -p admin
mv index.html admin/index.html   # ⚠️ 注意:这一步会把现在那个暖色后台移动到 /admin/

# 验证 admin 后台还能访问
ls admin/
```

**3. 上传 React 新产物到根目录**

```bash
# Mac 上
scp -r dist/* root@39.96.36.94:/www/wwwroot/xsnbb.xyz/
```

最终目录结构应该是:

```
/www/wwwroot/xsnbb.xyz/
├── index.html          ← React 网页(普通用户入口)
├── assets/
│   ├── index-xxx.js
│   └── index-xxx.css
└── admin/
    └── index.html      ← 管理后台壳子(admin 点"进入后台"打开)
```

**4. Nginx 配置:SPA history 路由 fallback**

React Router 用 history 模式,刷新非 `/` 页面(比如 `/post/123`)会 404。要在 Nginx 配置加 try_files。

打开宝塔 → 网站 → xsnbb.xyz → 配置文件,在 server 块里**加这一段**(放在敏感文件拦截规则之后、反向代理之前):

```nginx
location / {
    root /www/wwwroot/xsnbb.xyz;
    index index.html;
    try_files $uri $uri/ /index.html;
}

# /admin 也是 SPA(其实是单页 HTML),但加个 fallback 不影响
location /admin/ {
    root /www/wwwroot/xsnbb.xyz;
    try_files $uri $uri/ /admin/index.html;
}
```

⚠️ 注意:你现有的 `/api/` 反代要保留(放在 location / 之前或之后都行,顺序无所谓 Nginx 会自动按精确度匹配)。

`nginx -t && nginx -s reload`

## 验证清单

部署完后:

```
[ ] https://xsnbb.xyz 打开看到登录页
[ ] 用管理员账号登录 → 看到顶部"进入后台"按钮
[ ] 点"进入后台"打开新标签页到 /admin/(原管理面板)
[ ] 用普通用户账号登录 → 顶部没有后台按钮
[ ] 社区页能看到帖子,点赞、刷新都正常
[ ] 发帖能上传图片
[ ] AI 三个入口都能进,聊天逐字流式输出
[ ] 我的页能编辑昵称/简介/状态
[ ] 刷新非 / 页面不 404(SPA fallback 生效)
```

## 故障排查

- **登录后白屏** → 看浏览器控制台,大概率 token 没存 / API 401
- **/api 报 404** → Nginx 反代没生效,确认现有 /api/ 反代规则还在
- **SSE 不流式** → Nginx 反代没关 buffering(之前已配,但要确认)
- **刷新 /post/xxx 404** → SPA fallback 没加,见上面第 4 步
- **图片上传报"不支持格式"** → 后端 jar 没更新到最新版

## 阶段 2 预告

下次要做的:
- 后端新建 `knowledge_base` 表(用户级 AI 知识库)
- 后端 CRUD 接口:GET/POST/PUT/DELETE /knowledge
- 后端改 AI 调用:把用户启用的知识条目拼到 system prompt 前面
- 前端新页面 `/knowledge`:列表、新建、编辑、启用/禁用、删除
- 前端 AI 对话页:显示当前会话挂载的知识库标签
