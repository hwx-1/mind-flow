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

CREATE TABLE IF NOT EXISTS `friend_relation` (
  id          BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id     BIGINT NOT NULL,
  friend_id   BIGINT NOT NULL,
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_user_friend (user_id, friend_id),
  INDEX idx_friend (friend_id)
) COMMENT '好友关系';
