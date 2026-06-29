# 对话记录 #001 — 基础设施替代方案 / 开发顺序 / 多Agent协同Loop设计

> 日期：2026-06-29
> 主题：三个问题 — ①超算容器替代腾讯云 ②无账号开发调试顺序 ③多Agent Loop工程方案

---

## 问题1：用国家超算互联网Notebook替代腾讯云全家桶，可行吗？

### 用户前提
- 拥有国家超算互联网Notebook容器，配置：显存80GB、CPU 2×7390 32C（分配7核心）、内存245GB
- 认为腾讯云服务器/数据库/缓存/对象存储成本偏高
- 希望在该容器上手动部署全部后端服务

### 结论：✅ 完全可行，且性能远超需求

#### 资源对比

| 资源 | 超算容器 | 腾讯云轻量 2核4G | 腾讯云数据库 1核2G | 评估 |
|------|---------|-----------------|-------------------|------|
| CPU | 7核 (2×7390) | 2核 | 1核 | **超算碾压** |
| 内存 | 245GB | 4GB | 2GB | **超算碾压** |
| 磁盘 | 未说明（假设≥100GB） | 80GB SSD | 20GB | 需确认 |
| 显存 | 80GB | 无 | 无 | 额外能力 |
| 网络 | 需确认公网可达性 | 公网4Mbps | 内网 | **⚠️ 关键风险点** |

#### 可行性分析

**✅ 可以部署的服务**：

| 服务 | 方案 | 说明 |
|------|------|------|
| NestJS后端 | Docker / 直接运行 | 7核CPU运行Node.js绰绰有余 |
| PostgreSQL | Docker自建 | 245GB内存，pg可以分配4GB shared_buffers |
| Redis | Docker自建 | 分配1GB内存做缓存，性能远超256MB云版 |
| MinIO（替代COS） | Docker自建 | S3兼容的对象存储，完全替代腾讯云COS |
| Nginx | Docker | 反向代理 + SSL终止 |
| 后台管理前端 | Docker / 静态文件 | Nginx托管 |

**⚠️ 必须确认的关键问题**：

| 问题 | 风险等级 | 说明 | 解决方案 |
|------|---------|------|---------|
| 公网IP可达性 | 🔴 致命 | 微信小程序回调需要公网可达的HTTPS URL | ①确认容器是否有公网IP ②如无，使用frp/ngrok内网穿透 ③最终上线仍需公网服务器 |
| 域名绑定 | 🟡 重要 | ICP备案需要域名指向国内服务器 | 超算容器是否允许绑定自有域名？ |
| ICP备案 | 🔴 致命 | 微信小程序强制要求备案域名 | 超算IP是否可以备案？通常只有云服务商才能备案 |
| 容器持久化 | 🟡 重要 | 容器重启后数据是否保留 | 需确认存储持久化方案 |
| 端口开放 | 🟡 重要 | 80/443端口是否对外开放 | 需确认网络策略 |
| 数据安全 | 🟡 重要 | 超算平台的数据安全等级 | 商业客户数据存储合规性 |

#### 推荐策略：超算开发 + 轻量服务器上线

```
开发/测试阶段（0成本）：
┌─────────────────────────────────────────────┐
│          国家超算互联网 Notebook              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │ NestJS   │ │PostgreSQL│ │  Redis   │    │
│  │  后端    │ │  数据库  │ │  缓存    │    │
│  └──────────┘ └──────────┘ └──────────┘    │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │  MinIO   │ │  Nginx   │ │  Admin   │    │
│  │ 对象存储 │ │ 反向代理 │ │  前端    │    │
│  └──────────┘ └──────────┘ └──────────┘    │
│                                             │
│  Docker Compose 一键编排                     │
│  通过内网穿透(frp)提供外部访问               │
└─────────────────────────────────────────────┘

上线阶段（仅域名+最轻量服务器）：
┌─────────────────────────────────────────────┐
│        腾讯云轻量服务器 2核4G（仅跑API）      │
│  ┌──────────┐ ┌──────────┐                  │
│  │ NestJS   │ │  Nginx   │                  │
│  │  后端    │ │ + SSL    │                  │
│  └──────────┘ └──────────┘                  │
│  域名备案 → 绑定此服务器                     │
└─────────────────────────────────────────────┘
│
│ 数据库/缓存/存储仍可部署在超算容器
│ 通过内网穿透或VPN连接
│
│ 或者：上线时也在轻量服务器上Docker部署全套
│ 仅约2,136元/年
```

#### 超算容器 Docker Compose 部署方案

```yaml
# docker-compose.yml — 超算容器一键部署
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: zhixiu
      POSTGRES_USER: zhixiu
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    command: >
      postgres
        -c shared_buffers=2GB
        -c effective_cache_size=6GB
        -c max_connections=200

  redis:
    image: redis:7-alpine
    command: redis-server --requirepass ${REDIS_PASSWORD} --maxmemory 1gb --maxmemory-policy allkeys-lru
    volumes:
      - redisdata:/data
    ports:
      - "6379:6379"

  minio:
    image: minio/minio:latest
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: ${MINIO_ACCESS_KEY}
      MINIO_ROOT_PASSWORD: ${MINIO_SECRET_KEY}
    volumes:
      - miniodata:/data
    ports:
      - "9000:9000"   # S3 API
      - "9001:9001"   # 管理控制台

  server:
    build: ./server
    environment:
      DATABASE_URL: postgresql://zhixiu:${DB_PASSWORD}@postgres:5432/zhixiu
      REDIS_URL: redis://:${REDIS_PASSWORD}@redis:6379
      S3_ENDPOINT: http://minio:9000
      S3_ACCESS_KEY: ${MINIO_ACCESS_KEY}
      S3_SECRET_KEY: ${MINIO_SECRET_KEY}
      S3_BUCKET: zhixiu-assets
    ports:
      - "3000:3000"
    depends_on:
      - postgres
      - redis
      - minio

  admin:
    build: ./admin
    ports:
      - "3001:80"

  nginx:
    image: nginx:alpine
    volumes:
      - ./infra/nginx.conf:/etc/nginx/nginx.conf
      - ./infra/ssl:/etc/nginx/ssl  # SSL证书目录
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - server
      - admin

volumes:
  pgdata:
  redisdata:
  miniodata:
```

#### 成本重新核算（超算方案）

| 项目 | 费用 | 说明 |
|------|------|------|
| 超算容器 | 0元（已有） | 含DB/Redis/MinIO |
| 域名 | 55-70元/年 | 必须购买 |
| ICP备案 | 0元 | 自行备案 |
| SSL证书 | 0元 | 免费DV证书 |
| 微信认证 | 300元/年 | 必须 |
| 微信支付手续费 | 按交易额 | 不可避免 |
| **合计** | **约 355元/年** | 💰 对比腾讯云方案省6,370元/年 |

> ⚠️ 上线时如需独立公网服务器，增加轻量服务器 2,136元/年
> 即使加上，总计也仅约 2,491元/年，仍省 4,234元/年

#### MinIO 替代 COS 的兼容性说明

| 功能 | 腾讯云COS | MinIO | 兼容性 |
|------|----------|-------|--------|
| S3 API | 支持 | 原生支持 | ✅ 100%兼容 |
| 图片处理（裁剪/压缩） | 云端处理 | 需自建（Sharp/GM） | ⚠️ 需额外开发 |
| CDN加速 | 内置 | 需自建或配合CDN | ⚠️ 小程序场景流量小，可忽略 |
| 小程序downloadFile域名 | cos.myqcloud.com | 自定义域名 | ✅ 配置自定义域名即可 |
| 持久化 | 云端保障 | Docker Volume | ⚠️ 需定期备份 |

---

## 问题2：无微信账号时的开发调试方案 + 项目推进顺序

### 核心结论：先开发后注册，开发调试完全不需要微信账号

微信官方提供了完整的"开发版"调试能力，在未注册小程序账号的情况下，可以通过以下方式开发：

### 2.1 开发阶段可用的调试方式

| 阶段 | 调试方式 | 是否需要账号 | 说明 |
|------|---------|------------|------|
| UI开发 | 微信开发者工具 → 本地预览 | ❌ 不需要 | 使用测试AppID即可 |
| API开发 | 本地NestJS + 本地数据库 | ❌ 不需要 | Docker Compose本地运行 |
| 联调测试 | 微信开发者工具 → 本地后端 | ❌ 不需要 | 开发者工具不校验域名 |
| 真机预览 | 微信开发者工具 → 预览二维码 | ⚠️ 需要AppID | 注册后才能真机预览 |
| 微信登录 | wx.login() → 后端换session | ⚠️ 需要AppID+Secret | 注册后才能调试 |
| 微信支付 | JSAPI支付 | 🔴 需要商户号 | 最后阶段才需要 |
| 真机体验版 | 扫码体验 | ⚠️ 需要AppID | 注册后才能发布体验版 |

**关键技巧**：
1. 微信开发者工具中，**不填AppID**也能创建项目（使用测试号），可以正常开发UI和逻辑
2. 开发者工具中勾选 **"不校验合法域名"**，可以直接请求localhost后端
3. 微信登录可以先Mock，用固定的openid进行开发
4. 支付功能最后接入，先用模拟支付

### 2.2 项目推进先后顺序（优化版）

```
═══════════════════════════════════════════════════════════════
 Phase 0: 纯本地开发（不需要任何微信账号，0成本）
═══════════════════════════════════════════════════════════════

 Week 1: 🏗️ 基础设施搭建
   ├── [AI] 在超算容器上部署Docker Compose环境
   │   ├── PostgreSQL 16
   │   ├── Redis 7
   │   ├── MinIO (对象存储)
   │   └── Nginx + SSL(自签证书)
   ├── [AI] 初始化NestJS项目 + Prisma
   ├── [AI] 设计并创建数据库Schema
   ├── [AI] 设计API接口文档(OpenAPI 3.0)
   └── [AI] 初始化微信小程序项目（使用测试AppID）

 Week 2-3: 🔧 后端核心模块开发
   ├── [AI] Auth模块（Mock微信登录）
   ├── [AI] Brand品牌模块
   ├── [AI] Member会员模块 + 生日锁定[CRITICAL-1]
   ├── [AI] Product商品模块 + 四类屏蔽[CRITICAL-2]
   ├── [AI] RiskControl风控引擎
   └── [AI] 风控专项单元测试（40+用例）

 Week 3-4: 🔧 后端业务模块 + 前端开发
   ├── [AI] Order订单模块 + 生日限购[CRITICAL-3]
   ├── [AI] Points积分模块 + 实付积分[CRITICAL-4] + 滚动清零[CRITICAL-6]
   ├── [AI] Coupon卡券模块 + 券仅线下[CRITICAL-7]
   ├── [AI] 小程序4个Tab页面开发（开发者工具本地预览）
   ├── [AI] 后台管理前端开发
   └── [AI] 积分商城双模式[CRITICAL-8]

 Week 4-5: 🧪 集成测试与优化
   ├── [AI] 端到端测试（全链路）
   ├── [AI] 风控逻辑全面验证
   ├── [AI] 性能优化
   ├── [AI] UI适配中老年
   └── [AI] 代码审查 + 修复

═══════════════════════════════════════════════════════════════
 Phase 1: 注册微信账号（需要人工操作，与Phase 0并行启动）
═══════════════════════════════════════════════════════════════

 👤 Week 1 同时启动（人工操作）：
   ├── [人] 准备营业执照、法人身份证、对公账户
   ├── [人] 注册微信小程序账号 → 获取 AppID
   ├── [人] 完成微信认证（300元，1-5工作日）
   ├── [人] 申请微信支付商户号（1-5工作日）
   └── [人] 购买域名 + 启动ICP备案（⚠️最长20天）

 👤 Week 2-3 继续：
   ├── [人] ICP备案等待中...（与开发并行）
   ├── [人] 获取微信小程序 AppID + AppSecret
   ├── [人] 获取微信支付商户号 + API密钥 + 证书
   ├── [人] 准备品牌Logo/VI素材
   └── [人] 准备商品数据Excel

═══════════════════════════════════════════════════════════════
 Phase 2: 微信能力接入（需要Phase 0 + Phase 1 的产出）
═══════════════════════════════════════════════════════════════

 Week 5-6: 🔗 微信集成
   ├── [AI+人] 替换Mock登录 → 真实微信登录
   │   └── 人提供AppID+AppSecret → AI替换配置
   ├── [AI+人] 接入微信支付V3
   │   └── 人提供商户号+密钥+证书 → AI接入代码
   ├── [AI] 真机预览测试（用AppID创建体验版）
   ├── [人] ICP备案通过 → 配置服务器域名
   ├── [人] 申请订阅消息模板
   └── [AI] 1分钱支付端到端验证

═══════════════════════════════════════════════════════════════
 Phase 3: 上线发布（人工为主）
═══════════════════════════════════════════════════════════════

 Week 6-7: 🚀 上线
   ├── [人] 确认隐私政策+用户协议
   ├── [AI] 运营Agent录入商品数据
   ├── [AI] 上传小程序代码到微信平台
   ├── [人] 提交审核
   ├── [人] 审核通过 → 发布上线
   ├── [人] 门店张贴小程序码
   └── [人] 线下消费录入验证

═══════════════════════════════════════════════════════════════
```

### 2.3 开发顺序依赖图（Mermaid风格）

```
Phase 0（纯本地，0成本）         Phase 1（人工注册，并行）
─────────────────────         ──────────────────────
DB Schema ─→ Auth(Mock)       注册小程序 → AppID
    │                              │
    ├──→ Brand                    申请认证 → AppSecret
    │      │                       │
    ├──→ Member ──→ Product       申请支付 → 商户号+密钥
    │      │          │            │
    │      ├──→ Order             购买域名 → ICP备案
    │      │      │                │
    │      │      ├──→ Points     等待备案...(最长20天)
    │      │      │                    │
    │      ├──→ Coupon ◄──────────────┘
    │      │      │
    │      │      └──→ Payment (需商户号)
    │      │
    ├──→ Notification (需模板ID)
    │
    ├──→ 小程序前端 (本地预览)
    ├──→ 后台管理前端
    └──→ 集成测试
              │
              ▼
        Phase 2: 微信能力接入
        ──────────────────────
        真实登录 + 真实支付 + 真机调试
              │
              ▼
        Phase 3: 上线发布
```

---

## 问题3：多Agent协同Loop工程设计方案

### 3.1 什么是Loop工程？

Loop工程（Agentic Loop）是AI Agent领域的核心设计模式：Agent不是单次调用，而是在一个**循环**中持续"思考→行动→观察→调整"，直到任务完成。近期由Anthropic、OpenAI、LangChain等大力推动。

**核心原理**：
```
┌─────────────────────────────────────┐
│           Agent Loop                │
│                                     │
│   ┌───→ Think ───→ Act ───┐        │
│   │                         │        │
│   │    Observe ←────────────┘        │
│   │         │                        │
│   └─── Not Done? ── Yes ────────────┘
│              │                      
│              No → Done → Output     
└─────────────────────────────────────┘
```

### 3.2 多Agent Loop设计 — 致秀项目最优方案

#### 总体架构：Orchestrator Loop + Worker Loops

```
┌──────────────────────────────────────────────────────┐
│                  Orchestrator Loop                     │
│              (产品经理Agent 主控循环)                   │
│                                                       │
│   Think: 分析当前进度，决定下一步委派哪个Agent          │
│   Act:   创建Task，分配给Worker Agent                  │
│   Observe: 收集Worker返回结果，更新项目状态             │
│   Loop:  直到所有Epic完成                              │
│                                                       │
│   ┌─────────────┬──────────────┬──────────────┐      │
│   │             │              │              │      │
│   ▼             ▼              ▼              ▼      │
│ Backend     Frontend       Test         Review       │
│  Loop        Loop          Loop          Loop        │
│ (后端Agent)  (前端Agent)   (测试Agent)   (审查Agent)  │
└──────────────────────────────────────────────────────┘
```

#### 3.2.1 Orchestrator Loop（主控循环）

**角色**: 产品经理Agent
**模型**: Claude Sonnet 4
**职责**: 任务分解、委派、进度跟踪、冲突解决

```python
# 伪代码 — Orchestrator Loop

class OrchestratorLoop:
    def __init__(self, prd, project_state):
        self.prd = prd                              # PRD文档
        self.state = project_state                   # 项目状态
        self.epics = self.decompose_prd(prd)         # 拆解为Epic列表
        self.agents = {
            'architect': ArchitectAgent(),
            'backend':   BackendAgent(),
            'frontend':  FrontendAgent(),
            'test':      TestAgent(),
            'review':    ReviewAgent(),
            'devops':    DevOpsAgent(),
        }
    
    def run(self):
        """主控Loop — 持续运行直到项目完成"""
        while not self.all_epics_done():
            
            # 1. Think — 分析当前状态，决定下一步
            next_tasks = self.plan_next_tasks()
            
            # 2. Act — 将任务委派给对应的Worker Agent
            for task in next_tasks:
                agent = self.select_agent(task)
                result = agent.execute(task)  # 每个Agent内部也是一个Loop
                
                # 3. Observe — 收集结果，更新状态
                self.update_state(task, result)
                
                # 4. 判断是否需要调整
                if result.status == 'BLOCKED':
                    self.resolve_blocker(task, result)
                elif result.status == 'FAILED':
                    self.retry_with_context(task, result)
        
        return self.state  # 项目完成

    def plan_next_tasks(self):
        """基于依赖关系和当前进度，规划下一批可执行任务"""
        ready_tasks = []
        for epic in self.epics:
            if epic.status == 'DONE':
                continue
            for task in epic.tasks:
                if task.status == 'TODO' and self.dependencies_met(task):
                    ready_tasks.append(task)
        # 按优先级排序：风控相关 > 核心 > 辅助
        return sorted(ready_tasks, key=lambda t: t.priority)
```

#### 3.2.2 Worker Loop（每个Agent的内部循环）

每个Worker Agent内部也是一个Loop：

```python
class WorkerLoop:
    def __init__(self, agent_config):
        self.model = agent_config.model
        self.tools = agent_config.tools
        self.max_iterations = 10  # 防止无限循环
    
    def execute(self, task):
        """Worker内部Loop — 持续执行直到任务完成或失败"""
        context = self.build_context(task)
        
        for i in range(self.max_iterations):
            # 1. Think — LLM推理
            thought = self.llm.think(context, task)
            
            # 2. Act — 调用工具（写代码/运行测试/查询DB等）
            action_result = self.execute_action(thought.action)
            
            # 3. Observe — 观察结果
            context = self.update_context(context, action_result)
            
            # 4. 判断是否完成
            if self.is_task_complete(task, context):
                return TaskResult(status='DONE', output=context.summary())
            
            if self.is_blocked(action_result):
                return TaskResult(status='BLOCKED', blocker=action_result.error)
        
        return TaskResult(status='FAILED', reason='Max iterations reached')
```

#### 3.2.3 致秀项目的具体Loop设计方案

**方案：Claude Code + 自定义Orchestrator脚本**

不依赖第三方框架（LangGraph/CrewAI等），直接使用Claude Code作为Worker执行器，用Python脚本做Orchestrator。

```
项目根目录/
├── loop/
│   ├── orchestrator.py          # 主控Loop脚本
│   ├── agents/
│   │   ├── architect.py         # 架构师Agent定义
│   │   ├── backend.py           # 后端Agent定义
│   │   ├── frontend.py          # 前端Agent定义
│   │   ├── test.py              # 测试Agent定义
│   │   └── review.py           # 审查Agent定义
│   ├── tasks/
│   │   ├── epics.yaml           # Epic定义（由PM Agent生成）
│   │   └── state.json           # 项目状态跟踪
│   ├── prompts/
│   │   ├── architect.md         # 架构师System Prompt
│   │   ├── backend.md           # 后端System Prompt
│   │   └── ...
│   └── config.yaml              # Loop配置（模型/工具/限制等）
```

**config.yaml**:
```yaml
# Loop配置
loop:
  max_iterations: 50              # Orchestrator最大迭代次数
  worker_max_iterations: 10       # 每个Worker最大迭代次数
  parallel_workers: 2             # 并行Worker数量（避免冲突）
  
agents:
  architect:
    model: claude-opus-4-20250115
    system_prompt: prompts/architect.md
    tools: [read, write, bash, prisma]
    
  backend:
    model: claude-sonnet-4-20250514
    system_prompt: prompts/backend.md
    tools: [read, write, bash, prisma, npm, jest]
    working_dir: ./server
    
  frontend:
    model: claude-sonnet-4-20250514
    system_prompt: prompts/frontend.md
    tools: [read, write, bash, npm]
    working_dir: ./miniprogram
    
  test:
    model: claude-sonnet-4-20250514
    system_prompt: prompts/test.md
    tools: [read, write, bash, npm, jest]
    working_dir: ./server
    
  review:
    model: claude-opus-4-20250115
    system_prompt: prompts/review.md
    tools: [read, bash, github]

epics:
  - id: epic-001
    name: "数据库与架构设计"
    agent: architect
    tasks:
      - id: task-001-1
        name: "设计Prisma Schema"
        priority: CRITICAL
        dependencies: []
      - id: task-001-2
        name: "设计API接口文档"
        priority: HIGH
        dependencies: [task-001-1]
        
  - id: epic-002
    name: "后端核心模块"
    agent: backend
    tasks:
      - id: task-002-1
        name: "Auth模块（Mock登录）"
        priority: HIGH
        dependencies: [task-001-1]
      - id: task-002-2
        name: "Member模块 + CRITICAL-1"
        priority: CRITICAL
        dependencies: [task-002-1]
      # ... 更多任务

  - id: epic-003
    name: "风控测试"
    agent: test
    tasks:
      - id: task-003-1
        name: "CRITICAL-1~8 测试用例"
        priority: CRITICAL
        dependencies: [task-002-2]  # 依赖后端模块开发完
```

#### 3.2.4 Loop执行的完整流程

```
Step 1: 启动Orchestrator
  $ python loop/orchestrator.py --config loop/config.yaml

Step 2: Orchestrator读取epics.yaml，初始化state.json
  state = {
    "epic-001": { status: "IN_PROGRESS", current_task: "task-001-1" },
    "epic-002": { status: "BLOCKED", blocker: "waiting for epic-001" },
    ...
  }

Step 3: 选择可执行的任务
  → task-001-1 (设计Prisma Schema)，无依赖，分配给architect

Step 4: 调用Claude Code作为Worker
  $ claude --model claude-opus-4 \
    --system-prompt loop/prompts/architect.md \
    --task "设计完整的Prisma Schema，包含以下模型：Member, Brand, Product, Order, PointsRecord, Coupon..."

Step 5: Worker Loop内部执行
  Think: 需要设计8个核心模型 + 关联关系
  Act:   写入 prisma/schema.prisma
  Observe: 运行 npx prisma validate → 通过
  Think: 需要添加索引和触发器
  Act:   修改schema添加@@index
  Observe: npx prisma validate → 通过
  Done:  返回结果

Step 6: Orchestrator更新状态
  state["epic-001"]["task-001-1"] = { status: "DONE", output: "prisma/schema.prisma" }
  state["epic-001"]["current_task"] = "task-001-2"

Step 7: 继续下一个任务
  → task-001-2 (设计API接口文档)
  ...

Step 8: 当epic-001完成后，解锁epic-002
  → 分配task-002-1给backend agent
  → 同时分配task-002-1的测试给test agent（并行）

... 持续Loop直到所有Epic完成
```

#### 3.2.5 实际落地的两种方式

**方式A：纯Claude Code手动Loop（最简单，推荐起步）**

不需要写Orchestrator脚本，直接用人脑做Orchestrator，通过Claude Code CLI逐个执行任务：

```bash
# 1. 架构师Agent — 设计数据库
claude "根据PRD设计完整的Prisma Schema，包含8条风控规则的数据模型支持"

# 2. 后端Agent — 开发模块
claude "根据prisma/schema.prisma开发Member模块，实现CRITICAL-1生日锁定规则"

# 3. 测试Agent — 写测试
claude "为MemberService编写测试用例，覆盖CRITICAL-1生日锁定规则的全部5个维度"

# 4. 审查Agent — 代码审查
claude "审查src/modules/member/下的代码，检查CRITICAL-1规则是否正确实现"

# 5. 人工确认 → 继续下一个模块
```

优点：零配置，立刻开始
缺点：需要人工协调任务顺序

**方式B：Claude Code + GitHub Issues自动化Loop（推荐生产）**

利用GitHub Issues + Actions实现自动化的多Agent Loop：

```
工作流：
1. PM Agent在GitHub创建Issue（自动或手动触发）
   Issue #1: [epic-001] 设计Prisma Schema
   Issue #2: [epic-002] 开发Member模块

2. GitHub Action触发Claude Code
   on:
     issues:
       types: [assigned, labeled]
   
3. Claude Code读取Issue描述，执行任务
4. Claude Code创建PR，关联Issue
5. Review Agent自动审查PR
6. 审查通过 → 自动合并 → 关闭Issue
7. 下一个依赖的Issue自动解锁
```

**GitHub Actions Workflow**:
```yaml
# .github/workflows/agent-loop.yml
name: Agent Loop

on:
  issues:
    types: [assigned]
  pull_request:
    types: [opened, synchronize]

jobs:
  agent-execute:
    if: github.event_name == 'issues'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Read Issue Task
        id: task
        run: |
          echo "title=${{ github.event.issue.title }}" >> $GITHUB_OUTPUT
          echo "body=${{ github.event.issue.body }}" >> $GITHUB_OUTPUT
          
      - name: Determine Agent Type
        id: agent
        run: |
          TITLE="${{ steps.task.outputs.title }}"
          if [[ "$TITLE" == *"[architect]"* ]]; then
            echo "model=claude-opus-4" >> $GITHUB_OUTPUT
            echo "prompt=loop/prompts/architect.md" >> $GITHUB_OUTPUT
          elif [[ "$TITLE" == *"[backend]"* ]]; then
            echo "model=claude-sonnet-4" >> $GITHUB_OUTPUT
            echo "prompt=loop/prompts/backend.md" >> $GITHUB_OUTPUT
          # ... 其他Agent类型
          fi
      
      - name: Execute Agent
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          # 调用Claude API执行任务
          claude --model ${{ steps.agent.outputs.model }} \
                 --system-prompt ${{ steps.agent.outputs.prompt }} \
                 --task "${{ steps.task.outputs.body }}"
      
      - name: Create Pull Request
        run: |
          # 自动创建PR
          git checkout -b agent/${{ github.event.issue.number }}
          git add -A
          git commit -m "[agent] ${{ steps.task.outputs.title }}"
          git push origin agent/${{ github.event.issue.number }}
          gh pr create --title "[agent] ${{ steps.task.outputs.title }}" \
                       --body "Closes #${{ github.event.issue.number }}"

  agent-review:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Review PR
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          claude --model claude-opus-4 \
                 --system-prompt loop/prompts/review.md \
                 --task "审查PR #${{ github.event.pull_request.number }} 的代码变更"
      
      - name: Auto-merge if approved
        run: |
          # 如果审查通过，自动合并
          gh pr merge --auto --squash
```

#### 3.2.6 Loop的风控保障机制

```
┌─────────────────────────────────────────────────────┐
│              风控Loop（始终运行）                      │
│                                                     │
│   Every Commit:                                     │
│   ├── 风控规则检查：8条CRITICAL规则是否在代码中存在    │
│   ├── 金额精度检查：是否使用整数（分）                │
│   ├── 生日锁定检查：是否在update DTO中排除了birthday  │
│   └── 测试覆盖率：风控相关是否≥95%                   │
│                                                     │
│   Every PR:                                         │
│   ├── 审查Agent自动审查                              │
│   ├── CI自动运行风控专项测试                         │
│   └── 不通过则自动打回，附带修改建议                  │
│                                                     │
│   Every Release:                                    │
│   ├── 全量风控回归测试                               │
│   ├── 1分钱支付验证                                  │
│   └── 人工确认后才能发布                             │
└─────────────────────────────────────────────────────┘
```

### 3.3 三种Loop方案对比

| 维度 | 方式A：手动Loop | 方式B：GitHub Loop | 方式C：LangGraph |
|------|---------------|-------------------|-----------------|
| 复杂度 | ⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| 上手成本 | 0 | 中等 | 高 |
| 自动化程度 | 低 | 高 | 最高 |
| 可控性 | 最高 | 高 | 中 |
| 适合阶段 | 起步/原型 | 正式开发 | 大规模团队 |
| 依赖 | 仅Claude Code | GitHub+Actions | LangGraph+额外部署 |
| **推荐** | **✅ 当前阶段** | **✅ 正式开发后** | 未来可选 |

### 3.4 推荐的落地路径

```
Step 1（本周）：手动Loop
  → 用Claude Code直接执行，人做Orchestrator
  → 快速验证开发流程和风控逻辑

Step 2（开发中期）：GitHub Loop
  → 将任务拆为GitHub Issues
  → 配置Actions自动触发Agent
  → 代码审查自动化

Step 3（稳定运营后）：自定义Orchestrator
  → 编写Python Orchestrator脚本
  → 多Agent自动调度
  → 运营Agent自动执行日常任务
```

---

## 总结

| 问题 | 核心结论 |
|------|---------|
| 超算容器替代腾讯云 | ✅ 完全可行，245GB内存+7核CPU远超需求；⚠️ 关键风险是公网可达性和ICP备案；建议开发阶段用超算，上线阶段用轻量服务器(2,136元/年) |
| 无账号开发调试 | ✅ 微信开发者工具使用测试AppID即可开发；勾选"不校验域名"可请求localhost；Mock登录+模拟支付可在注册前完成95%的开发工作 |
| 多Agent Loop方案 | 推荐三步走：手动Loop(Claude Code)→ GitHub Loop(Actions)→ 自定义Orchestrator；当前阶段直接用Claude Code手动Loop最快落地 |

---

## 需要确认的待办事项

- [ ] 确认超算容器的公网IP/端口开放情况
- [ ] 确认超算容器的磁盘空间和持久化方案
- [ ] 确认超算容器是否允许绑定自定义域名
- [ ] 确认超算容器是否支持Docker
- [ ] 开始准备营业执照等微信注册材料
- [ ] 购买域名并启动ICP备案（越早越好）
