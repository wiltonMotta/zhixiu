# Agent工作流与执行计划

## 一、开发阶段工作流详细设计

### 1.1 Phase 0: 项目初始化（Day 1）

**执行Agent**: 架构师Agent + 运维Agent

```bash
# 架构师Agent执行
1. 创建项目目录结构
2. 初始化NestJS项目 (server/)
3. 初始化Prisma项目
4. 设计并创建完整Schema (prisma/schema.prisma)
5. 输出API Spec (docs/api-spec.yaml)
6. 输出架构文档 (docs/architecture.md)

# 运维Agent执行
1. 创建GitHub仓库
2. 配置GitHub Actions CI
3. 创建Docker配置
4. 配置环境变量模板 (.env.example)
5. 创建开发环境Docker Compose
```

**输出物清单**:
- [x] 项目目录结构
- [x] package.json (server + admin)
- [x] prisma/schema.prisma
- [x] docs/api-spec.yaml
- [x] docs/architecture.md
- [x] .github/workflows/ci.yml
- [x] docker-compose.dev.yml
- [x] .env.example

### 1.2 Phase 1: 核心基础模块（Day 2-4）

**执行Agent**: 后端Agent + 测试Agent

**模块开发顺序与依赖**:

```
模块1: Auth (微信登录认证)
  ├── 微信登录 → openid/session_key
  ├── JWT Token签发
  └── 无依赖
  
模块2: Brand (品牌管理)
  ├── 品牌CRUD
  └── 无依赖
  
模块3: Member (会员管理) → 依赖: Auth
  ├── 会员注册/资料
  ├── 生日信息锁定 [CRITICAL-1]
  ├── 等级计算 [CRITICAL-5]
  └── 等级只升不降验证

模块4: Product (商品管理) → 依赖: Brand
  ├── 商品CRUD
  ├── 多品牌分类
  ├── 商品标签枚举
  └── 四类商品折扣屏蔽 [CRITICAL-2]

模块5: Order (订单管理) → 依赖: Member, Product
  ├── 下单/购物车
  ├── 折扣计算引擎
  ├── 生日折扣限购 [CRITICAL-3]
  └── 订单状态机

模块6: Points (积分管理) → 依赖: Member, Order
  ├── 积分发放 [CRITICAL-4]
  ├── 积分商城
  ├── 积分滚动清零 [CRITICAL-6]
  └── 积分+现金双模式 [CRITICAL-8]

模块7: Coupon (卡券管理) → 依赖: Member, Product
  ├── 代金券/干洗券
  ├── 卡券核销
  └── 券仅线下正价 [CRITICAL-7]

模块8: Payment (支付模块) → 依赖: Order
  ├── 微信支付V3集成
  ├── 支付回调
  └── 退款处理

模块9: Notification (消息推送) → 依赖: Member
  ├── 订阅消息
  ├── 积分到期提醒
  └── 卡券到期提醒
```

**每个模块的执行流程**:

```
1. 测试Agent先编写测试用例（根据API Spec）
   输出: {module}.service.spec.ts + {module}.controller.spec.ts
   
2. 后端Agent实现模块
   输入: API Spec + Prisma Schema + 测试用例
   输出: {module}.module.ts + .controller.ts + .service.ts + dto/
   
3. 测试Agent运行测试
   - 单元测试: npm run test
   - 覆盖率检查: npm run test:cov
   - 风控逻辑专项: npm run test:risk-control
   
4. 代码审查Agent审查
   - 风控逻辑一致性
   - 安全性
   - 代码规范
   - 合并到main
```

### 1.3 Phase 2: 前端开发（Day 4-8）

**执行Agent**: 前端Agent + UI设计Agent

**小程序页面开发顺序**:

```
1. 基础框架
   ├── app.js + app.json (TabBar配置)
   ├── 全局样式变量
   ├── services/api.ts (请求封装)
   ├── services/auth.ts (登录)
   └── components/ (基础组件)

2. Tab4: 我的（最简单，先开发验证流程）
   ├── 会员卡片
   ├── 等级与权益
   ├── 订单列表
   └── 卡券列表

3. Tab1: 首页
   ├── 搜索
   ├── Banner
   ├── 四宫格入口
   ├── 品牌专区
   └── 风控提示

4. Tab2: 品牌商城
   ├── 品牌切换
   ├── 商品列表
   ├── 商品详情
   ├── 购物车
   └── 结算

5. Tab3: 积分中心
   ├── 积分概览
   ├── 积分商城
   ├── 代金券兑换
   └── 积分明细

6. 补充页面
   ├── 支付页面
   ├── 订单详情
   ├── 地址管理
   └── 售后申请
```

**后台管理页面开发顺序**:

```
1. 基础框架
   ├── Ant Design Pro布局
   ├── 登录页
   └── 权限控制

2. 商品管理页
   ├── 商品列表 + 筛选
   ├── 商品创建/编辑表单
   ├── 图片上传组件
   └── 批量导入

3. 积分商城管理页
   ├── 积分商品列表
   ├── 积分商品创建/编辑
   └── 积分兑换订单

4. 会员管理页
   ├── 会员列表 + 搜索
   ├── 会员详情
   └── 线下消费录入

5. 订单管理页
   ├── 订单列表
   ├── 发货操作
   └── 售后审核

6. 卡券管理页
   ├── 卡券列表
   ├── 核销操作
   └── 发放操作

7. 数据统计页
   ├── 总览仪表盘
   └── 各维度图表

8. 积分规则配置页
   ├── 规则编辑
   └── 开关控制
```

### 1.4 Phase 3: 集成测试与优化（Day 8-10）

**执行Agent**: 测试Agent + 审查Agent

```
1. 端到端测试
   ├── 注册→浏览→下单→支付→积分→兑换 全链路
   ├── 生日月全流程：生日折扣+限购+双倍积分
   ├── 会员升级全流程：消费→达标→升级→权益生效
   └── 积分全生命周期：获取→累计→兑换→到期清零

2. 风控逻辑专项测试（40+用例）
   └── 参见03-prompt-engineering.md中的风控测试矩阵

3. 性能测试
   ├── API响应时间 < 500ms (P95)
   ├── 小程序首屏加载 < 3秒
   └── 并发100用户下单

4. 安全测试
   ├── SQL注入
   ├── XSS
   ├── 越权访问
   └── 支付篡改

5. 兼容性测试
   ├── iOS + Android双平台
   ├── 微信版本兼容
   └── 不同机型适配
```

### 1.5 Phase 4: 部署上线（Day 10-12）

**执行Agent**: 运维Agent + 人工配合

```
1. 生产环境部署
   ├── 服务器环境初始化
   ├── Docker镜像构建与部署
   ├── Nginx反向代理配置
   ├── SSL证书部署
   ├── 数据库迁移
   └── Redis配置

2. 微信配置
   ├── 服务器域名配置（人工）
   ├── 支付回调URL配置（人工+Agent）
   ├── 订阅消息模板申请（人工）
   └── 小程序版本上传（Agent通过CI）

3. 线上验证
   ├── 全链路冒烟测试
   ├── 支付真实金额测试（1分钱）
   └── 风控规则线上验证

4. 提交审核（人工操作）
   └── 参见04-human-checklist.md
```

---

## 二、运营阶段工作流

### 2.1 日常运营Agent工作流

```
每日自动任务（CronJob + 运营Agent）：
├── 06:00 积分到期检查 → 推送提醒
├── 08:00 卡券到期检查 → 推送提醒
├── 09:00 生日祝福检查 → 推送祝福+权益提醒
├── 10:00 会员等级重算 → 自动升级
├── 12:00 运营数据汇总 → 生成日报
└── 23:00 积分清零执行（每月1日）

每周任务：
├── 会员增长分析 → 运营建议
├── 商品销量排行 → 库存预警
└── 积分兑换数据 → 商品调整建议
```

### 2.2 商品上架Agent工作流

```
运营Agent接收商品上架任务 →
  
  Step 1: 解析商品信息
    输入：品牌+品名+货号+价格+规格+分类
    输出：结构化商品数据
  
  Step 2: 生成商品文案
    - 标题优化（品牌+系列+品类+卖点）
    - 描述撰写（面料/工艺/版型/场景）
    - 搜索关键词
  
  Step 3: 图片处理
    - 如有原始图片 → 裁剪+压缩+上传COS
    - 如无原始图片 → AI生成参考图 → 上传COS
    - 生成多尺寸：1:1主图 / 3:4详情图 / 16:9场景图
  
  Step 4: 设置商品标签
    - 正价商品：tags=["REGULAR"]
    - 根据运营策略选择标签
    - 系统自动应用风控规则
  
  Step 5: 调用Admin API创建商品
    POST /api/v1/admin/products
  
  Step 6: 验证
    - 在小程序中搜索该商品
    - 验证折扣显示是否正确
    - 验证风控规则是否生效
  
  Step 7: 输出操作日志
```

### 2.3 积分商城运营Agent工作流

```
运营Agent执行积分商城管理 →

  商品上架：
  1. 确定积分商品类型（配饰/洗护/礼品/服务券）
  2. 设置全积分兑换价（纯积分模式）
  3. 设置积分+现金抵扣价（补差模式）
  4. 上传商品图片
  5. 设置库存与发货方式
  6. POST /api/v1/admin/points-products

  价格调整：
  1. 查询当前积分商品列表
  2. 根据库存/兑换率调整积分价
  3. PUT /api/v1/admin/points-products/:id

  代金券配置：
  1. 设置面值（50/100/200）
  2. 设置所需积分
  3. 设置使用限制（仅线下正价）
  4. POST /api/v1/admin/coupons/issue (批量发放)
```

---

## 三、Agent间通信协议

### 3.1 任务委派格式

```typescript
interface AgentTask {
  id: string;                    // UUID
  from: string;                  // 发起Agent
  to: string;                    // 接收Agent
  type: string;                  // 任务类型
  priority: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';
  input: Record<string, any>;    // 输入数据
  expectedOutput: string;        // 期望输出描述
  deadline: string;              // ISO 8601
  dependencies?: string[];       // 依赖的任务ID
}
```

### 3.2 状态更新格式

```typescript
interface TaskStatus {
  taskId: string;
  status: 'PENDING' | 'IN_PROGRESS' | 'BLOCKED' | 'REVIEW' | 'DONE' | 'FAILED';
  progress: number;              // 0-100
  output?: Record<string, any>;  // 输出数据
  error?: string;                // 错误信息
  updatedAt: string;             // ISO 8601
}
```

### 3.3 代码提交规范

```
commit message格式：
[agent-name] type(scope): description

示例：
[backend-agent] feat(order): implement birthday discount with 5-item limit
[test-agent] test(points): add risk control test cases for CRITICAL-4
[frontend-agent] feat(brand-mall): implement brand tab switching
[review-agent] fix(member): fix birthday lock bypass in update API
```

---

## 四、持续集成/持续部署 (CI/CD)

### 4.1 CI流水线

```yaml
# .github/workflows/ci.yml
name: CI Pipeline

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main, develop]

jobs:
  backend-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: cd server && npm ci
      - run: cd server && npm run test
      - run: cd server && npm run test:cov
      - run: cd server && npm run test:risk-control  # 风控专项测试
  
  frontend-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: cd miniprogram && npm ci
      - run: cd miniprogram && npm run build
  
  admin-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: cd admin && npm ci
      - run: cd admin && npm run build
  
  risk-control-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          # 风控规则一致性检查
          # 1. 检查所有CRITICAL标记是否在代码中存在
          # 2. 检查测试用例是否覆盖所有CRITICAL规则
          # 3. 检查数据库Schema是否支持风控逻辑
          cd scripts && ./risk-control-check.sh

  deploy-staging:
    needs: [backend-test, frontend-build, admin-build, risk-control-check]
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    steps:
      - run: # 部署到测试环境
```

### 4.2 CD流水线

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  workflow_dispatch:  # 人工触发
    inputs:
      version:
        description: 'Release version'
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Database Migration
        run: cd server && npx prisma migrate deploy
      - name: Deploy Backend
        run: docker-compose -f docker-compose.prod.yml up -d
      - name: Upload Mini Program
        run: |
          # 使用微信开发者工具CLI上传代码
          # 获取miniprogram upload token
          # 执行上传
      - name: Smoke Test
        run: curl -f https://${DOMAIN}/api/v1/health
      - name: Notify
        run: # 发送部署成功通知
```

---

## 五、监控与告警

### 5.1 关键监控指标

```
业务指标：
- 订单成功率 > 99%
- 支付成功率 > 99.5%
- 积分计算准确率 = 100%（不容忍任何误差）
- 生日折扣限额准确率 = 100%
- 会员等级计算准确率 = 100%

技术指标：
- API响应时间 P95 < 500ms
- 错误率 < 0.1%
- 数据库查询时间 P95 < 200ms
- 小程序首屏加载 < 3秒
```

### 5.2 告警规则

```
CRITICAL告警（立即通知）：
- 积分计算出现误差
- 生日折扣限额被绕过
- 支付回调失败
- 数据库连接断开

WARNING告警（30分钟内处理）：
- API错误率 > 0.1%
- 响应时间 P95 > 1s
- 磁盘空间 < 20%

INFO告警（每日汇总）：
- 新注册会员数
- 订单量异常波动
- 积分兑换量异常
```
