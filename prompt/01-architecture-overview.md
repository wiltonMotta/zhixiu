# 多品牌服饰会员小程序 — AI Agent 全自主开发体系架构总览

## 一、项目概览

本项目为一款面向线下中老年老客的多品牌服饰会员微信小程序，核心目标是客户留存、等级沉淀、复购锁客。采用"线下为主、线上为辅"策略，积分商城完全自营（对标海底捞模式），支持波司登、致秀真丝、香绒纱等多品牌无限拓展。

## 二、技术栈选型（Agent友好）

| 层级 | 技术选型 | Agent友好理由 |
|------|---------|--------------|
| **小程序前端** | 微信小程序原生 + WeUI组件库 | 文档完备、社区成熟、AI生成代码质量高 |
| **后端服务** | Node.js (NestJS) / Python (FastAPI) | 两者AI生成质量最高，NestJS结构化强，FastAPI简洁 |
| **数据库** | PostgreSQL + Redis | 关系型+缓存，AI生成的SQL/ORM代码质量高 |
| **对象存储** | 腾讯云COS | 微信生态原生集成 |
| **支付** | 微信支付V3 | 官方SDK成熟 |
| **消息推送** | 微信订阅消息 | 官方能力 |
| **后台管理** | React + Ant Design Pro | Agent可自主生成CRUD页面 |
| **部署** | 腾讯云Serverless / Docker | Agent可通过CI/CD自动化部署 |

### 推荐主技术栈：NestJS + PostgreSQL + React Ant Design Pro

理由：
1. NestJS的模块化架构与Agent的分工协作天然匹配
2. TypeScript全栈统一，减少Agent上下文切换
3. Prisma ORM让Agent生成的数据库操作更安全
4. Ant Design Pro的约定式路由让Agent可以自动生成管理页面

## 三、项目目录结构

```
zhixiu/
├── docs/                          # PRD与设计文档
├── prompt/                        # 提示词工程文件
│   ├── 01-architecture-overview.md
│   ├── 02-agent-roles-config.md
│   ├── 03-prompt-engineering.md
│   ├── 04-human-checklist.md
│   └── 05-agent-workflow.md
├── miniprogram/                   # 微信小程序前端
│   ├── pages/
│   │   ├── index/                 # 首页Tab
│   │   ├── brand-mall/            # 品牌商城Tab
│   │   ├── points-center/         # 积分中心Tab
│   │   └── profile/               # 我的Tab
│   ├── components/                # 公共组件
│   ├── services/                  # API调用层
│   ├── utils/                     # 工具函数
│   ├── styles/                    # 全局样式
│   ├── app.js / app.json / app.wxss
│   └── project.config.json
├── server/                        # 后端服务
│   ├── src/
│   │   ├── modules/
│   │   │   ├── auth/              # 认证模块
│   │   │   ├── member/            # 会员模块
│   │   │   ├── product/           # 商品模块
│   │   │   ├── order/             # 订单模块
│   │   │   ├── points/            # 积分模块
│   │   │   ├── coupon/            # 卡券模块
│   │   │   ├── payment/           # 支付模块
│   │   │   ├── brand/             # 品牌模块
│   │   │   └── notification/      # 消息推送模块
│   │   ├── common/                # 公共模块
│   │   └── main.ts
│   ├── prisma/
│   │   └── schema.prisma          # 数据库模型
│   └── test/
├── admin/                         # 后台管理系统
│   ├── src/
│   │   ├── pages/
│   │   │   ├── product/           # 商品管理
│   │   │   ├── points-shop/       # 积分商城管理
│   │   │   ├── member/            # 会员管理
│   │   │   ├── order/             # 订单管理
│   │   │   ├── coupon/            # 卡券核销
│   │   │   ├── points-config/     # 积分规则配置
│   │   │   └── notification/      # 消息管理
│   │   └── components/
│   └── package.json
├── infra/                         # 基础设施配置
│   ├── docker-compose.yml
│   ├── nginx.conf
│   └── ci-cd/
├── tests/                         # 集成测试与E2E测试
│   ├── e2e/
│   └── integration/
└── scripts/                       # 自动化脚本
    ├── seed.ts                    # 种子数据
    └── deploy.sh
```

## 四、Agent协作架构图

```
                    ┌─────────────────────────┐
                    │     产品经理 Agent       │
                    │  (需求拆解/PRD/验收)      │
                    └──────────┬──────────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
    ┌─────────▼──────┐ ┌──────▼───────┐ ┌──────▼───────┐
    │  架构师 Agent   │ │  UI设计Agent │ │ 测试Agent    │
    │ (DB/API/架构)  │ │ (页面/组件)   │ │ (单元/E2E)   │
    └─────────┬──────┘ └──────┬───────┘ └──────┬───────┘
              │                │                │
    ┌─────────▼──────┐ ┌──────▼───────┐ ┌──────▼───────┐
    │  后端开发Agent  │ │  前端开发Agent│ │ 运维Agent    │
    │ (API/业务逻辑) │ │ (小程序/后台) │ │ (部署/监控)   │
    └────────────────┘ └──────────────┘ └──────────────┘
              │                │                │
    ┌─────────▼────────────────▼────────────────▼───────┐
    │              运营管理Agent (商品/内容/运营)          │
    │         (后台管理Agent友好接口层)                   │
    └────────────────────────────────────────────────────┘
```

## 五、核心设计原则

1. **Agent-First API**: 所有后台API设计必须支持Agent直接调用，提供结构化的JSON输入输出
2. **约定优于配置**: 代码结构、命名规范、接口规范全部约定化，减少Agent决策负担
3. **幂等操作**: 所有写操作设计为幂等，Agent可安全重试
4. **声明式配置**: 积分规则、会员等级、风控规则全部声明式配置，Agent可通过修改配置文件调整
5. **测试驱动**: Agent先写测试再写实现，确保风控逻辑绝对正确
