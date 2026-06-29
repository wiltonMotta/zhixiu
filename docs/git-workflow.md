# 致秀小程序 - Git工作流手册

## 基本配置

```bash
# 用户信息
git config user.email "zhixiu-agent@github.com"
git config user.name "Zhixiu Agent"

# 提交策略（使用merge）
git config pull.rebase false

# 远程仓库
git remote add origin git@github.com:wiltonMotta/zhixiu.git
```

## 常用操作

### 1. 查看状态
```bash
git status
```

### 2. 添加文件
```bash
# 添加所有更改
git add .

# 添加指定文件
git add <file>
```

### 3. 提交更改
```bash
git commit -m "📝 description: commit message"
```

### 4. 推送到远程
```bash
# 首次推送
git push -u origin main

# 后续推送
git push
```

### 5. 拉取更新
```bash
git pull origin main
```

### 6. 查看历史
```bash
git log --oneline
git log --stat
```

## 提交规范

### 提交消息格式
```
[类型] 范围: 描述
```

### 类型说明
- `feat`: 新功能
- `fix`: 修复bug
- `docs`: 文档更新
- `style`: 代码格式
- `refactor`: 重构
- `test`: 测试相关
- `chore`: 构建/工具链

### 示例
```bash
git commit -m "feat: 实现用户注册功能"
git commit -m "fix: 修复积分计算错误"
git commit -m "docs: 更新API文档"
```

## 分支管理

### 创建新分支
```bash
git checkout -b feature/user-module
```

### 切换分支
```bash
git checkout main
git checkout feature/user-module
```

### 合并分支
```bash
git checkout main
git merge feature/user-module
```

## 忽略文件

以下文件/目录已被.gitignore忽略：
- `.env` (环境变量)
- `data/` (数据库文件)
- `node_modules/` (依赖包)
- `dist/` (构建产物)
- `*.log` (日志文件)

## 代理配置

项目通过代理访问GitHub:
```
http://scnkt47u2f:007dbce8@10.1.4.13:3120
```

SSH配置在~/.ssh/config中。
