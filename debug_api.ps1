# ========================================
# API 调试工具
# ========================================

Write-Host "🔍 Sotopia API 调试工具" -ForegroundColor Cyan

# 函数：测试端点
function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Method = "GET"
    )
    
    Write-Host "`n测试: $Name" -ForegroundColor Yellow
    Write-Host "  URL: $Url" -ForegroundColor Gray
    Write-Host "  Method: $Method" -ForegroundColor Gray
    
    try {
        $result = Invoke-RestMethod -Uri $Url -Method $Method -ErrorAction Stop
        Write-Host "  ✅ 成功" -ForegroundColor Green
        return $result
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "  ❌ 失败 (HTTP $statusCode)" -ForegroundColor Red
        Write-Host "     错误: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# ========================================
# 1. 健康检查
# ========================================
Write-Host "`n╔═══════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║  1. 健康检查                          ║" -ForegroundColor Magenta
Write-Host "╚═══════════════════════════════════════╝" -ForegroundColor Magenta

$health = Test-Endpoint "Health Check" "http://127.0.0.1:8800/health"
if ($health) {
    Write-Host "  Status: $($health.status)" -ForegroundColor Green
    Write-Host "  Redis: $($health.components.redis)" -ForegroundColor Gray
    Write-Host "  Database: $($health.components.database)" -ForegroundColor Gray
}

# ========================================
# 2. 查看所有数据
# ========================================
Write-Host "`n╔═══════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║  2. 查看现有数据                      ║" -ForegroundColor Magenta
Write-Host "╚═══════════════════════════════════════╝" -ForegroundColor Magenta

# Scenarios
$scenarios = Test-Endpoint "所有 Scenarios" "http://127.0.0.1:8800/scenarios"
if ($scenarios) {
    Write-Host "  找到 $($scenarios.Count) 个 Scenarios" -ForegroundColor Gray
    if ($scenarios.Count -gt 0) {
        $scenarios | Select-Object -First 3 | Format-Table pk, codename -AutoSize
    }
}

# Agents
$agents = Test-Endpoint "所有 Agents" "http://127.0.0.1:8800/agents"
if ($agents) {
    Write-Host "  找到 $($agents.Count) 个 Agents" -ForegroundColor Gray
    if ($agents.Count -gt 0) {
        $agents | Select-Object -First 5 | Format-Table pk, first_name, last_name, occupation -AutoSize
    }
}

# Episodes
$episodes = Test-Endpoint "所有 Episodes" "http://127.0.0.1:8800/episodes"
if ($episodes) {
    Write-Host "  找到 $($episodes.Count) 个 Episodes" -ForegroundColor Gray
    if ($episodes.Count -gt 0) {
        $episodes | Select-Object -First 5 | Format-Table pk, tag, @{Name="Messages";Expression={$_.messages.Count}} -AutoSize
    }
}

# Models
$models = Test-Endpoint "可用 Models" "http://127.0.0.1:8800/models"
if ($models) {
    Write-Host "  Models: $($models -join ', ')" -ForegroundColor Gray
}

# ========================================
# 3. 测试所有 API 端点
# ========================================
Write-Host "`n╔═══════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║  3. 测试所有端点                      ║" -ForegroundColor Magenta
Write-Host "╚═══════════════════════════════════════╝" -ForegroundColor Magenta

$endpoints = @(
    @{Name="Health"; Url="http://127.0.0.1:8800/health"; Method="GET"}
    @{Name="Scenarios"; Url="http://127.0.0.1:8800/scenarios"; Method="GET"}
    @{Name="Agents"; Url="http://127.0.0.1:8800/agents"; Method="GET"}
    @{Name="Episodes"; Url="http://127.0.0.1:8800/episodes"; Method="GET"}
    @{Name="Models"; Url="http://127.0.0.1:8800/models"; Method="GET"}
    @{Name="Evaluation Dims"; Url="http://127.0.0.1:8800/evaluation_dimensions"; Method="GET"}
)

Write-Host "`n端点测试结果:" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

foreach ($ep in $endpoints) {
    Write-Host "`n  $($ep.Name):" -NoNewline -ForegroundColor Yellow
    try {
        $null = Invoke-RestMethod -Uri $ep.Url -Method $ep.Method -ErrorAction Stop
        Write-Host " ✅" -ForegroundColor Green
    } catch {
        Write-Host " ❌ [$($_.Exception.Response.StatusCode.value__)]" -ForegroundColor Red
    }
}

# ========================================
# 4. 环境变量检查
# ========================================
Write-Host "`n╔═══════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║  4. 环境变量检查                      ║" -ForegroundColor Magenta
Write-Host "╚═══════════════════════════════════════╝" -ForegroundColor Magenta

$envVars = @(
    "OPENAI_API_KEY",
    "REDIS_OM_URL",
    "ANTHROPIC_API_KEY",
    "TOGETHER_API_KEY"
)

foreach ($var in $envVars) {
    $value = [Environment]::GetEnvironmentVariable($var)
    if ($value) {
        $preview = $value.Substring(0, [Math]::Min(20, $value.Length)) + "..."
        Write-Host "  ✅ $var = $preview" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  $var (未设置)" -ForegroundColor Yellow
    }
}

# ========================================
# 5. 查询特定 Episode (如果有)
# ========================================
Write-Host "`n╔═══════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║  5. 查询最近的 Episode                ║" -ForegroundColor Magenta
Write-Host "╚═══════════════════════════════════════╝" -ForegroundColor Magenta

if ($episodes -and $episodes.Count -gt 0) {
    $latest = $episodes | Sort-Object -Property pk -Descending | Select-Object -First 1
    
    Write-Host "`n最新 Episode:" -ForegroundColor Cyan
    Write-Host "  ID: $($latest.pk)" -ForegroundColor Gray
    Write-Host "  Tag: $($latest.tag)" -ForegroundColor Gray
    Write-Host "  Models: $($latest.models -join ', ')" -ForegroundColor Gray
    
    if ($latest.messages -and $latest.messages.Count -gt 0) {
        Write-Host "  消息数: $($latest.messages.Count)" -ForegroundColor Gray
        
        Write-Host "`n  前 3 条消息:" -ForegroundColor Yellow
        foreach ($msg in ($latest.messages | Select-Object -First 3)) {
            $speaker = if ($msg.agent_name) { $msg.agent_name } else { "System" }
            $content = if ($msg.content) { $msg.content } else { $msg.message }
            $preview = if ($content.Length -gt 60) { $content.Substring(0, 60) + "..." } else { $content }
            Write-Host "    [$speaker]: $preview" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ⚠️  没有消息" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n  没有找到 Episodes" -ForegroundColor Yellow
}

# ========================================
# 6. API 文档链接
# ========================================
Write-Host "`n╔═══════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║  6. 有用的链接                        ║" -ForegroundColor Magenta
Write-Host "╚═══════════════════════════════════════╝" -ForegroundColor Magenta

Write-Host "`n  📚 API 文档: http://127.0.0.1:8800/docs" -ForegroundColor Cyan
Write-Host "  🏥 Health Check: http://127.0.0.1:8800/health" -ForegroundColor Cyan
Write-Host "  📊 ReDoc: http://127.0.0.1:8800/redoc" -ForegroundColor Cyan

Write-Host "`n✨ 调试完成！" -ForegroundColor Magenta

