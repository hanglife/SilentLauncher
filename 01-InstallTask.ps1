# ============================================================
# 1 添加 SilentLauncher 登录自启动计划任务
# Install SilentLauncher scheduled task at user logon
#
# 这个脚本做什么：
# 1. 找到 Run-SilentLauncher.ps1
# 2. 创建 Windows 计划任务
# 3. 设置为用户登录后自动运行
# 4. 重复运行时会覆盖更新旧任务，不会创建多个
# ============================================================

$ErrorActionPreference = "Stop"

# 计划任务名称 / Scheduled task name
$TaskName = "SilentLauncher"

# 当前脚本所在目录 / Current script directory
$ScriptDir = if ($PSScriptRoot) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}

# 备用目录 / Fallback directory
$FallbackDir = "F:\fly\SilentLauncher"

# 优先使用当前目录下的 Run-SilentLauncher.ps1
# Prefer Run-SilentLauncher.ps1 in current script directory
$RunnerInCurrentDir = Join-Path $ScriptDir "Run-SilentLauncher.ps1"
$RunnerInFallbackDir = Join-Path $FallbackDir "Run-SilentLauncher.ps1"

if (Test-Path $RunnerInCurrentDir) {
    $Runner = $RunnerInCurrentDir
    $BaseDir = $ScriptDir
}
elseif (Test-Path $RunnerInFallbackDir) {
    $Runner = $RunnerInFallbackDir
    $BaseDir = $FallbackDir
}
else {
    throw "找不到 Run-SilentLauncher.ps1。请确认它在当前目录，或者在 F:\fly\SilentLauncher 目录。"
}

Write-Host ""
Write-Host "准备创建或更新计划任务..." -ForegroundColor Yellow
Write-Host "任务名称：$TaskName"
Write-Host "启动脚本：$Runner"
Write-Host "工作目录：$BaseDir"
Write-Host ""

# 任务动作：用 PowerShell 执行 Run-SilentLauncher.ps1
# Task action: run Run-SilentLauncher.ps1 with PowerShell
$ActionArgument = "-NoProfile -ExecutionPolicy Bypass -File `"$Runner`""

$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $ActionArgument -WorkingDirectory $BaseDir

# 触发器：用户登录后启动
# Trigger: run at user logon
$Trigger = New-ScheduledTaskTrigger -AtLogOn

# 登录后延迟 30 秒启动，避免刚进桌面时系统太忙
# Delay 30 seconds after logon
$Trigger.Delay = "PT30S"

# 使用当前用户身份运行
# Run as current user
# 目前使用的是普通用户运行，Limited 如果需要管理员模式运行则修改成
#注意一个坑
#如果用 Highest 启动 GUI 软件，某些托盘图标、拖拽文件、和普通权限软件交互，可能会变得不顺。

#所以我的建议是：
#$Principal = New-ScheduledTaskPrincipal `
#    -UserId "$env:USERDOMAIN\$env:USERNAME" `
#    -LogonType Interactive `
#    -RunLevel Highest

$Principal = New-ScheduledTaskPrincipal `
    -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType Interactive `
    -RunLevel Highest

# 任务设置
# Task settings
$Settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hours 0) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -MultipleInstances IgnoreNew -StartWhenAvailable

# 注册计划任务
# Register scheduled task
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Description "用户登录后自动启动 SilentLauncher，并记录日志 / Start SilentLauncher after user logon with logs" -Force

Write-Host ""
Write-Host "计划任务创建或更新成功。" -ForegroundColor Green
Write-Host "重复运行这个脚本不会创建多个任务，只会覆盖更新 SilentLauncher 任务。" -ForegroundColor Green
Write-Host ""
Write-Host "下一步：运行 2 手动测试任务.ps1，或者双击 2 双击手动测试任务.cmd 进行测试。" -ForegroundColor Yellow
Write-Host ""

Start-Sleep -Seconds 10