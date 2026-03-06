-- 修复 Railway MySQL 1045 访问拒绝
-- 允许 root 从任意主机连接（包括 Railway 内部网络 10.x.x.x）
-- 用你本地能连上的方式执行此文件

-- 创建 root@'%' 或更新密码（MySQL 5.7+）
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY 'whoQkzmDZkVjPBTpPHBdAGKeHHEUAEGI';

-- MySQL 8.0 若已存在用户，用 ALTER
ALTER USER 'root'@'%' IDENTIFIED BY 'whoQkzmDZkVjPBTpPHBdAGKeHHEUAEGI';

-- 授权
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
