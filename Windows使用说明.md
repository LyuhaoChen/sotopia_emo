# 🪟 Windows 系统使用 Sotopia 的完整指南

## ❗ 重要：Windows 系统的特殊问题

### 问题说明

您看到的错误：
```
AttributeError: module 'os' has no attribute 'fork'
```

**原因**：
- Sotopia 使用 **RQ (Redis Queue)** 来处理后台任务
- RQ 默认使用 `os.fork()` 创建工作进程
- **Windows 不支持 `fork()`**（这是 Unix/Linux 特有的功能）

### 解决方案

使用 **SimpleWorker** 替代默认的 Worker：
- ✅ Windows 兼容
- ✅ 不需要 `fork()`
- ⚠️ 性能可能稍慢（单线程处理）

---

## 🚀 快速开始（3 步）

### 方法 1：一键启动（推荐）✨

```powershell
# 一键启动所有服务（自动使用 SimpleWorker）
.\start_server_windows.ps1
```

这个脚本会自动：
1. ✅ 检查环境（Conda、Redis、API Key）
2. ✅ 启动 SimpleWorker（Windows 兼容）
3. ✅ 启动 FastAPI 服务器
4. ✅ 显示所有链接和状态
5. ✅ 持续监控服务状态

### 方法 2：手动启动

#### 步骤 1: 启动 Redis

```powershell
# 使用 Docker（推荐）
docker run -d -p 6379:6379 redis/redis-stack-server:latest
```

#### 步骤 2: 启动 RQ Worker (SimpleWorker)

```powershell
# 新建一个 PowerShell 窗口，运行：
conda activate sotopia

# 创建 worker.py
@'
from redis_om import get_redis_connection
from rq import SimpleWorker, Queue

redis_conn = get_redis_connection()
queue = Queue('default', connection=redis_conn)
worker = SimpleWorker([queue], connection=redis_conn)

print("✅ SimpleWorker started (Windows compatible)")
worker.work()
'@ | Out-File worker.py -Encoding UTF8

# 运行 worker
python worker.py
```

#### 步骤 3: 启动 FastAPI 服务器

```powershell
# 新建另一个 PowerShell 窗口，运行：
conda activate sotopia
$env:OPENAI_API_KEY = "sk-your-key-here"
fastapi run sotopia/api/fastapi_server.py --port 8800
```

---

## 📋 完整使用流程

### 1. 启动服务器

```powershell
# 方法 A: 一键启动（推荐）
.\start_server_windows.ps1

# 方法 B: 手动启动（见上面）
```

### 2. 验证服务器

```powershell
# 运行调试脚本
.\debug_api.ps1
```

应该看到：
```
✅ Health Check
✅ Redis: connected
✅ Database: available
✅ Worker: running (SimpleWorker)
```

### 3. 运行模拟

```powershell
# 快速测试
.\run_simple_simulation.ps1

# 完整模拟
.\run_sotopia_simulation.ps1
```

---

## 🔧 故障排除

### 问题 1: `os.fork()` 错误

```
AttributeError: module 'os' has no attribute 'fork'
```

**原因**: 使用了默认的 RQ Worker（需要 fork）

**解决**: 
1. 停止当前服务器
2. 使用 `.\start_server_windows.ps1`
3. 或手动启动 SimpleWorker（见上面步骤 2）

---

### 问题 2: Worker 没有处理任务

**症状**: 模拟一直不完成，没有消息

**解决**:
```powershell
# 1. 检查 worker 是否在运行
# 如果使用 start_server_windows.ps1，查看监控输出

# 2. 手动检查 Redis 队列
redis-cli
> LLEN rq:queue:default
# 应该返回待处理任务数

# 3. 重启 worker
# 停止并重新运行 start_server_windows.ps1
```

---

### 问题 3: Redis 连接失败

```
ConnectionError: Error connecting to Redis
```

**解决**:
```powershell
# 启动 Redis
docker run -d -p 6379:6379 redis/redis-stack-server:latest

# 验证
redis-cli ping
# 应该返回 PONG

# 如果还是失败，检查端口占用
netstat -ano | findstr :6379
```

---

### 问题 4: 模拟超时

**症状**: 等待 2-5 分钟后仍然没有结果

**可能原因**:
1. OpenAI API 响应慢
2. Worker 处理慢（SimpleWorker 是单线程）
3. 网络问题

**解决**:
```powershell
# 1. 查看 worker 日志
# 如果使用 start_server_windows.ps1，查看终端输出

# 2. 手动查询状态
$ep = Invoke-RestMethod -Uri "http://127.0.0.1:8800/episodes/pk/YOUR_EPISODE_ID"
$ep.messages.Count  # 查看消息数

# 3. 使用更短的对话
# 修改 max_turns = 6 (在模拟脚本中)
```

---

## ⚠️ Windows 特有限制

### 1. 性能

| 系统 | Worker 类型 | 性能 |
|------|-------------|------|
| Linux/Mac | Worker (fork) | ⚡ 快速（多进程） |
| **Windows** | **SimpleWorker** | 🐌 **较慢（单线程）** |

**影响**:
- 模拟可能需要更长时间
- 一次只能处理一个任务

**建议**:
- 使用 `gpt-4o-mini` 而不是 `gpt-4o`（更快）
- 减少 `max_turns`（如 8-12 轮而不是 20 轮）
- 一次运行一个模拟

### 2. 并发限制

```powershell
# ❌ Windows 不支持并发模拟
# 如果同时提交多个模拟请求，它们会排队

# ✅ 等待第一个完成后再提交下一个
```

---

## 📊 文件总览

| 文件 | 说明 | 适用系统 |
|------|------|----------|
| `start_server_windows.ps1` | **一键启动（Windows 专用）** | 🪟 **Windows** |
| `run_sotopia_simulation.ps1` | 完整模拟 | 🪟 Windows / 🍎 Mac / 🐧 Linux |
| `run_simple_simulation.ps1` | 快速测试 | 🪟 Windows / 🍎 Mac / 🐧 Linux |
| `debug_api.ps1` | 调试工具 | 🪟 Windows / 🍎 Mac / 🐧 Linux |
| `使用说明.md` | 通用文档 | 全平台 |
| `Windows使用说明.md` | **本文档** | 🪟 **Windows** |

---

## 💡 最佳实践（Windows）

### 1. 推荐配置

```powershell
# 模拟请求配置（针对 Windows 优化）
$simulationBody = @{
    env_id = $ENV_PK
    agent_ids = @($A1, $A2, $A3)
    models = @(
        "gpt-4o-mini",  # Agent 1 - 快速
        "gpt-4o-mini",  # Agent 2 - 快速
        "gpt-4o-mini",  # Agent 3 - 快速
        "gpt-4o-mini"   # Evaluator - 快速
    )
    max_turns = 10      # 不要太长
    tag = "test"
}
```

### 2. 启动顺序

```
1. Redis (Docker)
   ↓
2. RQ SimpleWorker
   ↓
3. FastAPI Server
   ↓
4. 运行模拟脚本
```

### 3. 监控服务

```powershell
# 如果使用 start_server_windows.ps1
# 您会看到实时状态：

[14:30:15] Worker: ✅ | API: ✅
[14:30:25] Worker: ✅ | API: ✅
...
```

---

## 🎯 检查清单

在运行模拟前：

- [ ] ✅ Redis 已启动 (`docker ps` 或 `redis-cli ping`)
- [ ] ✅ SimpleWorker 已运行（不是默认 Worker）
- [ ] ✅ FastAPI 服务器已启动 (http://127.0.0.1:8800/health)
- [ ] ✅ OpenAI API Key 已设置
- [ ] ✅ 使用 `gpt-4o-mini` 模型（快速）
- [ ] ✅ `max_turns` 设置为 8-12（合理）
- [ ] ✅ 网络连接正常

---

## 📞 常见问题速查

| 问题 | 快速解决 |
|------|----------|
| `os.fork()` 错误 | 使用 `start_server_windows.ps1` |
| Redis 连接失败 | `docker run -d -p 6379:6379 redis/redis-stack-server:latest` |
| Worker 不工作 | 确保使用 **SimpleWorker** 而不是 Worker |
| 模拟超时 | 减少 `max_turns`，使用 `gpt-4o-mini` |
| API Key 错误 | `$env:OPENAI_API_KEY = "sk-..."` |

---

## 🚀 现在开始！

```powershell
# 1. 一键启动
.\start_server_windows.ps1

# 等待看到 "服务器运行中"

# 2. 新开一个 PowerShell 窗口，运行模拟
.\run_simple_simulation.ps1

# 3. 查看结果！
```

---

## 📚 技术细节

### SimpleWorker vs Worker

| 特性 | Worker (默认) | SimpleWorker (Windows) |
|------|--------------|------------------------|
| 系统调用 | `os.fork()` | 普通线程 |
| 支持系统 | Linux/Mac | **Windows/Linux/Mac** |
| 性能 | ⚡ 快 | 🐌 慢 |
| 并发 | ✅ 多进程 | ❌ 单线程 |
| 适用场景 | 生产环境 | **开发/测试** |

### 为什么 Windows 不支持 fork？

- `fork()` 是 Unix 系统调用，复制整个进程
- Windows 使用不同的进程模型（CreateProcess）
- Python 的 `multiprocessing` 在 Windows 上使用 spawn 而不是 fork

---

**Windows 用户专属支持！** 🪟✨

有问题请参考 `使用说明.md` 或查看日志输出。

