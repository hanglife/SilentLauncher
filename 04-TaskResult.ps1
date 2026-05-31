# ============================================================
# 4 查看 SilentLauncher 计划任务运行结果
# View SilentLauncher scheduled task result
#
# 这个脚本做什么：
# 1. 检查 SilentLauncher 计划任务是否存在
# 2. 查看任务当前状态
# 3. 查看上次运行时间
# 4. 查看上次运行结果 LastTaskResult
# 5. 给出中文解释
#
# 注意：
# LastTaskResult = 0 通常表示计划任务执行成功。
# 但程序内部是否完全正常，还要结合 logs 日志一起看。
# ============================================================

$ErrorActionPreference = "Stop"

$TaskName = "SilentLauncher"

try {
    Write-Host ""
    Write-Host "========== 查看 SilentLauncher 运行结果 ==========" -ForegroundColor Cyan
    Write-Host "计划任务名称：$TaskName"
    Write-Host ""

    $Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

    if ($null -eq $Task) {
        throw "没有找到计划任务：$TaskName。请先运行 1 添加任务.ps1。"
    }

    $Info = Get-ScheduledTaskInfo -TaskName $TaskName

    Write-Host "任务存在。" -ForegroundColor Green
    Write-Host ""
    Write-Host "任务路径：$($Task.TaskPath)"
    Write-Host "当前状态：$($Task.State)"
    Write-Host "上次运行时间：$($Info.LastRunTime)"
    Write-Host "上次运行结果：$($Info.LastTaskResult)"
    Write-Host "下次运行时间：$($Info.NextRunTime)"
    Write-Host "错过运行次数：$($Info.NumberOfMissedRuns)"
    Write-Host ""

    Write-Host "========== 结果解释 ==========" -ForegroundColor Cyan

    if ($Info.LastTaskResult -eq 0) {
        Write-Host "LastTaskResult = 0" -ForegroundColor Green
        Write-Host "解释：Windows 计划任务层面显示运行成功。" -ForegroundColor Green
        Write-Host "下一步：如果你还想确认程序内部是否正常，请查看 logs 目录里的最新日志。" -ForegroundColor Yellow
    } elseif ($Info.LastTaskResult -eq 267009) {
        Write-Host "LastTaskResult = 267009" -ForegroundColor Yellow
        Write-Host "解释：任务正在运行中，不一定是失败。" -ForegroundColor Yellow
    } else {
        Write-Host "LastTaskResult = $($Info.LastTaskResult)" -ForegroundColor Red
        Write-Host "解释：计划任务可能运行失败。" -ForegroundColor Red
        Write-Host "建议：查看 logs 最新日志，或者双击 2 双击手动测试任务.cmd 再测一次。" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "========== 查看完成 ==========" -ForegroundColor Cyan
}
catch {
    Write-Host ""
    Write-Host "查看运行结果失败：" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host ""
Write-Host "窗口将在 10 秒后自动关闭。" -ForegroundColor Yellow
Start-Sleep -Seconds 10