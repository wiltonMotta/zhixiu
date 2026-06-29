# 对话记录 #002 — 超算容器Nginx反向代理方案可行性分析

> 日期：2026-06-29
> 主题：SCNet Notebook Nginx路由方案能否支撑微信小程序后端

---

## 用户提供的信息

- 超算Notebook对外暴露URL：`https://c-2056205187675406338.qdai.scnet.cn:58043/`
- 可以自定义映射一个端口
- 使用Nginx反向代理，通过路由对外暴露各种服务
- 已有致秀原型在 `/zhixiu/` 路径下运行

## 实际环境探查结果

| 项目 | 实际配置 |
|------|---------|
| CPU | 64核（2×7390 32C，容器分配7核） |
| 内存 | **2TB**（容器分配245GB） |
| 磁盘 | **19PB** 存储集群，可用16PB |
| GPU | A800 80GB × 1 |
| Node.js | v22.14.0 ✅ |
| Python | 3.11.9 ✅ |
| Nginx | 已安装并运行 ✅ |
| Docker | ❌ 不可用 |
| sudo | ❌ 需要密码 |
| 对外端口 | 仅58043（HTTPS，scnet.cn自带SSL） |

### 现有Nginx路由映射

| 外部路径 | 内部服务 | 说明 |
|---------|---------|------|
| `https://c-xxxx:58043/` | 127.0.0.1:3456 | Claude API代理 |
| `https://c-xxxx:58043/v1/` | 127.0.0.1:8000 | vLLM (Qwen3.6-35B) |
| `https://c-xxxx:58043/zhixiu/` | 127.0.0.1:58040 | 致秀静态原型 |
| `https://c-xxxx:58043/mcp/` | 127.0.0.1:8002 | MCP服务 |
| `https://c-xxxx:58043/vnc/` | 127.0.0.1:6080 | noVNC |
| `https://c-xxxx:58043/auth/` | 127.0.0.1:8002 | 认证服务 |
| `https://c-xxxx:58043/remote-chrome/` | 127.0.0.1:6090 | 远程Chrome |
| `https://c-xxxx:58043/chrome-debug/` | 127.0.0.1:9222 | Chrome调试 |

---

## 核心结论

### ✅ 开发阶段：完全可行，且极其强大

在开发阶段，你的超算容器方案**完全可行**，甚至比任何云服务器都强。

| 维度 | 评估 | 说明 |
|------|------|------|
| 运行NestJS后端 | ✅ 完美 | Node 22 + 7核 + 245GB内存，远超需求 |
| 运行PostgreSQL | ✅ 可行 | 需用户空间安装（无需sudo/Docker） |
| 运行Redis | ✅ 可行 | 同上 |
| 运行MinIO | ✅ 可行 | 同上 |
| Nginx路由分发 | ✅ 已有成熟方案 | 你已经在用了 |
| 开发者工具调试 | ✅ 完美 | 勾选"不校验合法域名"即可请求超算URL |
| 真机预览 | ✅ 可行 | 小程序体验版可以通过超算URL访问 |

### ⚠️ 上线阶段：存在3个硬性限制，需额外解决

| 限制 | 严重程度 | 说明 |
|------|---------|------|
| **端口58043** | 🔴 致命 | 微信小程序服务器域名**不支持非443端口**，`https://xxx:58043` 无法配置 |
| **ICP备案** | 🔴 致命 | `scnet.cn` 是科研机构域名，**无法用于商业ICP备案** |
| **域名稳定性** | 🟡 重要 | 实例ID可能变化（`c-2056205187675406338`），域名不稳定 |

---

## 详细分析

### 1. 微信小程序服务器域名的硬性规则

微信小程序后台配置服务器域名时：
```
✅ 正确格式：https://api.zhixiu.com
❌ 错误格式：https://api.zhixiu.com:58043  （不支持自定义端口）
❌ 错误格式：https://c-xxxx.qdai.scnet.cn:58043  （端口+不可备案域名）
```

**规则**：
1. 只支持 `https://` 开头
2. 只支持标准443端口（不可指定端口）
3. 域名必须通过ICP备案
4. 不支持IP地址
5. 不支持通配符域名（`*.scnet.cn`）

### 2. 你的Nginx路由方案的适配性

你的方案核心是：**一个端口 + Nginx路由分发**，这个架构本身非常好。

```
外部入口: https://c-xxxx:58043/
    ├── /zhixiu/    → 静态原型
    ├── /v1/        → vLLM
    ├── /mcp/       → MCP
    ├── /api/       → 🆕 致秀后端API（新增）
    ├── /admin/     → 🆕 后台管理前端（新增）
    └── /assets/    → 🆕 MinIO图片服务（新增）
```

**开发阶段**：在微信开发者工具中勾选「不校验合法域名」后，可以直接请求：
```
https://c-xxxx.qdai.scnet.cn:58043/api/v1/products
```

**问题只在上线时出现**：正式版小程序必须配置合法域名，而 `scnet.cn:58043` 无法通过。

### 3. 上线解决方案

#### 方案A：超算开发 + 轻量服务器上线（推荐 ⭐）

```
开发阶段（0成本）：
  超算容器运行全栈服务
  小程序开发者工具 → 直连超算URL

上线阶段（2,136元/年）：
  购买腾讯云轻量服务器 + 域名 + ICP备案
  轻量服务器运行NestJS + Nginx
  域名备案后配置到小程序后台

  可选：轻量服务器做反向代理，后端仍在超算
  用户 → 域名(443) → 轻量服务器Nginx → 超算容器API
  这样超算只提供计算，轻量只做流量转发
```

#### 方案B：frp内网穿透（适合不想买服务器）

```
购买域名 + ICP备案
域名DNS指向frp服务器（需一台有公网IP的VPS，~50元/月）
frp客户端运行在超算容器
frp服务端运行在VPS的443端口

用户 → 域名(443) → VPS frp → 超算容器API

VPS最便宜方案：腾讯云轻量 1核1G ≈ 50元/月 = 600元/年
```

#### 方案C：Cloudflare Tunnel（免费，但需域名）

```
购买域名 + 接入Cloudflare
在超算容器运行 cloudflared tunnel
Cloudflare自动提供HTTPS + CDN

用户 → 域名(443) → Cloudflare CDN → Tunnel → 超算容器API

⚠️ 问题：域名仍需ICP备案才能配置到小程序
```

---

## 开发阶段落地方案

### 第一步：在Nginx中添加致秀后端路由

修改 `/root/private_data/sun/Download/nginx/conf/vllm-proxy.conf`，添加以下路由：

```nginx
    # ==================== 致秀小程序后端 ====================
    
    # NestJS 后端API
    location /api/ {
        proxy_pass http://127.0.0.1:3000/api/;
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
        proxy_send_timeout 300s;
        proxy_buffering off;
        
        # WebSocket支持（如需要）
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    # 后台管理前端（React Ant Design Pro）
    location /admin/ {
        proxy_pass http://127.0.0.1:3001/;
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # MinIO 对象存储API
    location /oss/ {
        proxy_pass http://127.0.0.1:9000/;
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        client_max_body_size 50m;  # 允许大文件上传
        proxy_read_timeout 300s;
        proxy_buffering off;
    }
    
    # MinIO 管理控制台
    location /oss-console/ {
        proxy_pass http://127.0.0.1:9001/;
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
```

### 第二步：用户空间安装PostgreSQL和Redis（无需sudo）

由于没有Docker和sudo，需要用用户空间方式安装：

```bash
# ===== PostgreSQL 用户空间安装 =====
# 方案1：下载预编译二进制
cd /root/private_data/sun/Download
curl -L https://get.enterprisedb.com/postgresql/postgresql-16.4-1-linux-x64-binaries.tar.gz -o pg.tar.gz
tar xzf pg.tar.gz

# 初始化数据库
export PGDATA=/root/private_data/sun/claudeWorkspace/zhixiu/data/pgdata
export PGHOST=/tmp
mkdir -p $PGDATA
/root/private_data/sun/Download/pgsql/bin/initdb -D $PGDATA

# 修改配置允许本地连接
echo "listen_addresses = '127.0.0.1'" >> $PGDATA/postgresql.conf
echo "port = 5432" >> $PGDATA/postgresql.conf
echo "unix_socket_directories = '/tmp'" >> $PGDATA/postgresql.conf

# 启动
/root/private_data/sun/Download/pgsql/bin/pg_ctl -D $PGDATA -l $PGDATA/logfile start

# 创建数据库和用户
/root/private_data/sun/Download/pgsql/bin/psql -h /tmp -p 5432 -U root -c "CREATE DATABASE zhixiu;"
/root/private_data/sun/Download/pgsql/bin/psql -h /tmp -p 5432 -U root -c "CREATE USER zhixiu WITH PASSWORD 'your_password';"
/root/private_data/sun/Download/pgsql/bin/psql -h /tmp -p 5432 -U root -c "GRANT ALL PRIVILEGES ON DATABASE zhixiu TO zhixiu;"


# ===== Redis 用户空间安装 =====
cd /root/private_data/sun/Download
curl -L https://github.com/redis/redis/archive/refs/tags/7.4.1.tar.gz -o redis.tar.gz
# 如果没有gcc，使用预编译二进制
curl -L https://packages.redis.io/redis-stack/redis-stack-server-7.4.0-v2.jammy.x86_64.tar.gz -o redis-stack.tar.gz
tar xzf redis-stack.tar.gz

# 启动Redis
/root/private_data/sun/Download/redis-stack-server-7.4.0-v2/bin/redis-server \
  --port 6379 \
  --requirepass your_redis_password \
  --maxmemory 1gb \
  --maxmemory-policy allkeys-lru \
  --daemonize yes


# ===== MinIO 用户空间安装 =====
cd /root/private_data/sun/Download
curl -L https://dl.min.io/server/minio/release/linux-amd64/minio -o minio
chmod +x minio

# 启动MinIO
export MINIO_ROOT_USER=zhixiu
export MINIO_ROOT_PASSWORD=your_minio_password
/root/private_data/sun/Download/minio server \
  /root/private_data/sun/claudeWorkspace/zhixiu/data/minio \
  --console-address ":9001" \
  --address ":9000" &
```

### 第三步：启动NestJS后端和Admin前端

```bash
# 后端
cd /root/private_data/sun/claudeWorkspace/zhixiu/server
npm run start:dev  # 监听3000端口

# 后台管理前端
cd /root/private_data/sun/claudeWorkspace/zhixiu/admin
npm run dev  # 监听3001端口
```

### 第四步：微信开发者工具配置

```
1. 打开微信开发者工具
2. 详情 → 本地设置 → ✅ 不校验合法域名、web-view、TLS版本及HTTPS证书
3. 请求后端API：
   基础URL: https://c-2056205187675406338.qdai.scnet.cn:58043/api/v1/
4. 后台管理访问：
   https://c-2056205187675406338.qdai.scnet.cn:58043/admin/
5. 图片上传到MinIO：
   https://c-2056205187675406338.qdai.scnet.cn:58043/oss/
```

---

## 完整的Nginx路由规划

```
https://c-xxxx.qdai.scnet.cn:58043/
│
├── /                     → Claude API代理（原有）
├── /v1/                  → vLLM（原有）
├── /v1/messages          → Claude Messages API（原有）
├── /health               → vLLM健康检查（原有）
├── /mcp/                 → MCP服务（原有）
├── /vnc/                 → noVNC（原有）
├── /auth/                → 认证（原有）
├── /remote-chrome/       → 远程Chrome（原有）
├── /chrome-debug/        → Chrome调试（原有）
│
├── /zhixiu/              → 致秀静态原型（原有）
│
├── /api/                 → 🆕 NestJS后端API
│   ├── /api/v1/auth/     → 认证模块
│   ├── /api/v1/members/  → 会员模块
│   ├── /api/v1/products/ → 商品模块
│   ├── /api/v1/orders/   → 订单模块
│   ├── /api/v1/points/   → 积分模块
│   ├── /api/v1/coupons/  → 卡券模块
│   ├── /api/v1/payment/  → 支付模块
│   └── /api/v1/admin/    → 后台管理API
│
├── /admin/               → 🆕 后台管理前端
├── /oss/                 → 🆕 MinIO对象存储API
└── /oss-console/         → 🆕 MinIO管理控制台
```

---

## 总结

| 阶段 | 方案 | 可行性 | 成本 |
|------|------|--------|------|
| **开发阶段** | 超算Nginx全路由 | ✅ 完全可行 | 0元 |
| **调试阶段** | 开发者工具 + 不校验域名 | ✅ 完全可行 | 0元 |
| **真机体验版** | 超算URL + 体验版 | ✅ 可行 | 0元 |
| **正式上线** | 需备案域名+443端口 | ❌ 超算无法满足 | 需额外方案 |

**最终建议**：

```
现在 → 用超算容器全力开发（0成本，超算2TB内存+7核CPU远超任何云服务器）
        ↓
同时 → 购买域名 + 启动ICP备案（这步越早越好，10-20天）
        ↓
开发完成后 → 买一台最便宜的轻量服务器（50元/月），域名指向它
        ↓
两种上线策略选一：
  策略1：轻量服务器跑全部服务（简单，2,136元/年）
  策略2：轻量服务器只做Nginx反向代理 → 转发到超算API（省钱，计算仍在超算）
```

**策略2的架构**：
```
用户小程序 → https://api.zhixiu.com(443) → 轻量服务器Nginx → HTTPS:58043 → 超算API
                                  ↑
                           ICP备案域名
                           SSL证书
```
这样轻量服务器几乎不消耗资源，1核1G就够，约600元/年。

---

## 待确认事项

- [ ] 超算平台是否可以映射443端口？如果能，直接用自有域名+备案即可
- [ ] 超算容器实例重启后，外部URL是否变化？（影响长期可用性）
- [ ] 超算容器是否有数据持久化保障？（2.3TB已用空间说明有）
- [ ] 是否可以在超算容器中安装PostgreSQL/Redis/MinIO二进制文件（无需sudo）

---

## 实际执行记录（2026-06-29）

### 安装结果

| 服务 | 版本 | 安装方式 | 安装路径 | 状态 |
|------|------|---------|---------|------|
| PostgreSQL | 16.14 | conda (conda-forge) | /root/private_data/sun/tools/pgenv/ | ✅ 运行中 |
| Redis | 7.4.2 | 源码编译 (make) | /root/private_data/sun/tools/redis/ | ✅ 运行中 |
| MinIO | — | ❌ 下载超时 | — | 放弃，用本地文件存储替代 |

### 关键发现

1. **conda可用但需要系统代理**：默认代理20171不通，需设置 `http_proxy=http://scnkt47u2f:007dbce8@10.1.4.13:3120`
2. **conda默认环境不可写**：需创建用户空间环境 `-p /root/private_data/sun/tools/pgenv`
3. **Redis源码编译很快**：gcc已安装，make -j7编译Redis仅需几秒
4. **MinIO下载极慢**：dl.min.io通过代理速度<50KB/s，15分钟仅下载2MB/65MB，放弃
5. **本地文件存储完全够用**：初期商品图片量小，Nginx直接提供静态文件服务即可

### 数据库初始化

```sql
-- PostgreSQL已创建：
-- 用户: zhixiu / 密码: zhixiu2026
-- 数据库: zhixiu
-- 连接URL: postgresql://zhixiu:zhixiu2026@127.0.0.1:5432/zhixiu

-- Redis已配置：
-- 端口: 6379 / 密码: zhixiu2026redis
-- 最大内存: 1GB / 持久化: AOF+RDB
-- 连接URL: redis://:zhixiu2026redis@127.0.0.1:6379
```

### Nginx路由已配置（待reload生效）

| 路由 | 后端 | 用途 |
|------|------|------|
| /api/ | 127.0.0.1:3000 | NestJS后端API |
| /zx-admin/ | 127.0.0.1:3001 | 后台管理前端 |
| /zx-assets/ | 本地目录 | 静态文件存储（图片等） |
| /zhixiu/ | 127.0.0.1:58040 | 静态原型 |

### 服务管理脚本

```bash
/root/private_data/sun/claudeWorkspace/zhixiu/scripts/services.sh start|stop|status|restart
```

### PostgreSQL配置优化（超算245GB内存）

```
shared_buffers = 2GB
effective_cache_size = 6GB
work_mem = 64MB
max_connections = 200
```
