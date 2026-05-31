# ============================================================
# 5 删除 SilentLauncher 计划任务
# Remove SilentLauncher scheduled task
#
# 这个脚本做什么：
# 1. 检查 SilentLauncher 计划任务是否存在
# 2. 如果存在，就删除这个计划任务
# 3. 不会删除 SilentLauncher.exe
# 4. 不会删除 launcher.json
# 5. 不会删除 logs 日志文件
# ============================================================

$ErrorActionPreference = "Stop"

$TaskName = "SilentLauncher"

try {
    Write-Host ""
    Write-Host "========== 删除 SilentLauncher 计划任务 ==========" -ForegroundColor Cyan
    Write-Host "计划任务名称：$TaskName"
    Write-Host ""

    $Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

    if ($null -eq $Task) {
        Write-Host "没有找到计划任务：$TaskName" -ForegroundColor Yellow
        Write-Host "无需删除，可能之前已经删除过。" -ForegroundColor Yellow
    } else {
        Write-Host "已找到计划任务，准备删除..." -ForegroundColor Yellow

        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false

        Write-Host ""
        Write-Host "计划任务已删除成功。" -ForegroundColor Green
        Write-Host "注意：只删除了 Windows 计划任务，没有删除程序文件和日志。" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "========== 删除流程完成 ==========" -ForegroundColor Cyan
}
catch {
    Write-Host ""
    Write-Host "删除任务失败：" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host ""
Write-Host "窗口将在 10 秒后自动关闭。" -ForegroundColor Yellow
Start-Sleep -Seconds 10