package com.mental.health.controller;

import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.nio.charset.StandardCharsets;

@RestController
public class ApiPageController {

    private static final MediaType TEXT_HTML_UTF8 = new MediaType("text", "html", StandardCharsets.UTF_8);

    @GetMapping(value = {"", "/"}, produces = "text/html;charset=UTF-8")
    public ResponseEntity<String> index() {
        return ResponseEntity.ok()
                .contentType(TEXT_HTML_UTF8)
                .cacheControl(CacheControl.noCache())
                .body(API_PAGE);
    }

    private static final String API_PAGE = """
            <!DOCTYPE html>
            <html lang="zh-CN">
            <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>心晴 · API 接口中心</title>
            <link rel="preconnect" href="https://fonts.googleapis.com">
            <link href="https://fonts.googleapis.com/css2?family=Noto+Serif+SC:wght@400;500;600;700&family=Noto+Sans+SC:wght@300;400;500;700&display=swap" rel="stylesheet">
            <style>
              :root {
                --cream: #faf6f0;
                --cream-deep: #f3ece1;
                --paper: #fffdfa;
                --terracotta: #d98e73;
                --terracotta-deep: #c2755a;
                --sage: #9caf88;
                --sage-deep: #7d9268;
                --clay: #8a7158;
                --ink: #4a3f35;
                --ink-soft: #8a7d6e;
                --line: #ece2d4;
                --gold: #e0b87f;
                --blush: #f0d4c4;
                --shadow: 0 4px 24px rgba(138, 113, 88, 0.08);
                --shadow-lg: 0 12px 48px rgba(138, 113, 88, 0.12);
                --radius: 20px;
                --radius-sm: 14px;
              }
              * { margin: 0; padding: 0; box-sizing: border-box; }
              html { scroll-behavior: smooth; }
              body {
                min-height: 100vh;
                font-family: 'Noto Sans SC', sans-serif;
                background: var(--cream);
                color: var(--ink);
                line-height: 1.6;
                -webkit-font-smoothing: antialiased;
              }
              body::before {
                content: '';
                position: fixed;
                inset: 0;
                background:
                  radial-gradient(circle at 12% 18%, rgba(217, 142, 115, 0.07), transparent 38%),
                  radial-gradient(circle at 88% 78%, rgba(156, 175, 136, 0.08), transparent 42%);
                pointer-events: none;
                z-index: 0;
              }
              a { color: inherit; text-decoration: none; }
              code, pre { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace; }
              .app { display: flex; min-height: 100vh; position: relative; z-index: 1; }
              aside {
                width: 252px;
                background: var(--paper);
                border-right: 1px solid var(--line);
                padding: 28px 18px;
                position: fixed;
                inset: 0 auto 0 0;
                overflow-y: auto;
                display: flex;
                flex-direction: column;
              }
              .brand {
                display: flex;
                align-items: center;
                gap: 11px;
                padding: 0 12px 28px;
              }
              .brand-mark {
                width: 42px;
                height: 42px;
                border-radius: 13px;
                background: linear-gradient(135deg, var(--terracotta), var(--gold));
                display: flex;
                align-items: center;
                justify-content: center;
                font-family: 'Noto Serif SC', serif;
                font-size: 22px;
                color: #fff;
                box-shadow: 0 4px 12px rgba(217, 142, 115, 0.3);
              }
              .brand-text { font-family: 'Noto Serif SC', serif; }
              .brand-text .name { font-size: 19px; font-weight: 700; color: var(--ink); }
              .brand-text .role { font-size: 11px; color: var(--ink-soft); letter-spacing: 0.1em; }
              .nav-label {
                font-size: 10px;
                color: var(--ink-soft);
                letter-spacing: 0.16em;
                padding: 16px 14px 8px;
                text-transform: uppercase;
              }
              .nav-item {
                display: flex;
                align-items: center;
                gap: 12px;
                padding: 11px 14px;
                border-radius: var(--radius-sm);
                color: var(--ink-soft);
                font-size: 14.5px;
                transition: all 0.2s;
                margin-bottom: 2px;
              }
              .nav-item:hover,
              .nav-item.active {
                background: linear-gradient(135deg, rgba(217, 142, 115, 0.14), rgba(224, 184, 127, 0.1));
                color: var(--terracotta-deep);
              }
              .nav-dot {
                width: 9px;
                height: 9px;
                border-radius: 50%;
                background: var(--sage);
                flex-shrink: 0;
              }
              .aside-footer {
                margin-top: auto;
                padding: 18px 14px 0;
                border-top: 1px dashed var(--line);
                color: var(--ink-soft);
                font-size: 12px;
              }
              main {
                flex: 1;
                margin-left: 252px;
                padding: 34px 38px 48px;
                max-width: 1440px;
              }
              .topbar {
                display: flex;
                justify-content: space-between;
                align-items: flex-start;
                gap: 24px;
                margin-bottom: 24px;
              }
              .title-block h1 {
                font-family: 'Noto Serif SC', serif;
                font-size: 32px;
                line-height: 1.25;
                color: var(--ink);
                margin-bottom: 8px;
              }
              .title-block p { color: var(--ink-soft); font-size: 14px; }
              .base-card {
                min-width: 330px;
                background: var(--paper);
                border: 1px solid var(--line);
                border-radius: var(--radius);
                box-shadow: var(--shadow);
                padding: 18px 20px;
              }
              .base-label {
                font-size: 12px;
                color: var(--ink-soft);
                letter-spacing: 0.12em;
                margin-bottom: 7px;
              }
              .base-url {
                display: flex;
                align-items: center;
                justify-content: space-between;
                gap: 12px;
                padding: 12px 14px;
                border-radius: var(--radius-sm);
                background: var(--cream);
                border: 1px solid var(--line);
                color: var(--terracotta-deep);
                font-weight: 700;
                word-break: break-all;
              }
              .copy-btn,
              .mini-btn {
                border: none;
                border-radius: 999px;
                background: linear-gradient(135deg, var(--terracotta), var(--terracotta-deep));
                color: #fff;
                font-family: inherit;
                font-size: 12px;
                padding: 8px 12px;
                cursor: pointer;
                box-shadow: 0 6px 18px rgba(194, 117, 90, 0.18);
                white-space: nowrap;
              }
              .copy-btn:hover,
              .mini-btn:hover { transform: translateY(-1px); }
              .toolbar {
                display: grid;
                grid-template-columns: minmax(220px, 1fr) auto;
                gap: 14px;
                margin-bottom: 18px;
              }
              .search {
                width: 100%;
                padding: 14px 18px;
                border: 1.5px solid var(--line);
                border-radius: var(--radius);
                background: var(--paper);
                color: var(--ink);
                font-family: inherit;
                font-size: 14px;
                box-shadow: var(--shadow);
                outline: none;
              }
              .search:focus {
                border-color: var(--terracotta);
                box-shadow: 0 0 0 4px rgba(217, 142, 115, 0.1);
              }
              .chips {
                display: flex;
                flex-wrap: wrap;
                gap: 8px;
                align-items: center;
              }
              .chip {
                border: 1px solid var(--line);
                background: var(--paper);
                color: var(--ink-soft);
                border-radius: 999px;
                padding: 10px 14px;
                font-family: inherit;
                font-size: 13px;
                cursor: pointer;
              }
              .chip.active {
                border-color: transparent;
                background: linear-gradient(135deg, rgba(217, 142, 115, 0.16), rgba(224, 184, 127, 0.16));
                color: var(--terracotta-deep);
                font-weight: 600;
              }
              .summary-grid {
                display: grid;
                grid-template-columns: repeat(4, minmax(0, 1fr));
                gap: 14px;
                margin-bottom: 24px;
              }
              .stat {
                background: var(--paper);
                border: 1px solid var(--line);
                border-radius: var(--radius);
                padding: 18px;
                box-shadow: var(--shadow);
              }
              .stat .num {
                font-family: 'Noto Serif SC', serif;
                font-size: 26px;
                color: var(--terracotta-deep);
                font-weight: 700;
              }
              .stat .text { color: var(--ink-soft); font-size: 13px; margin-top: 4px; }
              .info-grid {
                display: grid;
                grid-template-columns: repeat(3, minmax(0, 1fr));
                gap: 14px;
                margin-bottom: 24px;
              }
              .info-card,
              .section {
                background: var(--paper);
                border: 1px solid var(--line);
                border-radius: var(--radius);
                box-shadow: var(--shadow);
              }
              .info-card { padding: 20px; }
              .info-card h2 {
                font-family: 'Noto Serif SC', serif;
                font-size: 18px;
                margin-bottom: 10px;
              }
              .info-card p,
              .info-card li { color: var(--ink-soft); font-size: 13px; }
              .info-card ul { padding-left: 18px; }
              .token-box {
                margin-top: 12px;
                padding: 12px 14px;
                background: var(--cream);
                border: 1px dashed var(--line);
                border-radius: var(--radius-sm);
                color: var(--clay);
                font-size: 12px;
                overflow-x: auto;
              }
              .section {
                margin-bottom: 18px;
                overflow: hidden;
              }
              .section-head {
                display: flex;
                align-items: center;
                justify-content: space-between;
                gap: 16px;
                padding: 20px 22px;
                border-bottom: 1px solid var(--line);
                background: linear-gradient(135deg, rgba(250, 246, 240, 0.8), rgba(255, 253, 250, 0.9));
              }
              .section-title {
                display: flex;
                align-items: center;
                gap: 12px;
              }
              .section-title .mark {
                width: 34px;
                height: 34px;
                border-radius: 12px;
                display: flex;
                align-items: center;
                justify-content: center;
                color: #fff;
                background: linear-gradient(135deg, var(--sage), var(--sage-deep));
                font-weight: 700;
              }
              .section h2 {
                font-family: 'Noto Serif SC', serif;
                font-size: 20px;
                color: var(--ink);
              }
              .section-sub { color: var(--ink-soft); font-size: 13px; }
              .endpoint-list { display: grid; gap: 1px; background: var(--line); }
              .endpoint {
                display: grid;
                grid-template-columns: 92px minmax(230px, 1fr) minmax(260px, 1.1fr) 86px;
                gap: 16px;
                align-items: start;
                background: var(--paper);
                padding: 16px 22px;
              }
              .method {
                width: max-content;
                min-width: 72px;
                padding: 5px 10px;
                text-align: center;
                border-radius: 999px;
                color: #fff;
                font-size: 12px;
                font-weight: 700;
                letter-spacing: 0.04em;
              }
              .get { background: var(--sage-deep); }
              .post { background: var(--terracotta-deep); }
              .put { background: var(--gold); color: #6b4e28; }
              .delete { background: #a95f50; }
              .ws { background: var(--clay); }
              .path {
                color: var(--ink);
                font-weight: 700;
                word-break: break-all;
              }
              .desc { color: var(--ink-soft); font-size: 13px; }
              .auth {
                justify-self: end;
                border-radius: 999px;
                padding: 5px 10px;
                font-size: 12px;
                background: var(--cream);
                color: var(--clay);
                border: 1px solid var(--line);
              }
              .auth.public {
                background: rgba(156, 175, 136, 0.14);
                color: var(--sage-deep);
              }
              details {
                grid-column: 2 / 5;
                border-radius: var(--radius-sm);
                background: var(--cream);
                border: 1px solid var(--line);
                overflow: hidden;
              }
              summary {
                cursor: pointer;
                padding: 10px 14px;
                color: var(--clay);
                font-size: 13px;
                user-select: none;
              }
              pre {
                margin: 0;
                padding: 0 14px 14px;
                color: #5b4a3a;
                font-size: 12px;
                line-height: 1.7;
                white-space: pre-wrap;
                word-break: break-word;
              }
              .footer-note {
                margin-top: 28px;
                padding: 18px 20px;
                color: var(--ink-soft);
                font-size: 13px;
                border: 1px dashed var(--line);
                border-radius: var(--radius);
                background: rgba(255, 253, 250, 0.72);
              }
              .toast {
                position: fixed;
                right: 28px;
                bottom: 28px;
                z-index: 10;
                background: var(--ink);
                color: #fff;
                border-radius: 999px;
                padding: 11px 16px;
                font-size: 13px;
                opacity: 0;
                transform: translateY(8px);
                transition: all 0.2s;
                pointer-events: none;
              }
              .toast.show { opacity: 1; transform: translateY(0); }
              .empty {
                display: none;
                padding: 42px;
                text-align: center;
                color: var(--ink-soft);
                background: var(--paper);
                border: 1px dashed var(--line);
                border-radius: var(--radius);
              }
              @media (max-width: 1060px) {
                aside {
                  position: static;
                  width: 100%;
                  height: auto;
                  border-right: none;
                  border-bottom: 1px solid var(--line);
                }
                .app { display: block; }
                main { margin-left: 0; padding: 24px 18px 36px; }
                .topbar,
                .toolbar { grid-template-columns: 1fr; display: grid; }
                .base-card { min-width: 0; }
                .summary-grid,
                .info-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
                .endpoint { grid-template-columns: 82px 1fr; }
                .desc,
                .auth,
                details { grid-column: 2 / 3; }
                .auth { justify-self: start; }
              }
              @media (max-width: 640px) {
                aside { padding: 20px 14px; }
                .brand { padding-bottom: 18px; }
                .nav-section { display: none; }
                .title-block h1 { font-size: 26px; }
                .summary-grid,
                .info-grid { grid-template-columns: 1fr; }
                .endpoint {
                  grid-template-columns: 1fr;
                  gap: 9px;
                  padding: 16px;
                }
                .desc,
                .auth,
                details { grid-column: 1 / 2; }
                .section-head { align-items: flex-start; flex-direction: column; }
                .toolbar { gap: 10px; }
                .chips { overflow-x: auto; flex-wrap: nowrap; padding-bottom: 2px; }
                .chip { flex: 0 0 auto; }
              }
            </style>
            </head>
            <body>
            <div class="app">
              <aside>
                <div class="brand">
                  <div class="brand-mark">晴</div>
                  <div class="brand-text">
                    <div class="name">心晴</div>
                    <div class="role">API CENTER</div>
                  </div>
                </div>
                <nav class="nav-section">
                  <div class="nav-label">接口分组</div>
                  <a class="nav-item active" href="#overview"><span class="nav-dot"></span>概览</a>
                  <a class="nav-item" href="#auth"><span class="nav-dot"></span>认证登录</a>
                  <a class="nav-item" href="#user"><span class="nav-dot"></span>用户关系</a>
                  <a class="nav-item" href="#post"><span class="nav-dot"></span>帖子社区</a>
                  <a class="nav-item" href="#message"><span class="nav-dot"></span>消息私聊</a>
                  <a class="nav-item" href="#ai"><span class="nav-dot"></span>AI 对话</a>
                  <a class="nav-item" href="#upload"><span class="nav-dot"></span>上传资源</a>
                </nav>
                <div class="aside-footer">
                  当前页面由后端直接提供。上线后访问 <strong>xsnbb.xyz/api</strong> 即可查看。
                </div>
              </aside>
              <main>
                <section id="overview" class="topbar">
                  <div class="title-block">
                    <h1>心晴 API 接口中心</h1>
                    <p>用于 HarmonyOS 端与网页版共同对接，覆盖账号登录、帖子、关注好友、消息、AI 流式对话与上传。</p>
                  </div>
                  <div class="base-card">
                    <div class="base-label">BASE URL</div>
                    <div class="base-url">
                      <code id="baseUrl">https://xsnbb.xyz/api</code>
                      <button class="copy-btn" type="button" data-copy="#baseUrl">复制</button>
                    </div>
                  </div>
                </section>

                <div class="toolbar">
                  <input class="search" id="search" type="search" placeholder="搜索接口、路径或说明，例如：验证码、点赞、SSE">
                  <div class="chips" id="chips">
                    <button class="chip active" type="button" data-filter="all">全部</button>
                    <button class="chip" type="button" data-filter="public">公开</button>
                    <button class="chip" type="button" data-filter="auth">需登录</button>
                    <button class="chip" type="button" data-filter="stream">流式</button>
                  </div>
                </div>

                <div class="summary-grid">
                  <div class="stat"><div class="num">44</div><div class="text">已整理接口</div></div>
                  <div class="stat"><div class="num">6</div><div class="text">业务模块</div></div>
                  <div class="stat"><div class="num">SSE</div><div class="text">AI 实时流式返回</div></div>
                  <div class="stat"><div class="num">JWT</div><div class="text">Bearer Token 鉴权</div></div>
                </div>

                <div class="info-grid">
                  <div class="info-card">
                    <h2>返回格式</h2>
                    <p>普通接口统一返回 JSON，成功时 code 为 0。</p>
                    <div class="token-box"><code>{"code":0,"msg":"ok","data":{}}</code></div>
                  </div>
                  <div class="info-card">
                    <h2>鉴权方式</h2>
                    <p>除公开接口外，请在 Header 里携带登录返回的 token。</p>
                    <div class="token-box"><code>Authorization: Bearer &lt;token&gt;</code></div>
                  </div>
                  <div class="info-card">
                    <h2>部署说明</h2>
                    <ul>
                      <li>后端 context-path 已配置为 /api。</li>
                      <li>当前文档页映射到根路径 /。</li>
                      <li>完整访问地址就是 https://xsnbb.xyz/api。</li>
                    </ul>
                  </div>
                </div>

                <section id="auth" class="section" data-group="auth">
                  <div class="section-head">
                    <div class="section-title"><span class="mark">登</span><div><h2>认证登录</h2><p class="section-sub">账号密码、短信验证码、刷新 token 与第三方登录占位。</p></div></div>
                    <button class="mini-btn" type="button" data-copy-text="Authorization: Bearer <token>">复制鉴权头</button>
                  </div>
                  <div class="endpoint-list">
                    <article class="endpoint" data-public="true">
                      <span class="method post">POST</span><code class="path">/auth/register</code><p class="desc">注册账号，支持 username、password、phone、code。</p><span class="auth public">公开</span>
                      <details><summary>请求示例</summary><pre>{
  "username": "xiaoqing",
  "password": "123456",
  "phone": "13800138000",
  "code": "1234"
}</pre></details>
                    </article>
                    <article class="endpoint" data-public="true">
                      <span class="method post">POST</span><code class="path">/auth/login</code><p class="desc">账号密码登录，account 可传用户名或手机号。</p><span class="auth public">公开</span>
                      <details><summary>请求示例</summary><pre>{
  "account": "xiaoqing",
  "password": "123456"
}</pre></details>
                    </article>
                    <article class="endpoint" data-public="true">
                      <span class="method post">POST</span><code class="path">/auth/code</code><p class="desc">发送互亿短信验证码，scene 可为 login、register、reset_pwd。</p><span class="auth public">公开</span>
                      <details><summary>请求示例</summary><pre>{
  "phone": "13800138000",
  "scene": "login"
}</pre></details>
                    </article>
                    <article class="endpoint" data-public="true">
                      <span class="method post">POST</span><code class="path">/auth/login/code</code><p class="desc">手机号验证码登录，成功后返回 token、refreshToken 与 user。</p><span class="auth public">公开</span>
                      <details><summary>请求示例</summary><pre>{
  "phone": "13800138000",
  "code": "1234"
}</pre></details>
                    </article>
                    <article class="endpoint" data-public="true">
                      <span class="method post">POST</span><code class="path">/auth/refresh</code><p class="desc">使用 refreshToken 换取新的登录凭证。</p><span class="auth public">公开</span>
                      <details><summary>请求示例</summary><pre>{
  "refreshToken": "refresh-token"
}</pre></details>
                    </article>
                    <article class="endpoint" data-public="true">
                      <span class="method post">POST</span><code class="path">/auth/oauth/{provider}</code><p class="desc">第三方登录入口，provider 可传 wechat 或 qq；当前后端为演示占位。</p><span class="auth public">公开</span>
                      <details><summary>请求示例</summary><pre>{
  "provider": "wechat",
  "authCode": "client-auth-code"
}</pre></details>
                    </article>
                  </div>
                </section>

                <section id="user" class="section" data-group="user">
                  <div class="section-head">
                    <div class="section-title"><span class="mark">人</span><div><h2>用户关系</h2><p class="section-sub">资料、搜索、关注、好友申请与好友同意。</p></div></div>
                  </div>
                  <div class="endpoint-list">
                    <article class="endpoint" data-auth="true"><span class="method get">GET</span><code class="path">/user/profile</code><p class="desc">获取当前登录用户资料。</p><span class="auth">需登录</span></article>
                    <article class="endpoint" data-auth="true"><span class="method get">GET</span><code class="path">/user/profile/{userId}</code><p class="desc">查看其他用户资料，包含可见状态、关注关系等。</p><span class="auth">需登录</span></article>
                    <article class="endpoint" data-auth="true"><span class="method get">GET</span><code class="path">/user/search?keyword=</code><p class="desc">按昵称、账号或 uid 搜索用户。</p><span class="auth">需登录</span></article>
                    <article class="endpoint" data-auth="true">
                      <span class="method put">PUT</span><code class="path">/user/update</code><p class="desc">编辑资料与状态，role 会被后端保护，不能通过此接口改权限。</p><span class="auth">需登录</span>
                      <details><summary>请求示例</summary><pre>{
  "nickname": "晴天",
  "avatar": "https://xsnbb.xyz/static/avatar.png",
  "bio": "今天也好好生活",
  "profileStatus": "online"
}</pre></details>
                    </article>
                    <article class="endpoint" data-auth="true">
                      <span class="method put">PUT</span><code class="path">/user/password</code><p class="desc">修改当前账号密码。</p><span class="auth">需登录</span>
                      <details><summary>请求示例</summary><pre>{
  "oldPassword": "123456",
  "newPassword": "654321"
}</pre></details>
                    </article>
                    <article class="endpoint" data-auth="true"><span class="method post">POST</span><code class="path">/user/{userId}/follow</code><p class="desc">关注或取消关注用户，返回 followed。</p><span class="auth">需登录</span></article>
                    <article class="endpoint" data-auth="true">
                      <span class="method post">POST</span><code class="path">/user/{userId}/friend/request</code><p class="desc">向指定用户发送好友申请。</p><span class="auth">需登录</span>
                      <details><summary>请求示例</summary><pre>{
  "message": "你好，我想和你聊聊"
}</pre></details>
                    </article>
                    <article class="endpoint" data-auth="true">
                      <span class="method post">POST</span><code class="path">/user/friend/request-by-uid</code><p class="desc">通过对方唯一 uid 添加好友。</p><span class="auth">需登录</span>
                      <details><summary>请求示例</summary><pre>{
  "uid": "10000001",
  "message": "我是从搜索页来的"
}</pre></details>
                    </article>
                    <article class="endpoint" data-auth="true"><span class="method get">GET</span><code class="path">/user/friend/requests</code><p class="desc">获取收到的好友申请列表。</p><span class="auth">需登录</span></article>
                    <article class="endpoint" data-auth="true"><span class="method get">GET</span><code class="path">/user/friends</code><p class="desc">获取通讯录好友列表，包含头像、昵称、状态与在线标记。</p><span class="auth">需登录</span></article>
                    <article class="endpoint" data-auth="true"><span class="method post">POST</span><code class="path">/user/friend/requests/{id}/accept</code><p class="desc">同意某条好友申请。</p><span class="auth">需登录</span></article>
                  </div>
                </section>

                <section id="post" class="section" data-group="post">
                  <div class="section-head">
                    <div class="section-title"><span class="mark">帖</span><div><h2>帖子社区</h2><p class="section-sub">信息流、搜索、发布、详情、点赞收藏与评论。</p></div></div>
                  </div>
                  <div class="endpoint-list">
                    <article class="endpoint" data-public="true"><span class="method get">GET</span><code class="path">/post/list?type=recommend&page=1&size=10</code><p class="desc">获取帖子列表，type 可按前端约定传 recommend、follow 等。</p><span class="auth public">公开</span></article>
                    <article class="endpoint" data-public="true"><span class="method get">GET</span><code class="path">/post/search?keyword=&page=1&size=10</code><p class="desc">搜索帖子内容或话题。</p><span class="auth public">公开</span></article>
                    <article class="endpoint" data-public="true"><span class="method get">GET</span><code class="path">/post/{id}</code><p class="desc">获取帖子详情，登录时会附带 liked、collected 等状态。</p><span class="auth public">公开</span></article>
                    <article class="endpoint" data-auth="true">
                      <span class="method post">POST</span><code class="path">/post/publish</code><p class="desc">发布帖子，可携带图片、视频、话题与定位信息。</p><span class="auth">需登录</span>
                      <details><summary>请求示例</summary><pre>{
  "content": "今天散步看到了很好看的晚霞",
  "images": ["https://xsnbb.xyz/static/1.jpg"],
  "video": "",
  "topic": "日常",
  "locationLabel": "北京市朝阳区",
  "latitude": 39.9219,
  "longitude": 116.4432,
  "address": "朝阳公园"
}</pre></details>
                    </article>
                    <article class="endpoint" data-auth="true"><span class="method delete">DELETE</span><code class="path">/post/{id}/delete</code><p class="desc">删除自己的帖子。</p><span class="auth">需登录</span></article>
                    <article class="endpoint" data-auth="true"><span class="method post">POST</span><code class="path">/post/{id}/like</code><p class="desc">点赞或取消点赞，返回 liked。</p><span class="auth">需登录</span></article>
                    <article class="endpoint" data-auth="true"><span class="method post">POST</span><code class="path">/post/{id}/collect</code><p class="desc">收藏或取消收藏，返回 collected。</p><span class="auth">需登录</span></article>
                    <article class="endpoint" data-public="true"><span class="method get">GET</span><code class="path">/post/{id}/comments?page=1&size=20</code><p class="desc">获取帖子评论列表。</p><span class="auth public">公开</span></article>
                    <article class="endpoint" data-auth="true">
                      <span class="method post">POST</span><code class="path">/post/{id}/comment</code><p class="desc">发表评论或回复评论，返回评论 id。</p><span class="auth">需登录</span>
                      <details><summary>请求示例</summary><pre>{
  "content": "我也喜欢这里",
  "replyId": null
}</pre></details>
                    </article>
                    <article class="endpoint" data-auth="true"><span class="method get">GET</span><code class="path">/post/my?page=1&size=10</code><p class="desc">获取我的发帖。</p><span class="auth">需登录</span></article>
                    <article class="endpoint" data-auth="true"><span class="method get">GET</span><code class="path">/post/user/{userId}?page=1&size=10</code><p class="desc">获取指定用户公开帖子。</p><span class="auth">需登录</span></article>
                    <article class="endpoint" data-auth="true"><span class="method get">GET</span><code class="path">/post/my-comments</code><p class="desc">获取我的评论记录。</p><span class="auth">需登录</span></article>
                    <article class="endpoint" data-auth="true"><span class="method get">GET</span><code class="path">/post/my-likes?page=1&size=10</code><p class="desc">获取我的点赞帖子。</p><span class="auth">需登录</span></article>
                  </div>
                </section>

                <section id="message" class="section" data-group="message">
                  <div class="section-head">
                    <div class="section-title"><span class="mark">信</span><div><h2>消息私聊</h2><p class="section-sub">通知、未读数、会话列表、私聊消息与 WebSocket。</p></div></div>
                  </div>
                  <div class="endpoint-list">
                    <article class="endpoint" data-auth="true"><span class="method get">GET</span><code class="path">/message/notifications?type=all&page=1&size=20</code><p class="desc">获取系统通知，type 可按 all、like、comment、follow 等使用。</p><span class="auth">需登录</span></article>
                    <article class="endpoint" data-auth="true"><span class="method get">GET</span><code class="path">/message/unread-count</code><p class="desc">获取未读通知与聊天数量。</p><span class="auth">需登录</span></article>
                    <article class="endpoint" data-auth="true">
                      <span class="method post">POST</span><code class="path">/message/read</code><p class="desc">标记通知或消息已读。</p><span class="auth">需登录</span>
                      <details><summary>请求示例</summary><pre>{
  "type": "all",
  "ids": [1, 2, 3]
}</pre></details>
                    </article>
                    <article class="endpoint" data-auth="true"><span class="method get">GET</span><code class="path">/message/chats</code><p class="desc">获取当前用户聊天会话列表。</p><span class="auth">需登录</span></article>
                    <article class="endpoint" data-auth="true"><span class="method get">GET</span><code class="path">/message/chats/{userId}</code><p class="desc">获取与指定用户的聊天记录。</p><span class="auth">需登录</span></article>
                    <article class="endpoint" data-auth="true">
                      <span class="method post">POST</span><code class="path">/message/send</code><p class="desc">发送私聊消息，陌生人打招呼限制由业务层决定。</p><span class="auth">需登录</span>
                      <details><summary>请求示例</summary><pre>{
  "toUserId": 10000001,
  "content": "你好",
  "type": "text"
}</pre></details>
                    </article>
                    <article class="endpoint" data-auth="true"><span class="method ws">WS</span><code class="path">/ws/im?token=&lt;token&gt;</code><p class="desc">即时消息 WebSocket 通道。</p><span class="auth">需登录</span></article>
                  </div>
                </section>

                <section id="ai" class="section" data-group="ai">
                  <div class="section-head">
                    <div class="section-title"><span class="mark">AI</span><div><h2>AI 对话</h2><p class="section-sub">会话管理、历史消息与 text/event-stream 实时流式输出。</p></div></div>
                  </div>
                  <div class="endpoint-list">
                    <article class="endpoint" data-auth="true"><span class="method get">GET</span><code class="path">/ai/sessions?business=mental</code><p class="desc">获取 AI 会话列表，business 可为 mental、study、general。</p><span class="auth">需登录</span></article>
                    <article class="endpoint" data-auth="true">
                      <span class="method post">POST</span><code class="path">/ai/sessions</code><p class="desc">创建 AI 会话。</p><span class="auth">需登录</span>
                      <details><summary>请求示例</summary><pre>{
  "business": "mental",
  "title": "今晚有点焦虑"
}</pre></details>
                    </article>
                    <article class="endpoint" data-auth="true"><span class="method delete">DELETE</span><code class="path">/ai/sessions/{id}</code><p class="desc">删除指定 AI 会话。</p><span class="auth">需登录</span></article>
                    <article class="endpoint" data-auth="true"><span class="method get">GET</span><code class="path">/ai/sessions/{id}/messages</code><p class="desc">获取会话历史消息。</p><span class="auth">需登录</span></article>
                    <article class="endpoint" data-auth="true" data-stream="true">
                      <span class="method post">POST</span><code class="path">/ai/chat</code><p class="desc">SSE 流式对话，响应 Content-Type 为 text/event-stream；每帧 data 为 {"delta":"片段"}，结束帧为 [DONE]。</p><span class="auth">需登录</span>
                      <details open><summary>请求示例</summary><pre>{
  "sessionId": 1,
  "content": "我今天压力很大"
}</pre></details>
                    </article>
                  </div>
                </section>

                <section id="upload" class="section" data-group="upload">
                  <div class="section-head">
                    <div class="section-title"><span class="mark">传</span><div><h2>上传资源</h2><p class="section-sub">图片、视频上传，返回可访问 URL。</p></div></div>
                  </div>
                  <div class="endpoint-list">
                    <article class="endpoint" data-public="true"><span class="method post">POST</span><code class="path">/upload/image</code><p class="desc">上传图片到阿里云 OSS，multipart/form-data，字段名 file。</p><span class="auth public">公开</span></article>
                    <article class="endpoint" data-public="true"><span class="method post">POST</span><code class="path">/upload/video</code><p class="desc">上传视频，multipart/form-data，字段名 file。</p><span class="auth public">公开</span></article>
                    <article class="endpoint" data-public="true"><span class="method get">GET</span><code class="path">/static/{filename}</code><p class="desc">访问已上传资源；生产环境也可以由 Nginx 直接托管 /static。</p><span class="auth public">公开</span></article>
                  </div>
                </section>

                <div class="empty" id="empty">没有找到匹配的接口。</div>
                <div class="footer-note">提示：如果线上访问出现 401，请确认后端安全白名单包含根路径 /，并确认宝塔反向代理把 xsnbb.xyz/api 正确转发到 Spring Boot 的 /api context-path。</div>
              </main>
            </div>
            <div class="toast" id="toast">已复制</div>
            <script>
              const $ = (selector, root = document) => root.querySelector(selector);
              const $$ = (selector, root = document) => Array.from(root.querySelectorAll(selector));
              const search = $('#search');
              const chips = $$('#chips .chip');
              const sections = $$('.section');
              const endpoints = $$('.endpoint');
              const empty = $('#empty');
              let filter = 'all';

              function textOf(node) {
                return node.textContent.toLowerCase();
              }

              function updateVisible() {
                const keyword = (search.value || '').trim().toLowerCase();
                let visibleCount = 0;
                sections.forEach(section => {
                  let sectionVisible = false;
                  $$('.endpoint', section).forEach(endpoint => {
                    const matchKeyword = !keyword || textOf(endpoint).includes(keyword);
                    const matchFilter =
                      filter === 'all' ||
                      (filter === 'public' && endpoint.dataset.public === 'true') ||
                      (filter === 'auth' && endpoint.dataset.auth === 'true') ||
                      (filter === 'stream' && endpoint.dataset.stream === 'true');
                    const visible = matchKeyword && matchFilter;
                    endpoint.style.display = visible ? 'grid' : 'none';
                    sectionVisible = sectionVisible || visible;
                    if (visible) visibleCount += 1;
                  });
                  section.style.display = sectionVisible ? 'block' : 'none';
                });
                empty.style.display = visibleCount ? 'none' : 'block';
              }

              search.addEventListener('input', updateVisible);
              chips.forEach(chip => {
                chip.addEventListener('click', () => {
                  chips.forEach(item => item.classList.remove('active'));
                  chip.classList.add('active');
                  filter = chip.dataset.filter;
                  updateVisible();
                });
              });

              function showToast(text) {
                const toast = $('#toast');
                toast.textContent = text;
                toast.classList.add('show');
                window.clearTimeout(showToast.timer);
                showToast.timer = window.setTimeout(() => toast.classList.remove('show'), 1500);
              }

              async function copyText(text) {
                try {
                  await navigator.clipboard.writeText(text);
                  showToast('已复制');
                } catch (error) {
                  showToast('复制失败，请手动选择');
                }
              }

              $$('[data-copy]').forEach(btn => {
                btn.addEventListener('click', () => {
                  const target = $(btn.dataset.copy);
                  if (target) copyText(target.textContent.trim());
                });
              });

              $$('[data-copy-text]').forEach(btn => {
                btn.addEventListener('click', () => copyText(btn.dataset.copyText));
              });

              const navItems = $$('.nav-item');
              const observer = new IntersectionObserver(entries => {
                entries.forEach(entry => {
                  if (!entry.isIntersecting) return;
                  navItems.forEach(item => item.classList.toggle('active', item.getAttribute('href') === '#' + entry.target.id));
                });
              }, { rootMargin: '-30% 0px -60% 0px' });
              ['overview', 'auth', 'user', 'post', 'message', 'ai', 'upload'].forEach(id => {
                const el = document.getElementById(id);
                if (el) observer.observe(el);
              });
            </script>
            </body>
            </html>
            """;
}
