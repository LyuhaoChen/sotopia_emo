# ========================================
# Sotopia 三人对话模拟 - 完整流程
# ========================================

Write-Host @"
╔═══════════════════════════════════════════════════════════╗
║         Sotopia 三人对话模拟 - 完整流程                  ║
╚═══════════════════════════════════════════════════════════╝
"@ -ForegroundColor Magenta

# ========================================
# 步骤 0: 环境检查
# ========================================
Write-Host "`n[步骤 0/6] 环境检查..." -ForegroundColor Cyan

Write-Host "  检查 API 服务器..." -ForegroundColor Gray
try {
    $health = Invoke-RestMethod -Uri "http://127.0.0.1:8800/health" -Method GET
    Write-Host "  ✅ API 服务器运行正常" -ForegroundColor Green
    Write-Host "     Redis: $($health.components.redis)" -ForegroundColor Gray
    Write-Host "     Database: $($health.components.database)" -ForegroundColor Gray
} catch {
    Write-Host "  ❌ API 服务器未启动！" -ForegroundColor Red
    Write-Host "     请先运行: fastapi run sotopia/api/fastapi_server.py --port 8800" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n  检查环境变量..." -ForegroundColor Gray
if ([string]::IsNullOrEmpty($env:OPENAI_API_KEY)) {
    Write-Host "  ⚠️  警告: OPENAI_API_KEY 未设置" -ForegroundColor Yellow
    Write-Host "     模拟可能会失败，请先设置 API Key" -ForegroundColor Yellow
} else {
    $keyPreview = $env:OPENAI_API_KEY.Substring(0, [Math]::Min(10, $env:OPENAI_API_KEY.Length)) + "..."
    Write-Host "  ✅ OPENAI_API_KEY: $keyPreview" -ForegroundColor Green
}

Start-Sleep -Seconds 1

# ========================================
# 步骤 1: 创建场景 (Scenario)
# ========================================
Write-Host "`n[步骤 1/6] 创建场景..." -ForegroundColor Cyan

$scenarioBody = @{
    codename = "coffee_shop_chat"
    scenario = "三个朋友在咖啡店偶然相遇，开始聊天。Alice 是一位软件工程师，Bob 是大学教授，Carol 是自由艺术家。"
    agent_goals = @(
        "Alice: 和朋友们分享最近的工作项目进展",
        "Bob: 询问大家对人工智能的看法",
        "Carol: 邀请朋友们参加即将举办的艺术展"
    )
} | ConvertTo-Json -Depth 10

try {
    $ENV_PK = Invoke-RestMethod `
        -Uri "http://127.0.0.1:8800/scenarios" `
        -Method POST `
        -Headers @{ "Content-Type" = "application/json" } `
        -Body $scenarioBody
    
    Write-Host "  ✅ 场景创建成功" -ForegroundColor Green
    Write-Host "     Scenario ID: $ENV_PK" -ForegroundColor Gray
} catch {
    Write-Host "  ❌ 创建失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Start-Sleep -Seconds 1

# ========================================
# 步骤 2: 创建三个 Agents
# ========================================
Write-Host "`n[步骤 2/6] 创建 Agents..." -ForegroundColor Cyan

# Agent 1: Alice
$agent1Body = @{
    first_name = "Alice"
    last_name = "Johnson"
    age = 28
    occupation = "Software Engineer"
    gender = "female"
    gender_pronoun = "she/her"
    personality_traits = @("analytical", "friendly", "tech-savvy")
    public_info = "A passionate software engineer who loves coding and coffee"
    big_five_personality = @("high_openness", "high_conscientiousness", "medium_extraversion", "low_agreeableness", "low_neuroticism")
} | ConvertTo-Json -Depth 10

try {
    $AGENT1_PK = Invoke-RestMethod `
        -Uri "http://127.0.0.1:8800/agents" `
        -Method POST `
        -Headers @{ "Content-Type" = "application/json" } `
        -Body $agent1Body
    
    Write-Host "  ✅ Alice 创建成功: $AGENT1_PK" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Alice 创建失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Agent 2: Bob
$agent2Body = @{
    first_name = "Bob"
    last_name = "Smith"
    age = 45
    occupation = "University Professor"
    gender = "male"
    gender_pronoun = "he/him"
    personality_traits = @("knowledgeable", "curious", "thoughtful")
    public_info = "A philosophy professor interested in AI ethics"
    big_five_personality = @("high_openness", "high_conscientiousness", "low_extraversion", "high_agreeableness", "low_neuroticism")
} | ConvertTo-Json -Depth 10

try {
    $AGENT2_PK = Invoke-RestMethod `
        -Uri "http://127.0.0.1:8800/agents" `
        -Method POST `
        -Headers @{ "Content-Type" = "application/json" } `
        -Body $agent2Body
    
    Write-Host "  ✅ Bob 创建成功: $AGENT2_PK" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Bob 创建失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Agent 3: Carol
$agent3Body = @{
    first_name = "Carol"
    last_name = "Williams"
    age = 32
    occupation = "Artist"
    gender = "female"
    gender_pronoun = "she/her"
    personality_traits = @("creative", "expressive", "enthusiastic")
    public_info = "A freelance artist specializing in digital art"
    big_five_personality = @("high_openness", "low_conscientiousness", "high_extraversion", "high_agreeableness", "medium_neuroticism")
} | ConvertTo-Json -Depth 10

try {
    $AGENT3_PK = Invoke-RestMethod `
        -Uri "http://127.0.0.1:8800/agents" `
        -Method POST `
        -Headers @{ "Content-Type" = "application/json" } `
        -Body $agent3Body
    
    Write-Host "  ✅ Carol 创建成功: $AGENT3_PK" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Carol 创建失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Start-Sleep -Seconds 1

# ========================================
# 步骤 3: 提交模拟请求
# ========================================
Write-Host "`n[步骤 3/6] 提交模拟请求..." -ForegroundColor Cyan

$simulationBody = @{
    env_id = $ENV_PK
    agent_ids = @($AGENT1_PK, $AGENT2_PK, $AGENT3_PK)
    models = @("gpt-4o-mini", "gpt-4o-mini", "gpt-4o-mini", "gpt-4o-mini")
    max_turns = 12
    tag = "coffee_shop_conversation"
} | ConvertTo-Json -Depth 10

try {
    $EPISODE_PK = Invoke-RestMethod `
        -Uri "http://127.0.0.1:8800/simulate" `
        -Method POST `
        -Headers @{ "Content-Type" = "application/json" } `
        -Body $simulationBody
    
    Write-Host "  ✅ 模拟任务已提交" -ForegroundColor Green
    Write-Host "     Episode ID: $EPISODE_PK" -ForegroundColor Gray
} catch {
    Write-Host "  ❌ 提交失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Start-Sleep -Seconds 2

# ========================================
# 步骤 4: 等待模拟完成
# ========================================
Write-Host "`n[步骤 4/6] 等待模拟完成..." -ForegroundColor Cyan
Write-Host "  (这可能需要 1-3 分钟，取决于 API 响应速度)" -ForegroundColor Gray

$maxWaitTime = 300  # 最多等待 5 分钟
$checkInterval = 5   # 每 5 秒检查一次
$elapsed = 0
$lastStatus = ""

while ($elapsed -lt $maxWaitTime) {
    Start-Sleep -Seconds $checkInterval
    $elapsed += $checkInterval
    
    try {
        # 尝试查询 episode
        $episode = Invoke-RestMethod -Uri "http://127.0.0.1:8800/episodes/pk/$EPISODE_PK" -Method GET
        
        if ($episode) {
            $currentStatus = if ($episode.messages -and $episode.messages.Count -gt 0) { "running" } else { "pending" }
            $messageCount = if ($episode.messages) { $episode.messages.Count } else { 0 }
            
            if ($currentStatus -ne $lastStatus) {
                Write-Host "  [$elapsed`s] 状态: $currentStatus | 消息数: $messageCount" -ForegroundColor Yellow
                $lastStatus = $currentStatus
            }
            
            # 检查是否完成 (有足够的消息)
            if ($messageCount -ge 10) {
                Write-Host "`n  ✅ 模拟完成！" -ForegroundColor Green
                Write-Host "     总用时: $elapsed 秒" -ForegroundColor Gray
                Write-Host "     消息数: $messageCount" -ForegroundColor Gray
                break
            }
        }
    } catch {
        Write-Host "  [$elapsed`s] 等待中..." -ForegroundColor Yellow -NoNewline
        Write-Host "`r" -NoNewline
    }
}

if ($elapsed -ge $maxWaitTime) {
    Write-Host "`n  ⏱️  超时！模拟可能仍在运行或失败" -ForegroundColor Yellow
    Write-Host "     您可以稍后手动查询结果" -ForegroundColor Gray
}

Start-Sleep -Seconds 2

# ========================================
# 步骤 5: 获取模拟结果
# ========================================
Write-Host "`n[步骤 5/6] 获取模拟结果..." -ForegroundColor Cyan

try {
    # 查询完整的 episode
    $episode = Invoke-RestMethod -Uri "http://127.0.0.1:8800/episodes/pk/$EPISODE_PK" -Method GET
    
    if ($episode.messages -and $episode.messages.Count -gt 0) {
        Write-Host "  ✅ 成功获取对话记录" -ForegroundColor Green
        Write-Host "     消息数: $($episode.messages.Count)" -ForegroundColor Gray
        
        # 保存到文件
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $jsonFile = "episode_${timestamp}.json"
        $txtFile = "episode_${timestamp}.txt"
        
        # 保存 JSON
        $episode | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
        Write-Host "     JSON 已保存: $jsonFile" -ForegroundColor Gray
        
        # 保存可读文本
        $textOutput = @"
╔═══════════════════════════════════════════════════════════╗
║           Sotopia 对话模拟结果                            ║
╚═══════════════════════════════════════════════════════════╝

Episode ID: $EPISODE_PK
时间: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
场景: 咖啡店聊天
参与者: Alice (软件工程师), Bob (大学教授), Carol (艺术家)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

"@
        
        foreach ($msg in $episode.messages) {
            $speaker = if ($msg.agent_name) { $msg.agent_name } else { "System" }
            $role = if ($msg.role) { $msg.role } else { "message" }
            $content = if ($msg.content) { $msg.content } else { $msg.message }
            
            $textOutput += "`n[$speaker] ($role):`n$content`n`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n"
        }
        
        $textOutput | Out-File -FilePath $txtFile -Encoding UTF8
        Write-Host "     文本已保存: $txtFile" -ForegroundColor Gray
        
    } else {
        Write-Host "  ⚠️  没有找到对话消息" -ForegroundColor Yellow
        Write-Host "     模拟可能失败或还在处理中" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "  ❌ 获取失败: $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Seconds 1

# ========================================
# 步骤 6: 显示对话内容
# ========================================
Write-Host "`n[步骤 6/6] 显示对话内容..." -ForegroundColor Cyan

if ($episode -and $episode.messages -and $episode.messages.Count -gt 0) {
    Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                   对话内容                                ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    $messageIndex = 1
    foreach ($msg in $episode.messages) {
        $speaker = if ($msg.agent_name) { $msg.agent_name } else { "System" }
        $content = if ($msg.content) { $msg.content } else { $msg.message }
        
        # 根据说话者使用不同颜色
        $color = switch ($speaker) {
            "Alice" { "Green" }
            "Bob" { "Blue" }
            "Carol" { "Magenta" }
            default { "Gray" }
        }
        
        Write-Host "`n[$messageIndex] " -NoNewline -ForegroundColor Gray
        Write-Host "$speaker" -NoNewline -ForegroundColor $color
        Write-Host ":" -ForegroundColor Gray
        Write-Host "$content" -ForegroundColor White
        
        $messageIndex++
    }
    
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    
} else {
    Write-Host "  ⚠️  没有对话内容可显示" -ForegroundColor Yellow
}

# ========================================
# 完成
# ========================================
Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║                   ✨ 完成！✨                             ║" -ForegroundColor Magenta
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Magenta

Write-Host "`n📊 摘要信息:" -ForegroundColor Cyan
Write-Host "  - Scenario ID: $ENV_PK" -ForegroundColor Gray
Write-Host "  - Agents: Alice ($AGENT1_PK), Bob ($AGENT2_PK), Carol ($AGENT3_PK)" -ForegroundColor Gray
Write-Host "  - Episode ID: $EPISODE_PK" -ForegroundColor Gray
if ($episode.messages) {
    Write-Host "  - 消息数量: $($episode.messages.Count)" -ForegroundColor Gray
}

Write-Host "`n💡 提示:" -ForegroundColor Cyan
Write-Host "  - 结果已保存到当前目录" -ForegroundColor Gray
Write-Host "  - JSON 文件包含完整数据" -ForegroundColor Gray
Write-Host "  - TXT 文件便于阅读" -ForegroundColor Gray

Write-Host "`n🔗 有用的链接:" -ForegroundColor Cyan
Write-Host "  - API 文档: http://127.0.0.1:8800/docs" -ForegroundColor Gray
Write-Host "  - Health Check: http://127.0.0.1:8800/health" -ForegroundColor Gray

Write-Host ""

