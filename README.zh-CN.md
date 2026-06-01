# SilentLauncher 中文使用说明

`SilentLauncher.exe` 是一个 Windows 隐藏启动器。它自己的程序类型是 `WinExe`，所以双击不会弹出黑色控制台窗口；它会读取 `launcher.json`，按配置启动一个或多个软件，并尝试隐藏或最小化目标软件窗口。

它适合处理这类需求：

- 登录 Windows 后自动启动 Kavita、Jellyfin、Sideloadly、同步工具等软件。
- 不想让这些软件启动时弹到前台。
- 不想把 GUI 软件硬塞进 Windows Service。
- 想给每个软件设置延迟、防重复启动、工作目录、启动参数和日志。

## 文件说明

### 建议全部使用右键-管理员模式-

```text
├─ Run-SilentLauncher.ps1        ← 核心启动脚本
│
├─ 01-InstallTask.ps1            ← 添加/更新计划任务
├─ 01-InstallTask.cmd            ← 双击添加/更新计划任务
│
├─ 02-TestTask.ps1               ← 手动测试任务
├─ 02-TestTask.cmd               ← 双击手动测试
│
├─ 04-TaskResult.ps1             ← 查看运行结果
├─ 04-TaskResult.cmd             ← 双击查看运行结果
│
├─ 05-RemoveTask.ps1             ← 删除任务
├─ 05-RemoveTask.cmd             ← 双击删除任务
│
├─ 03-View-LatestLog.ps1         ← 查看最新日志
├─ 03-View-LatestLog.cmd         ← 双击查看最新日志
│
├─ SilentLauncher.exe            ← SilentLauncher-code 编译生成
├─ SilentLauncher.log            ← 日志
│
├─ SilentLauncher.pdb            ← 可删除
│
├─ launcher.example.json         ← 主要配置文件示例
├─ launcher.json                 ← 主要配置文件 配置完需要删除注释
```

## Quick Start 快速开始

1. 下载库
2. 配置 [launcher.example.json](https://github.com/hanglife/SilentLauncher/blob/main/launcher.example.json) 配置完后修改文件名为 `launcher.json`

   大部分不用修改，只要修改添加 `apps` 内配置你要启动的 app。

   e.g.

   服务类型程序如 Jellyfin，Kavita 和 正常应用程序 如 Sideloadly（连接手机自动刷新应用）。

   注意：

   `"hideWindow": true` 后，正常应用程序在任务栏以及 Windows 中不会显示窗口，关闭需要在任务管理器中搜索找到程序关闭。

3. `01-InstallTask.cmd` 安装，右键管理员模式运行
4. `02-TestTask.cmd` 测试，右键管理员模式运行
