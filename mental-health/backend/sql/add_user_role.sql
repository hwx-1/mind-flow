-- 给 user 表加 role 字段，区分管理员
-- 用法：mysql -umental -p mental_health < add_user_role.sql

USE mental_health;

ALTER TABLE `user`
  ADD COLUMN `role` VARCHAR(20) NOT NULL DEFAULT 'user'
  COMMENT '角色：user 普通用户 / admin 管理员' AFTER `status`;

-- 把你自己的账号设为管理员（把 'alice' 换成你的真实用户名或手机号）
-- 二选一执行：
-- UPDATE `user` SET `role` = 'admin' WHERE username = 'alice';
-- UPDATE `user` SET `role` = 'admin' WHERE phone = '13158268668';

-- 验证
SELECT id, username, phone, role, status FROM `user`;
