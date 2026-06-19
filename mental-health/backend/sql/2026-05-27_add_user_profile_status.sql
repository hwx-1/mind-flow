ALTER TABLE `user`
  ADD COLUMN `profile_status` VARCHAR(20) DEFAULT '在线' COMMENT '公开展示状态' AFTER `bio`;
