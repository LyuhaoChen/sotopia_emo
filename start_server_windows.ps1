# ========================================
# Windows 兼容的 Sotopia 服务器启动脚本
# ========================================

Write-Host @"
╔═══════════════════════════════════════════════════════════╗
║     Sotopia 服务器启动 (Windows 兼容模式)                ║
╚═══════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# ========================================
# 1. 检查环境
# ========================================
Write-Host "`n[1/4] 检查环境..." -ForegroundColor Yellow

# 检查 Conda 环境
$condaEnv = $env:CONDA_DEFAULT_ENV
if ($condaEnv -eq "sotopia") {
    Write-Host "  ✅ Conda 环境: $condaEnv" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  当前不在 sotopia 环境" -ForegroundColor Yellow
    Write-Host "     请先运行: conda activate sotopia" -ForegroundColor Gray
    exit 1
}

# 检查 OpenAI API Key
if ([string]::IsNullOrEmpty($env:OPENAI_API_KEY)) {
    Write-Host "  ⚠️  OPENAI_API_KEY 未设置" -ForegroundColor Yellow
    $key = Read-Host "请输入您的 OpenAI API Key (或按 Ctrl+C 退出)"
    $env:OPENAI_API_KEY = $key
}
$keyPreview = $env:OPENAI_API_KEY.Substring(0, [Math]::Min(10, $env:OPENAI_API_KEY.Length)) + "..."
Write-Host "  ✅ OpenAI Key: $keyPreview" -ForegroundColor Green

# 检查 Redis
Write-Host "`n  检查 Redis 连接..." -ForegroundColor Gray
try {
    # 尝试连接 Redis
    $redisTest = Test-NetConnection -ComputerName localhost -Port 6379 -WarningAction SilentlyContinue
    if ($redisTest.TcpTestSucceeded) {
        Write-Host "  ✅ Redis 已运行" -ForegroundColor Green
    } else {
        throw "Redis not running"
    }
} catch {
    Write-Host "  ❌ Redis 未运行！" -ForegroundColor Red
    Write-Host "     请先启动 Redis:" -ForegroundColor Yellow
    Write-Host "     docker run -d -p 6379:6379 redis/redis-stack-server:latest" -ForegroundColor Gray
    exit 1
}

# ========================================
# 2. 启动 RQ Worker (SimpleWorker - Windows 兼容)
# ========================================
Write-Host "`n[2/4] 启动 RQ Worker (Windows 模式)..." -ForegroundColor Yellow

# 创建 worker 启动脚本
$workerScript = @'
import sys
from redis_om import get_redis_connection
from rq import SimpleWorker, Queue

print("🔧 Starting RQ SimpleWorker (Windows compatible)...")

redis_conn = get_redis_connection()
queue = Queue('default', connection=redis_conn)

# Use SimpleWorker instead of Worker (Windows compatible)
worker = SimpleWorker([queue], connection=redis_conn)

print("✅ Worker started successfully!")
print("   Queue: default")
print("   Mode: SimpleWorker (no fork)")
print("   Listening for jobs...")
print()

worker.work()
'@

# 保存临时脚本
$workerScript | Out-File -FilePath "temp_worker.py" -Encoding UTF8

# 在后台启动 worker
Write-Host "  启动后台 Worker..." -ForegroundColor Gray
$workerJob = Start-Job -ScriptBlock {
    param($pythonScript)
    Set-Location $using:PWD
    python $pythonScript
} -ArgumentList "temp_worker.py"

Start-Sleep -Seconds 2

# 检查 worker 状态
$workerState = $workerJob.State
if ($workerState -eq "Running") {
    Write-Host "  ✅ Worker 已启动 (Job ID: $($workerJob.Id))" -ForegroundColor Green
    Write-Host "     模式: SimpleWorker (Windows 兼容)" -ForegroundColor Gray
} else {
    Write-Host "  ❌ Worker 启动失败" -ForegroundColor Red
    Receive-Job -Job $workerJob
    exit 1
}

# ========================================
# 3. 启动 FastAPI 服务器
# ========================================
Write-Host "`n[3/4] 启动 FastAPI 服务器..." -ForegroundColor Yellow

Write-Host "  正在启动 API 服务器..." -ForegroundColor Gray
Write-Host "  端口: 8800" -ForegroundColor Gray
Write-Host "  模式: 开发服务器" -ForegroundColor Gray
Write-Host ""

# 在新窗口启动 FastAPI（这样可以看到日志）
$apiJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD
    $env:OPENAI_API_KEY = $using:env:OPENAI_API_KEY
    fastapi run sotopia/api/fastapi_server.py --port 8800
}

Start-Sleep -Seconds 5

# 检查 API 服务器
Write-Host "  检查 API 服务器..." -ForegroundColor Gray
$maxRetries = 10
$retryCount = 0
$apiReady = $false

while ($retryCount -lt $maxRetries) {
    try {
        $health = Invoke-RestMethod -Uri "http://127.0.0.1:8800/health" -Method GET -ErrorAction Stop
        if ($health.status -eq "healthy") {
            Write-Host "  ✅ API 服务器已启动" -ForegroundColor Green
            Write-Host "     Status: $($health.status)" -ForegroundColor Gray
            Write-Host "     Redis: $($health.components.redis)" -ForegroundColor Gray
            Write-Host "     Database: $($health.components.database)" -ForegroundColor Gray
            $apiReady = $true
            break
        }
    } catch {
        $retryCount++
        Write-Host "  等待中... ($retryCount/$maxRetries)" -ForegroundColor Gray
        Start-Sleep -Seconds 2
    }
}

if (-not $apiReady) {
    Write-Host "  ❌ API 服务器启动失败或超时" -ForegroundColor Red
    Write-Host "`n查看详细错误:" -ForegroundColor Yellow
    Receive-Job -Job $apiJob
    exit 1
}

# ========================================
# 4. 显示信息和控制台
# ========================================
Write-Host "`n[4/4] 服务器就绪！" -ForegroundColor Yellow

Write-Host @"

╔═══════════════════════════════════════════════════════════╗
║                 ✨ 服务器运行中 ✨                        ║
╚═══════════════════════════════════════════════════════════╝

📡 API 端点:
   • Health Check:  http://127.0.0.1:8800/health
   • API 文档:      http://127.0.0.1:8800/docs
   • ReDoc:         http://127.0.0.1:8800/redoc

🔧 后台任务:
   • RQ Worker:     Job ID $($workerJob.Id) (SimpleWorker - Windows 模式)
   • FastAPI:       Job ID $($apiJob.Id)

💡 快速测试:
   • 运行调试:      .\debug_api.ps1
   • 快速模拟:      .\run_simple_simulation.ps1
   • 完整模拟:      .\run_sotopia_simulation.ps1

⚠️  重要提示:
   • Windows 系统使用 SimpleWorker（无 fork 支持）
   • Worker 在后台运行，可能比 Linux 慢一些
   • 模拟任务会排队处理

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

"@ -ForegroundColor Cyan

# ========================================
# 5. 实时监控（可选）
# ========================================
Write-Host "按 Ctrl+C 停止所有服务并退出`n" -ForegroundColor Yellow

# 监控循环
try {
    while ($true) {
        Start-Sleep -Seconds 10
        
        # 检查 Worker 状态
        $wState = (Get-Job -Id $workerJob.Id).State
        $aState = (Get-Job -Id $apiJob.Id).State
        
        $timestamp = Get-Date -Format "HH:mm:ss"
        Write-Host "[$timestamp] Worker: " -NoNewline -ForegroundColor Gray
        
        if ($wState -eq "Running") {
            Write-Host "✅" -NoNewline -ForegroundColor Green
        } else {
            Write-Host "❌" -NoNewline -ForegroundColor Red
        }
        
        Write-Host " | API: " -NoNewline -ForegroundColor Gray
        
        if ($aState -eq "Running") {
            Write-Host "✅" -ForegroundColor Green
        } else {
            Write-Host "❌" -ForegroundColor Red
        }
        
        # 如果任一服务停止，退出
        if ($wState -ne "Running" -or $aState -ne "Running") {
            Write-Host "`n❌ 检测到服务停止！" -ForegroundColor Red
            break
        }
    }
} catch {
    Write-Host "`n`n⚠️  收到中断信号..." -ForegroundColor Yellow
} finally {
    # ========================================
    # 清理
    # ========================================
    Write-Host "`n正在停止服务..." -ForegroundColor Yellow
    
    # 停止 Jobs
    Write-Host "  停止 API 服务器..." -ForegroundColor Gray
    Stop-Job -Id $apiJob.Id -ErrorAction SilentlyContinue
    Remove-Job -Id $apiJob.Id -Force -ErrorAction SilentlyContinue
    
    Write-Host "  停止 Worker..." -ForegroundColor Gray
    Stop-Job -Id $workerJob.Id -ErrorAction SilentlyContinue
    Remove-Job -Id $workerJob.Id -Force -ErrorAction SilentlyContinue
    
    # 删除临时文件
    if (Test-Path "temp_worker.py") {
        Remove-Item "temp_worker.py" -Force
        Write-Host "  清理临时文件..." -ForegroundColor Gray
    }
    
    Write-Host "`n✅ 所有服务已停止" -ForegroundColor Green
    Write-Host "再见！👋`n" -ForegroundColor Cyan
}

