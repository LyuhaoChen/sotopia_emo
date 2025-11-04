# 🎭 Sotopia 三人对话模拟 - 快速指南

## 📁 文件说明

| 文件 | 用途 | 运行时间 |
|------|------|----------|
| `run_sotopia_simulation.ps1` | 完整的模拟流程（推荐） | 2-5 分钟 |
| `run_simple_simulation.ps1` | 快速测试版本 | 1-2 分钟 |
| `debug_api.ps1` | API 调试工具 | 10-20 秒 |
| `使用说明.md` | 详细文档 | - |

---

## 🚀 快速开始（3 步）

### 1️⃣ 启动服务器

```powershell
# 激活环境
conda activate sotopia

# 启动 API 服务器（新终端窗口）
fastapi run sotopia/api/fastapi_server.py --port 8800
```

### 2️⃣ 设置 API Key

```powershell
# 设置 OpenAI API Key
$env:OPENAI_API_KEY = "sk-your-api-key-here"
```

### 3️⃣ 运行模拟

```powershell
# 完整版（推荐）
.\run_sotopia_simulation.ps1

# 或快速测试
.\run_simple_simulation.ps1
```

**就这么简单！** 🎉

---

## 📊 输出示例

运行完成后，您会看到：

```
╔═══════════════════════════════════════════════════════════╗
║                   对话内容                                ║
╚═══════════════════════════════════════════════════════════╝

[1] Alice:
嗨，Bob 和 Carol！真巧在这里遇到你们。最近我在做一个很酷的项目...

[2] Bob:
Alice，真高兴见到你！说到项目，我最近在思考 AI 伦理问题...

[3] Carol:
太好了！说到 AI，我正在准备一个数字艺术展，想邀请你们来看...

...
```

同时生成两个文件：
- `episode_20250104_143022.json` - 完整数据
- `episode_20250104_143022.txt` - 易读版本

---

## 🔧 故障排除

### ❌ 问题：连接被拒绝

```
Invoke-RestMethod: Connection refused
```

**解决**：启动 API 服务器
```powershell
fastapi run sotopia/api/fastapi_server.py --port 8800
```

---

### ❌ 问题：Redis 错误

```
ERROR: Redis connection failed
```

**解决**：启动 Redis
```powershell
docker run -d -p 6379:6379 redis/redis-stack-server:latest
```

---

### ❌ 问题：OpenAI API Key 未设置

```
WARNING: OPENAI_API_KEY 未设置
```

**解决**：设置环境变量
```powershell
$env:OPENAI_API_KEY = "sk-your-key-here"
```

---

### ⏱️ 问题：模拟超时

**解决**：手动查询结果
```powershell
# 运行调试工具
.\debug_api.ps1

# 或手动查询
$episodes = Invoke-RestMethod -Uri "http://127.0.0.1:8800/episodes"
$episodes | Format-Table
```

---

## 🎯 使用场景

### 1. 快速测试 API

```powershell
# 1. 检查环境
.\debug_api.ps1

# 2. 快速测试
.\run_simple_simulation.ps1
```

**用时**: 2 分钟

---

### 2. 正式运行模拟

```powershell
# 运行完整版
.\run_sotopia_simulation.ps1
```

**用时**: 3-5 分钟

---

### 3. 查看历史记录

```powershell
# 运行调试工具
.\debug_api.ps1

# 或手动查询
$all = Invoke-RestMethod -Uri "http://127.0.0.1:8800/episodes"
$all | Format-Table pk, tag, @{Name="消息数";Expression={$_.messages.Count}}
```

---

## 📝 自定义场景

### 修改 `run_sotopia_simulation.ps1`

找到这一段：

```powershell
$scenarioBody = @{
    codename = "coffee_shop_chat"
    scenario = "三个朋友在咖啡店偶然相遇..."
    agent_goals = @(
        "Alice: 分享工作进展",
        "Bob: 询问 AI 话题",
        "Carol: 邀请参加活动"
    )
}
```

修改为您的场景：

```powershell
$scenarioBody = @{
    codename = "office_meeting"
    scenario = "三个同事在会议室讨论新项目"
    agent_goals = @(
        "Alice: 提出技术方案",
        "Bob: 评估项目风险",
        "Carol: 设计用户界面"
    )
}
```

---

## 📚 完整文档

查看 `使用说明.md` 获取：
- ✅ 详细的 API 端点说明
- ✅ 完整的数据结构
- ✅ 逐步操作指南
- ✅ 常见问题解答

---

## 🎨 进阶用法

### 1. 使用不同模型

```powershell
# 修改 models 参数
models = @("gpt-4o", "gpt-4o", "gpt-4o", "gpt-4o")  # 高质量
models = @("gpt-4o-mini", "gpt-4o-mini", "gpt-4o-mini", "gpt-4o-mini")  # 快速
```

### 2. 调整对话长度

```powershell
# 修改 max_turns 参数
max_turns = 8   # 短对话
max_turns = 15  # 中等长度
max_turns = 30  # 深度对话
```

### 3. 自定义 Agent 性格

```powershell
$agent1Body = @{
    first_name = "Alice"
    personality_traits = @("analytical", "decisive", "innovative")
    big_five_personality = @(
        "high_openness",
        "high_conscientiousness",
        "medium_extraversion",
        "low_agreeableness",
        "low_neuroticism"
    )
}
```

---

## 🔗 有用的链接

- **API 文档**: http://127.0.0.1:8800/docs
- **Health Check**: http://127.0.0.1:8800/health
- **详细文档**: `使用说明.md`

---

## ✅ 检查清单

运行前请确保：

- [ ] Conda 环境已激活 (`conda activate sotopia`)
- [ ] Redis 服务器已启动
- [ ] FastAPI 服务器已启动 (端口 8800)
- [ ] OpenAI API Key 已设置
- [ ] 网络连接正常

---

## 💬 示例对话主题

试试这些场景：

1. **商务会议**: 讨论新产品发布策略
2. **学术讨论**: 辩论 AI 伦理问题
3. **朋友聚会**: 计划周末旅行
4. **创意工作坊**: 头脑风暴新想法
5. **客户服务**: 处理客户投诉

---

**准备好了吗？开始运行吧！** 🚀

```powershell
.\run_sotopia_simulation.ps1
```

