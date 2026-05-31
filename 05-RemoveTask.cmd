@echo off
chcp 65001 >nul
title 删除 SilentLauncher 计划任务

echo 正在删除 SilentLauncher 计划任务...
echo.
echo 注意：这里只删除 Windows 计划任务，不删除程序文件。
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp005-RemoveTask.ps1"

echo.
echo 删除脚本已结束。
timeout /t 10