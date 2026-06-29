# 权限配置文档

## 用户组配置

### sunjg用户组成员
```bash
sunjg : sunjg sudo sunjgrp docker
```

### 权限说明
- **docker组**: 可无需sudo直接操作Docker（docker ps, docker build等）
- **sudo组**: 拥有管理员权限，可执行需要root权限的命令

## Docker Socket权限

```bash
# Docker socket权限
$ ls -la /var/run/docker.sock
srw-rw---- 1 root docker 0 Jun 29 19:32 /var/run/docker.sock

# ACL权限
$ getfacl /var/run/docker.sock
# file: var/run/docker.sock
# owner: root
# group: docker
user::rw-
group::rw-
other::---
```

## sudoers配置

### sunjg用户的sudo权限
```bash
# 配置文件: /etc/sudoers.d/sunjg-restart-nginx
# 当前配置:
(root) NOPASSWD: /usr/bin/bash /root/private_data/sun/Download/restart_nginx.sh
(root) NOPASSWD: /root/private_data/sun/Download/nginx/sbin/nginx
```

## 使用说明

### Docker使用
```bash
# sunjg用户可以直接使用
docker ps
docker build -t zhixiu .
docker-compose up -d

# 需要sudo权限的操作
sudo docker system prune
```

### Sudo使用
```bash
# sunjg用户可以直接执行
sudo systemctl restart docker
sudo apt update
```

## 注意事项
- Docker守护进程当前未运行，需要先启动
- 部分sudo命令需要密码
- 当前环境可能无法完全验证权限（缺少systemd）
