USE mental_health;

CREATE TABLE IF NOT EXISTS `friend_request` (
  `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
  `from_user` BIGINT NOT NULL COMMENT '申请人',
  `to_user` BIGINT NOT NULL COMMENT '接收人',
  `message` VARCHAR(120) DEFAULT '',
  `status` TINYINT DEFAULT 0 COMMENT '0待处理 1已同意 2已拒绝',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_to_status` (`to_user`, `status`),
  INDEX `idx_from_to_status` (`from_user`, `to_user`, `status`)
) COMMENT '好友申请';

CREATE TABLE IF NOT EXISTS `friend_relation` (
  `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
  `user_id` BIGINT NOT NULL,
  `friend_id` BIGINT NOT NULL,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_user_friend` (`user_id`, `friend_id`),
  INDEX `idx_friend` (`friend_id`)
) COMMENT '好友关系';

SET @profile_status_exists = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'user'
    AND column_name = 'profile_status'
);

SET @profile_status_sql = IF(
  @profile_status_exists = 0,
  'ALTER TABLE `user` ADD COLUMN `profile_status` VARCHAR(20) DEFAULT ''在线'' COMMENT ''公开展示状态''',
  'SELECT 1'
);

PREPARE profile_status_stmt FROM @profile_status_sql;
EXECUTE profile_status_stmt;
DEALLOCATE PREPARE profile_status_stmt;
