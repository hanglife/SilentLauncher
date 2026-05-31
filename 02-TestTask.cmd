@echo off
chcp 65001 >nul
title SilentLauncher 手动测试

echo 正在启动 SilentLauncher 手动测试脚本...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp002-TestTask.ps1"

echo.
echo 测试脚本已结束。
timeout /t 10