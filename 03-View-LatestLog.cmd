@echo off
chcp 65001 >nul
title 查看 SilentLauncher 最新日志

echo 正在查看 SilentLauncher 最新日志...
echo.

set "SCRIPT=%~dp003-View-LatestLog.ps1"

if not exist "%SCRIPT%" (
    echo 找不到脚本文件：
    echo %SCRIPT%
    echo.
    echo 请确认 03-View-LatestLog.ps1 和这个 cmd 文件在同一个目录。
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"

echo.
echo 查看日志脚本已结束。
timeout /t 10