# ============================================================
# Run-SilentLauncher.ps1
# SilentLauncher 启动包装脚本
#
# 这个脚本做什么：
# 1. 优先检查当前脚本目录是否有 SilentLauncher.exe 和 launcher.json
# 2. 如果没有，再检查当前运行目录
# 3. 如果还没有，就使用备用路径 F:\fly\SilentLauncher
# 4. 启动 SilentLauncher.exe，并传入 launcher.json
# 5. 自动写入 logs 日志
# 6. 启动失败时弹出中文提醒，并自动打开日志
# ============================================================

$ErrorActionPreference = "Stop"

# ============================================================
# 备用路径配置
# 如果当前目录没有 SilentLauncher.exe 和 launcher.json，就用这里
# ============================================================

$FallbackExe = "F:\fly\SilentLauncher\SilentLauncher.exe"
$FallbackConfig = "F:\fly\SilentLauncher\launcher.json"

# ============================================================
# 当前脚本目录和当前运行目录
# ============================================================

$ScriptDir = if ($PSScriptRoot) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}

$CurrentDir = (Get-Location).Path

# ============================================================
# 日志目录
# 默认写到 Run-SilentLauncher.ps1 所在目录的 logs 文件夹
# ============================================================

$LogDir = Join-Path $ScriptDir "logs"

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
}

$LogFile = Join-Path $LogDir ("SilentLauncher_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

# ============================================================
# 写日志函数
# ============================================================

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $Line = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    $Line | Tee-Object -FilePath $LogFile -Append
}

# ============================================================
# 失败提醒函数
# ============================================================

function Show-FailAlert {
    param(
        [string]$Message
    )

    Write-Log $Message "ERROR"

    $FullMessage = @"
SilentLauncher 启动失败。

失败原因：
$Message

日志文件：
$LogFile

建议检查：
1. SilentLauncher.exe 是否存在
2. launcher.json 是否存在
3. launcher.json 内容是否正确
4. 计划任务是否指向 Run-SilentLauncher.ps1
5. 当前账号是否有权限运行该程序
"@

    try {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show(
            $FullMessage,
            "SilentLauncher 启动失败",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    } catch {
        Write-Log "弹窗提醒失败，但不影响日志记录。" "WARN"
    }

    try {
        Start-Process notepad.exe $LogFile
    } catch {
        Write-Log "自动打开日志失败，请手动查看日志文件。" "WARN"
    }
}

# ============================================================
# 解析最终使用哪个 SilentLauncher.exe 和 launcher.json
# ============================================================

function Resolve-LauncherFiles {
    # 方案 1：脚本所在目录
    $ExeInScriptDir = Join-Path $ScriptDir "SilentLauncher.exe"
    $ConfigInScriptDir = Join-Path $ScriptDir "launcher.json"

    if ((Test-Path $ExeInScriptDir) -and (Test-Path $ConfigInScriptDir)) {
        return @{
            Exe = $ExeInScriptDir
            Config = $ConfigInScriptDir
            BaseDir = $ScriptDir
            Source = "脚本所在目录"
        }
    }

    # 方案 2：当前运行目录
    $ExeInCurrentDir = Join-Path $CurrentDir "SilentLauncher.exe"
    $ConfigInCurrentDir = Join-Path $CurrentDir "launcher.json"

    if ((Test-Path $ExeInCurrentDir) -and (Test-Path $ConfigInCurrentDir)) {
        return @{
            Exe = $ExeInCurrentDir
            Config = $ConfigInCurrentDir
            BaseDir = $CurrentDir
            Source = "当前运行目录"
        }
    }

    # 方案 3：备用路径
    if ((Test-Path $FallbackExe) -and (Test-Path $FallbackConfig)) {
        return @{
            Exe = $FallbackExe
            Config = $FallbackConfig
            BaseDir = Split-Path -Parent $FallbackExe
            Source = "备用路径"
        }
    }

    throw @"
找不到可用的 SilentLauncher.exe 和 launcher.json。

已经检查以下位置：

1. 脚本所在目录：
$ScriptDir

2. 当前运行目录：
$CurrentDir

3. 备用路径：
$FallbackExe
$FallbackConfig
"@
}

# ============================================================
# 主流程
# ============================================================

try {
    Write-Log "========== SilentLauncher 启动流程开始 =========="
    Write-Log "脚本所在目录：$ScriptDir"
    Write-Log "当前运行目录：$CurrentDir"
    Write-Log "备用启动器路径：$FallbackExe"
    Write-Log "备用配置文件路径：$FallbackConfig"

    $Resolved = Resolve-LauncherFiles

    $Exe = $Resolved.Exe
    $Config = $Resolved.Config
    $BaseDir = $Resolved.BaseDir
    $Source = $Resolved.Source

    Write-Log "最终使用来源：$Source"
    Write-Log "最终启动器路径：$Exe"
    Write-Log "最终配置文件路径：$Config"
    Write-Log "最终工作目录：$BaseDir"

    if (-not (Test-Path $Exe)) {
        throw "最终启动器路径不存在：$Exe"
    }

    if (-not (Test-Path $Config)) {
        throw "最终配置文件路径不存在：$Config"
    }

    Write-Log "文件检查通过，准备启动 SilentLauncher。"

    $ArgumentText = '"' + $Config + '"'

    $Process = Start-Process `
        -FilePath $Exe `
        -ArgumentList $ArgumentText `
        -WorkingDirectory $BaseDir `
        -WindowStyle Hidden `
        -PassThru

    Write-Log "SilentLauncher 启动命令已发送。"
    Write-Log "SilentLauncher 进程 PID：$($Process.Id)"

    Start-Sleep -Seconds 8

    $Process.Refresh()

    if ($Process.HasExited) {
        Write-Log "SilentLauncher 进程已经退出。" "WARN"
        Write-Log "退出码：$($Process.ExitCode)" "WARN"

        if ($Process.ExitCode -ne 0) {
            throw "SilentLauncher 启动后异常退出，退出码：$($Process.ExitCode)"
        } else {
            Write-Log "SilentLauncher 正常退出。如果它只是负责拉起其他程序，这通常是正常现象。"
        }
    } else {
        Write-Log "SilentLauncher 仍在运行，初步判断启动成功。"
    }

    Write-Log "========== SilentLauncher 启动流程完成 =========="
    exit 0
}
catch {
    Show-FailAlert $_.Exception.Message
    exit 1
}