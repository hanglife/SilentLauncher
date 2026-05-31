@echo off
chcp 65001 >nul
title 查看 SilentLauncher 运行结果

echo 正在查看 SilentLauncher 计划任务运行结果...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp004-TaskResult.ps1"

echo.
echo 查看完成。
timeout /t 10