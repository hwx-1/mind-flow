package com.mental.health.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class DatabaseMigrationRunner implements ApplicationRunner {

    private final JdbcTemplate jdbcTemplate;

    @Override
    public void run(ApplicationArguments args) {
        ensureNotificationTable();
        ensureChatMessageTable();
        ensureChatConversationTable();
        ensureFriendRequestTable();
        ensureFriendRelationTable();
        ensureUserProfileStatusColumn();
        ensureAnnouncementTable();
    }

    private void ensureAnnouncementTable() {
        execute("create announcement table", """
                CREATE TABLE IF NOT EXISTS `announcement` (
                  `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
                  `title` VARCHAR(200) DEFAULT '' COMMENT '标题',
                  `content` TEXT NOT NULL COMMENT '公告内容',
                  `status` TINYINT DEFAULT 1 COMMENT '1上线/0下线(逻辑删除)',
                  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
                  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                  INDEX `idx_status` (`status`),
                  INDEX `idx_created` (`created_at`)
                ) COMMENT '公告'
                """);
        ensureColumn("announcement", "title", "`title` VARCHAR(200) DEFAULT '' COMMENT '标题'");
        ensureColumn("announcement", "content", "`content` TEXT NOT NULL COMMENT '公告内容'");
        ensureColumn("announcement", "status", "`status` TINYINT DEFAULT 1 COMMENT '1上线/0下线(逻辑删除)'");
        ensureColumn("announcement", "created_at", "`created_at` DATETIME DEFAULT CURRENT_TIMESTAMP");
        ensureColumn("announcement", "updated_at", "`updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP");
    }

    private void ensureNotificationTable() {
        execute("create notification table", """
                CREATE TABLE IF NOT EXISTS `notification` (
                  `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
                  `user_id` BIGINT NOT NULL COMMENT '接收者',
                  `from_user` BIGINT NOT NULL COMMENT '触发者',
                  `type` VARCHAR(20) NOT NULL COMMENT 'like/comment/follow/friend',
                  `target_id` BIGINT,
                  `target_type` TINYINT,
                  `content` VARCHAR(255),
                  `is_read` TINYINT DEFAULT 0,
                  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
                  INDEX `idx_user_read` (`user_id`, `is_read`),
                  INDEX `idx_created` (`created_at`)
                ) COMMENT '通知'
                """);
        ensureColumn("notification", "user_id", "`user_id` BIGINT NOT NULL COMMENT '接收者'");
        ensureColumn("notification", "from_user", "`from_user` BIGINT NOT NULL COMMENT '触发者'");
        ensureColumn("notification", "type", "`type` VARCHAR(20) NOT NULL COMMENT 'like/comment/follow/friend'");
        ensureColumn("notification", "target_id", "`target_id` BIGINT");
        ensureColumn("notification", "target_type", "`target_type` TINYINT");
        ensureColumn("notification", "content", "`content` VARCHAR(255)");
        ensureColumn("notification", "is_read", "`is_read` TINYINT DEFAULT 0");
        ensureColumn("notification", "created_at", "`created_at` DATETIME DEFAULT CURRENT_TIMESTAMP");
    }

    private void ensureChatMessageTable() {
        execute("create chat_message table", """
                CREATE TABLE IF NOT EXISTS `chat_message` (
                  `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
                  `from_user` BIGINT NOT NULL,
                  `to_user` BIGINT NOT NULL,
                  `content` TEXT NOT NULL,
                  `type` VARCHAR(10) DEFAULT 'text' COMMENT 'text/image',
                  `is_read` TINYINT DEFAULT 0,
                  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
                  INDEX `idx_from_to` (`from_user`, `to_user`),
                  INDEX `idx_to_read` (`to_user`, `is_read`)
                ) COMMENT '私信'
                """);
        ensureColumn("chat_message", "from_user", "`from_user` BIGINT NOT NULL");
        ensureColumn("chat_message", "to_user", "`to_user` BIGINT NOT NULL");
        ensureColumn("chat_message", "content", "`content` TEXT NOT NULL");
        ensureColumn("chat_message", "type", "`type` VARCHAR(10) DEFAULT 'text' COMMENT 'text/image'");
        ensureColumn("chat_message", "is_read", "`is_read` TINYINT DEFAULT 0");
        ensureColumn("chat_message", "created_at", "`created_at` DATETIME DEFAULT CURRENT_TIMESTAMP");
    }

    private void ensureChatConversationTable() {
        execute("create chat_conversation table", """
                CREATE TABLE IF NOT EXISTS `chat_conversation` (
                  `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
                  `user_id` BIGINT NOT NULL,
                  `other_user` BIGINT NOT NULL,
                  `last_message` VARCHAR(255),
                  `unread_count` INT DEFAULT 0,
                  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                  UNIQUE KEY `uk_user_other` (`user_id`, `other_user`),
                  INDEX `idx_updated` (`user_id`, `updated_at`)
                ) COMMENT '私信会话'
                """);
        ensureColumn("chat_conversation", "user_id", "`user_id` BIGINT NOT NULL");
        ensureColumn("chat_conversation", "other_user", "`other_user` BIGINT NOT NULL");
        ensureColumn("chat_conversation", "last_message", "`last_message` VARCHAR(255)");
        ensureColumn("chat_conversation", "unread_count", "`unread_count` INT DEFAULT 0");
        ensureColumn("chat_conversation", "updated_at", "`updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP");
    }

    private void ensureFriendRequestTable() {
        execute("create friend_request table", """
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
                ) COMMENT '好友申请'
                """);
        ensureColumn("friend_request", "message", "`message` VARCHAR(120) DEFAULT ''");
        ensureColumn("friend_request", "status", "`status` TINYINT DEFAULT 0 COMMENT '0待处理 1已同意 2已拒绝'");
        ensureColumn("friend_request", "created_at", "`created_at` DATETIME DEFAULT CURRENT_TIMESTAMP");
        ensureColumn("friend_request", "updated_at", "`updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP");
    }

    private void ensureFriendRelationTable() {
        execute("create friend_relation table", """
                CREATE TABLE IF NOT EXISTS `friend_relation` (
                  `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
                  `user_id` BIGINT NOT NULL,
                  `friend_id` BIGINT NOT NULL,
                  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
                  UNIQUE KEY `uk_user_friend` (`user_id`, `friend_id`),
                  INDEX `idx_friend` (`friend_id`)
                ) COMMENT '好友关系'
                """);
        ensureColumn("friend_relation", "user_id", "`user_id` BIGINT NOT NULL");
        ensureColumn("friend_relation", "friend_id", "`friend_id` BIGINT NOT NULL");
        ensureColumn("friend_relation", "created_at", "`created_at` DATETIME DEFAULT CURRENT_TIMESTAMP");
    }

    private void ensureUserProfileStatusColumn() {
        ensureColumn("user", "profile_status", "`profile_status` VARCHAR(20) DEFAULT '在线' COMMENT '公开展示状态'");
    }

    private void ensureColumn(String table, String column, String definition) {
        if (!tableExists(table) || columnExists(table, column)) {
            return;
        }
        execute("add column " + table + "." + column,
                "ALTER TABLE `" + table + "` ADD COLUMN " + definition);
    }

    private boolean tableExists(String table) {
        try {
            Integer count = jdbcTemplate.queryForObject("""
                    SELECT COUNT(*)
                    FROM information_schema.tables
                    WHERE table_schema = DATABASE() AND table_name = ?
                    """, Integer.class, table);
            return count != null && count > 0;
        } catch (Exception e) {
            log.warn("check table {} failed: {}", table, e.getMessage());
            return false;
        }
    }

    private boolean columnExists(String table, String column) {
        try {
            Integer count = jdbcTemplate.queryForObject("""
                    SELECT COUNT(*)
                    FROM information_schema.columns
                    WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ?
                    """, Integer.class, table, column);
            return count != null && count > 0;
        } catch (Exception e) {
            log.warn("check column {}.{} failed: {}", table, column, e.getMessage());
            return true;
        }
    }

    private void execute(String description, String sql) {
        try {
            jdbcTemplate.execute(sql);
            log.info("database migration ok: {}", description);
        } catch (Exception e) {
            log.warn("database migration skipped: {}: {}", description, e.getMessage());
        }
    }
}
