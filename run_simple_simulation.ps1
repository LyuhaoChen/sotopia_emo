# ========================================
# Sotopia 简化版 - 快速运行
# ========================================

Write-Host "🚀 Sotopia 快速模拟..." -ForegroundColor Cyan

# 1. 创建场景
Write-Host "`n[1/4] 创建场景..." -ForegroundColor Yellow
$ENV_PK = Invoke-RestMethod -Uri "http://127.0.0.1:8800/scenarios" -Method POST `
    -Headers @{"Content-Type"="application/json"} `
    -Body '{"codename":"quick_test","scenario":"三人简单对话","agent_goals":["打招呼","回应","告别"]}'
Write-Host "  ✅ Scenario: $ENV_PK" -ForegroundColor Green

# 2. 创建 Agents
Write-Host "`n[2/4] 创建 Agents..." -ForegroundColor Yellow
$A1 = Invoke-RestMethod -Uri "http://127.0.0.1:8800/agents" -Method POST `
    -Headers @{"Content-Type"="application/json"} `
    -Body '{"first_name":"Alice","last_name":"A"}'
$A2 = Invoke-RestMethod -Uri "http://127.0.0.1:8800/agents" -Method POST `
    -Headers @{"Content-Type"="application/json"} `
    -Body '{"first_name":"Bob","last_name":"B"}'
$A3 = Invoke-RestMethod -Uri "http://127.0.0.1:8800/agents" -Method POST `
    -Headers @{"Content-Type"="application/json"} `
    -Body '{"first_name":"Carol","last_name":"C"}'
Write-Host "  ✅ Agents: $A1, $A2, $A3" -ForegroundColor Green

# 3. 提交模拟
Write-Host "`n[3/4] 提交模拟..." -ForegroundColor Yellow
$body = @{
    env_id = $ENV_PK
    agent_ids = @($A1, $A2, $A3)
    models = @("gpt-4o-mini", "gpt-4o-mini", "gpt-4o-mini", "gpt-4o-mini")
    max_turns = 8
    tag = "quick_test"
} | ConvertTo-Json -Depth 10

$EPK = Invoke-RestMethod -Uri "http://127.0.0.1:8800/simulate" -Method POST `
    -Headers @{"Content-Type"="application/json"} -Body $body
Write-Host "  ✅ Episode: $EPK" -ForegroundColor Green

# 4. 等待并获取结果
Write-Host "`n[4/4] 等待结果 (最多 2 分钟)..." -ForegroundColor Yellow
$waited = 0
while ($waited -lt 120) {
    Start-Sleep -Seconds 5
    $waited += 5
    
    try {
        $ep = Invoke-RestMethod -Uri "http://127.0.0.1:8800/episodes/pk/$EPK" -Method GET
        $count = if ($ep.messages) { $ep.messages.Count } else { 0 }
        
        Write-Host "  [$waited`s] 消息数: $count" -ForegroundColor Gray
        
        if ($count -ge 6) {
            Write-Host "`n✅ 完成！显示对话:" -ForegroundColor Green
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
            
            foreach ($msg in $ep.messages) {
                $speaker = if ($msg.agent_name) { $msg.agent_name } else { "System" }
                $content = if ($msg.content) { $msg.content } else { $msg.message }
                Write-Host "`n[$speaker]: $content"
            }
            
            Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
            
            # 保存
            $file = "quick_sim_$(Get-Date -Format 'HHmmss').json"
            $ep | ConvertTo-Json -Depth 10 | Out-File $file -Encoding UTF8
            Write-Host "已保存: $file" -ForegroundColor Green
            break
        }
    } catch {
        Write-Host "  [$waited`s] 等待中..." -ForegroundColor Gray
    }
}

if ($waited -ge 120) {
    Write-Host "`n⏱️  超时！请手动查询: http://127.0.0.1:8800/episodes/pk/$EPK" -ForegroundColor Yellow
}

Write-Host "`n✨ 完成！Episode ID: $EPK" -ForegroundColor Magenta

