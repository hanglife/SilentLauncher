# ============================================================
# 查看 SilentLauncher 最新日志
# View latest SilentLauncher log
#
# 这个脚本做什么：
# 1. 自动寻找当前目录下的 logs 文件夹
# 2. 找到最新的 .log 文件
# 3. 显示日志路径、时间、大小
# 4. 显示最新日志内容
# 5. 自动用记事本打开最新日志，方便复制排查
# ============================================================

$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}

$LogDir = Join-Path $ScriptDir "logs"

try {
    Write-Host ""
    Write-Host "========== 查看 SilentLauncher 最新日志 ==========" -ForegroundColor Cyan
    Write-Host "当前脚本目录：$ScriptDir"
    Write-Host "日志目录：$LogDir"
    Write-Host ""

    if (-not (Test-Path $LogDir)) {
        throw "没有找到日志目录。说明 Run-SilentLauncher.ps1 可能还没有运行过。"
    }

    $LatestLog = Get-ChildItem $LogDir -Filter "*.log" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -eq $LatestLog) {
        throw "日志目录存在，但里面没有 .log 文件。说明还没有产生启动日志。"
    }

    Write-Host "已找到最新日志。" -ForegroundColor Green
    Write-Host ""
    Write-Host "日志文件：$($LatestLog.FullName)"
    Write-Host "修改时间：$($LatestLog.LastWriteTime)"
    Write-Host "文件大小：$($LatestLog.Length) 字节"
    Write-Host ""

    Write-Host "================ 日志内容，最近 150 行 ================" -ForegroundColor Cyan
    Get-Content $LatestLog.FullName -Tail 150
    Write-Host "========================================================" -ForegroundColor Cyan

    Write-Host ""
    Write-Host "正在用记事本打开最新日志..." -ForegroundColor Yellow
    Start-Process notepad.exe $LatestLog.FullName
}
catch {
    Write-Host ""
    Write-Host "查看日志失败：" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host ""
Write-Host "窗口将在 10 秒后自动关闭。" -ForegroundColor Yellow
Start-Sleep -Seconds 10