# ============================================================
# 02 手动测试 SilentLauncher 计划任务
# 作用：
# 1. 检查 SilentLauncher 计划任务是否存在
# 2. 手动启动计划任务
# 3. 等待 10 秒
# 4. 查看任务运行结果
# 5. 显示最新日志
# ============================================================

$ErrorActionPreference = "Stop"

$TaskName = "SilentLauncher"

$ScriptDir = if ($PSScriptRoot) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}

$LogDir = Join-Path $ScriptDir "logs"

function Show-LatestLog {
    if (-not (Test-Path $LogDir)) {
        Write-Host ""
        Write-Host "没有找到日志目录：$LogDir" -ForegroundColor Yellow
        Write-Host "说明 Run-SilentLauncher.ps1 可能还没有真正运行过。" -ForegroundColor Yellow
        return
    }

    $LatestLog = Get-ChildItem $LogDir -Filter "*.log" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -eq $LatestLog) {
        Write-Host ""
        Write-Host "日志目录存在，但没有 .log 文件。" -ForegroundColor Yellow
        Write-Host "说明 Run-SilentLauncher.ps1 可能还没有真正运行过。" -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "========== 最新日志 ==========" -ForegroundColor Cyan
    Write-Host "日志文件：$($LatestLog.FullName)"
    Write-Host "修改时间：$($LatestLog.LastWriteTime)"
    Write-Host "==============================" -ForegroundColor Cyan
    Get-Content $LatestLog.FullName -Tail 120
}

try {
    Write-Host ""
    Write-Host "========== SilentLauncher 手动测试 ==========" -ForegroundColor Cyan
    Write-Host "脚本目录：$ScriptDir"
    Write-Host "任务名称：$TaskName"
    Write-Host ""

    $Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

    if ($null -eq $Task) {
        throw "没有找到计划任务：$($TaskName)。请先运行 01-InstallTask.cmd。"
    }

    Write-Host "已找到计划任务。" -ForegroundColor Green
    Write-Host "当前状态：$($Task.State)"
    Write-Host ""

    Write-Host "正在手动启动计划任务..." -ForegroundColor Yellow
    Start-ScheduledTask -TaskName $TaskName

    Write-Host "启动命令已发送，等待 10 秒..." -ForegroundColor Green

    for ($i = 10; $i -ge 1; $i--) {
        Write-Host "等待中：$i 秒..."
        Start-Sleep -Seconds 1
    }

    $Info = Get-ScheduledTaskInfo -TaskName $TaskName

    Write-Host ""
    Write-Host "========== 任务运行结果 ==========" -ForegroundColor Cyan
    Write-Host "上次运行时间：$($Info.LastRunTime)"
    Write-Host "上次运行结果：$($Info.LastTaskResult)"
    Write-Host "下次运行时间：$($Info.NextRunTime)"
    Write-Host "错过运行次数：$($Info.NumberOfMissedRuns)"
    Write-Host "==================================" -ForegroundColor Cyan

    if ($Info.LastTaskResult -eq 0) {
        Write-Host "结果：计划任务运行成功。" -ForegroundColor Green
    }
    elseif ($Info.LastTaskResult -eq 267009) {
        Write-Host "结果：任务正在运行中，不一定是失败。" -ForegroundColor Yellow
    }
    elseif ($Info.LastTaskResult -eq 267011) {
        Write-Host "结果：任务还没有真正运行过，或者还没产生有效结果。" -ForegroundColor Yellow
    }
    else {
        Write-Host "结果：计划任务可能失败，错误码：$($Info.LastTaskResult)" -ForegroundColor Red
    }

    Show-LatestLog

    Write-Host ""
    Write-Host "========== 手动测试完成 ==========" -ForegroundColor Cyan
}
catch {
    Write-Host ""
    Write-Host "手动测试失败：" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host ""
Write-Host "窗口将在 10 秒后自动关闭。" -ForegroundColor Yellow
Start-Sleep -Seconds 10