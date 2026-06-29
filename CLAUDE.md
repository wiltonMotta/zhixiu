# 致秀 — 多品牌服饰会员小程序

## 项目概述
面向线下中老年老客的多品牌服饰会员微信小程序，核心目标是客户留存、等级沉淀、复购锁客。线下为主、线上为辅，积分商城完全自营（对标海底捞模式）。

## 技术栈
- 前端：微信小程序原生 + WeUI + TypeScript
- 后端：NestJS + Prisma + PostgreSQL + Redis
- 后台管理：React + Ant Design Pro + TypeScript
- 部署：腾讯云Docker + GitHub Actions

## 品牌体系
1. 波司登（冬季羽绒主力）— brandId: "bosideng"
2. 致秀真丝（夏季高端真丝）— brandId: "zhixiu_silk"
3. 香绒纱（夏季轻奢女装）— brandId: "xiangrongsha"
4. 预留品牌空位 — brandId: "brand_N"

## 8条强制风控规则 [CRITICAL] — 不可违反
1. 生日信息永久锁定，前台后台均无修改入口
2. 四类商品(特价/促销/引流/清仓)永久屏蔽所有会员折扣+生日折上折
3. 生日折上折当月仅限5件正价商品，超出恢复原价
4. 积分仅按实付金额发放，折扣/优惠券/减免不计积分
5. 会员等级只升不降，消费永久累计不清零
6. 积分12个月滚动清零，到期前15天自动提醒
7. 线下代金券/干洗服务券仅本店线下正价商品可用
8. 积分商城全部自营，支持纯积分兑换+积分补差抵扣双模式

## 会员等级体系
| 等级 | 累计消费 | 日常折扣 | 生日折扣 | 干洗/年 |
|------|---------|---------|---------|--------|
| 普通 | 0元 | 无 | 无 | 0次 |
| 银卡 | 2000元 | 无 | 正价9折(限5件) | 0次 |
| 金卡 | 5000元 | 正价95折 | 正价85折(限5件) | 1次 |
| 钻石 | 10000元 | 正价9折 | 正价8折(限5件) | 2次 |

## 积分规则
- 实付1元 = 10积分，会员日1元 = 20积分
- 生日当月全月双倍积分（不限件数品类）
- 积分有效期12个月滚动清零

## 商品标签枚举
- REGULAR（正价）→ 允许折扣
- SPECIAL（特价）→ 屏蔽折扣
- PROMOTION（促销）→ 屏蔽折扣
- TRAFFIC（引流）→ 屏蔽折扣
- CLEARANCE（清仓）→ 屏蔽折扣

## 代码规范
- TypeScript strict mode
- 金额使用整数（分）存储，展示层转换为元
- ESLint + Prettier
- commit格式：[agent-name] type(scope): description

## 文档结构
- prompt/01-architecture-overview.md — 架构总览
- prompt/02-agent-roles-config.md — Agent角色与配置
- prompt/03-prompt-engineering.md — 提示词工程
- prompt/04-human-checklist.md — 人工操作清单
- prompt/05-agent-workflow.md — Agent工作流
- docs/PRD.pdf — 产品需求文档（终极定稿）

## 本地开发环境（超算容器）

### 基础设施（已部署）
- PostgreSQL 16.14: 127.0.0.1:5432 (zhixiu/zhixiu2026)
- Redis 7.4.2: 127.0.0.1:6379 (zhixiu2026redis)
- Nginx: 127.0.0.1:80 → 外部 https://c-xxxx:58043/
- 本地文件存储: ./data/storage/zhixiu-assets/ → /zx-assets/

### 安装路径
- PostgreSQL: /root/private_data/sun/tools/pgenv/
- Redis: /root/private_data/sun/tools/redis/
- Nginx: /root/private_data/sun/Download/nginx/

### 服务管理
```bash
./scripts/services.sh start|stop|status|restart
```

### Nginx路由（已配置）
- /api/         → NestJS后端 (127.0.0.1:3000)
- /zx-admin/    → 后台管理前端 (127.0.0.1:3001)
- /zx-assets/   → 静态文件存储 (本地目录)
- /zhixiu/      → 静态原型 (127.0.0.1:58040)

### 环境变量
- .env — 本地开发配置（不提交到仓库）
- .env.example — 模板（提交到仓库）

## Agent环境配置

### 已安装工具
- PostgreSQL 16.14 (conda-forge): /root/private_data/sun/tools/pgenv/
- Redis 7.4.2 (源码编译): /root/private_data/sun/tools/redis/
- Node.js v22.14.0: /root/private_data/sun/tools/node/
- npm 10.9.2: /root/private_data/sun/tools/node/

### 存储配置
- 文件存储目录: /root/private_data/sun/storage/zhixiu-assets/
- Nginx已配置 /zx-assets/ 路由指向该目录

### Agent配置
- 配置文件: agent-config.yaml
- Claude Code配置: ~/.claude/settings.json

### 待安装工具（无sudo权限）
- Docker (需要sudo权限)
- kubectl (需要sudo权限)
- 某些MCP服务器 (需要API密钥)
