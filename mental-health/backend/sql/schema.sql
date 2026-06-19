-- ========================================
-- AI 心理健康助手 - 数据库结构
-- MySQL 8.0+ / utf8mb4
-- ========================================
CREATE DATABASE IF NOT EXISTS mental_health DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE mental_health;

-- 用户表
CREATE TABLE IF NOT EXISTS `user` (
  id          BIGINT PRIMARY KEY AUTO_INCREMENT,
  username    VARCHAR(50)  NOT NULL UNIQUE COMMENT '用户名',
  password    VARCHAR(100) NOT NULL COMMENT 'BCrypt 加密',
  phone       VARCHAR(20)  UNIQUE,
  nickname    VARCHAR(50),
  avatar      VARCHAR(255) DEFAULT '',
  bio         VARCHAR(255) DEFAULT '',
  profile_status VARCHAR(20) DEFAULT '在线' COMMENT '公开展示状态',
  gender      TINYINT      DEFAULT 0 COMMENT '0未知 1男 2女',
  birthday    DATE,
  status      TINYINT      DEFAULT 1 COMMENT '1正常 0禁用',
  role        VARCHAR(20)  NOT NULL DEFAULT 'user' COMMENT '角色：user 普通用户 / admin 管理员',
  created_at  DATETIME     DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_phone (phone)
) COMMENT '用户表';

-- 帖子表
CREATE TABLE IF NOT EXISTS `post` (
  id            BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id       BIGINT       NOT NULL,
  content       TEXT         NOT NULL,
  images        TEXT         COMMENT 'JSON 数组',
  video         VARCHAR(500) COMMENT '视频 URL',
  topic         VARCHAR(50)  COMMENT '话题',
  like_count    INT          DEFAULT 0,
  comment_count INT          DEFAULT 0,
  view_count    INT          DEFAULT 0,
  status        TINYINT      DEFAULT 1 COMMENT '1正常 0删除',
  created_at    DATETIME     DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_user (user_id),
  INDEX idx_created (created_at DESC)
) COMMENT '帖子';

-- 评论表（支持二级回复）
CREATE TABLE IF NOT EXISTS `comment` (
  id          BIGINT PRIMARY KEY AUTO_INCREMENT,
  post_id     BIGINT  NOT NULL,
  user_id     BIGINT  NOT NULL,
  reply_id    BIGINT  COMMENT '回复的评论 id',
  reply_user  BIGINT  COMMENT '被回复用户 id',
  content     VARCHAR(500) NOT NULL,
  like_count  INT     DEFAULT 0,
  status      TINYINT DEFAULT 1,
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_post (post_id),
  INDEX idx_user (user_id)
) COMMENT '评论';

-- 点赞表（帖子和评论共用，target_type 区分）
CREATE TABLE IF NOT EXISTS `like_record` (
  id           BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id      BIGINT NOT NULL,
  target_id    BIGINT NOT NULL,
  target_type  TINYINT NOT NULL COMMENT '1帖子 2评论',
  created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_user_target (user_id, target_id, target_type)
) COMMENT '点赞';

-- 收藏
CREATE TABLE IF NOT EXISTS `collect` (
  id         BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id    BIGINT NOT NULL,
  post_id    BIGINT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_user_post (user_id, post_id)
) COMMENT '收藏';

-- 关注
CREATE TABLE IF NOT EXISTS `follow` (
  id          BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id     BIGINT NOT NULL,
  follow_id   BIGINT NOT NULL,
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_user_follow (user_id, follow_id)
) COMMENT '关注关系';

-- 好友申请
CREATE TABLE IF NOT EXISTS `friend_request` (
  id          BIGINT PRIMARY KEY AUTO_INCREMENT,
  from_user   BIGINT NOT NULL COMMENT '申请人',
  to_user     BIGINT NOT NULL COMMENT '接收人',
  message     VARCHAR(120) DEFAULT '',
  status      TINYINT DEFAULT 0 COMMENT '0待处理 1已同意 2已拒绝',
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_to_status (to_user, status),
  INDEX idx_from_to_status (from_user, to_user, status)
) COMMENT '好友申请';

-- 好友关系
CREATE TABLE IF NOT EXISTS `friend_relation` (
  id          BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id     BIGINT NOT NULL,
  friend_id   BIGINT NOT NULL,
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_user_friend (user_id, friend_id),
  INDEX idx_friend (friend_id)
) COMMENT '好友关系';

-- AI 会话
CREATE TABLE IF NOT EXISTS `ai_session` (
  id          BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id     BIGINT NOT NULL,
  business    VARCHAR(20) NOT NULL COMMENT 'mental/study/general',
  title       VARCHAR(100) DEFAULT '新会话',
  last_msg    VARCHAR(255),
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_user_business (user_id, business),
  INDEX idx_updated (updated_at DESC)
) COMMENT 'AI 会话';

-- AI 消息
CREATE TABLE IF NOT EXISTS `ai_message` (
  id          BIGINT PRIMARY KEY AUTO_INCREMENT,
  session_id  BIGINT  NOT NULL,
  role        VARCHAR(10) NOT NULL COMMENT 'user/assistant/system',
  content     TEXT NOT NULL,
  tokens      INT DEFAULT 0,
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_session (session_id, created_at)
) COMMENT 'AI 消息';

-- 通知
CREATE TABLE IF NOT EXISTS `notification` (
  id          BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id     BIGINT NOT NULL COMMENT '接收者',
  from_user   BIGINT NOT NULL COMMENT '触发者',
  type        VARCHAR(20) NOT NULL COMMENT 'like/comment/follow',
  target_id   BIGINT COMMENT '关联的帖子/评论 id',
  target_type TINYINT,
  content     VARCHAR(255),
  is_read     TINYINT DEFAULT 0,
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_user_read (user_id, is_read),
  INDEX idx_created (created_at DESC)
) COMMENT '通知';

-- 私信消息
CREATE TABLE IF NOT EXISTS `chat_message` (
  id           BIGINT PRIMARY KEY AUTO_INCREMENT,
  from_user    BIGINT NOT NULL,
  to_user      BIGINT NOT NULL,
  content      TEXT   NOT NULL,
  type         VARCHAR(10) DEFAULT 'text' COMMENT 'text/image',
  is_read      TINYINT DEFAULT 0,
  created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_from_to (from_user, to_user),
  INDEX idx_to_read (to_user, is_read)
) COMMENT '私信';

-- 私信会话（聚合最近一条）
CREATE TABLE IF NOT EXISTS `chat_conversation` (
  id            BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id       BIGINT NOT NULL,
  other_user    BIGINT NOT NULL,
  last_message  VARCHAR(255),
  unread_count  INT DEFAULT 0,
  updated_at    DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_user_other (user_id, other_user),
  INDEX idx_updated (user_id, updated_at DESC)
) COMMENT '私信会话';


-- 好友申请
CREATE TABLE IF NOT EXISTS `friend_request` (
  id          BIGINT PRIMARY KEY AUTO_INCREMENT,
  from_user   BIGINT NOT NULL COMMENT '申请人',
  to_user     BIGINT NOT NULL COMMENT '接收人',
  message     VARCHAR(120) DEFAULT '',
  status      TINYINT DEFAULT 0 COMMENT '0待处理 1已同意 2已拒绝',
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_to_status (to_user, status),
  INDEX idx_from_to_status (from_user, to_user, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT '好友申请';

-- 好友关系（互为好友时插入两条）
CREATE TABLE IF NOT EXISTS `friend_relation` (
  id          BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id     BIGINT NOT NULL,
  friend_id   BIGINT NOT NULL,
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_user_friend (user_id, friend_id),
  INDEX idx_friend (friend_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT '好友关系';
