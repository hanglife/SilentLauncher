@echo off
chcp 65001 >nul
title 添加 SilentLauncher 计划任务

echo 正在添加或更新 SilentLauncher 计划任务...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp001-InstallTask.ps1"

echo.
echo 脚本已结束。
timeout /t 10