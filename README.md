# SilentLauncher

`SilentLauncher.exe` is a hidden launcher for Windows. The application itself is built as `WinExe`, so double-clicking it does not open a black console window. It reads `launcher.json`, starts one or more programs according to the configuration, and tries to hide or minimize the target program windows.

## Languages

- [简体中文](README.zh-CN.md)

It is useful for these scenarios:

- Automatically start Kavita, Jellyfin, Sideloadly, sync tools, and similar programs after logging in to Windows.
- Keep those programs from popping up in the foreground during startup.
- Avoid forcing GUI applications into Windows Service mode.
- Configure delay, duplicate-start prevention, working directory, startup arguments, and logging for each program.

## Files

### It is recommended to run all scripts by right-clicking and choosing administrator mode.

```text
├─ Run-SilentLauncher.ps1        ← Core startup script
│
├─ 01-InstallTask.ps1            ← Add/update the scheduled task
├─ 01-InstallTask.cmd            ← Double-click to add/update the scheduled task
│
├─ 02-TestTask.ps1               ← Manually test the task
├─ 02-TestTask.cmd               ← Double-click to manually test
│
├─ 04-TaskResult.ps1             ← View the run result
├─ 04-TaskResult.cmd             ← Double-click to view the run result
│
├─ 05-RemoveTask.ps1             ← Remove the task
├─ 05-RemoveTask.cmd             ← Double-click to remove the task
│
├─ 03-View-LatestLog.ps1         ← View the latest log
├─ 03-View-LatestLog.cmd         ← Double-click to view the latest log
│
├─ SilentLauncher.exe            ← Built from SilentLauncher-code
├─ SilentLauncher.log            ← Log file
│
├─ SilentLauncher.pdb            ← Can be deleted
│
├─ launcher.example.json         ← Main configuration example with English comments
├─ launcher.example.zh-CN.json   ← Main configuration example with Simplified Chinese comments
├─ launcher.json                 ← Main configuration file copied from one of the examples
```

## Configuration Comments

The example configuration files intentionally use JSONC-style `//` comments. Strict JSON validators may mark them as invalid because standard JSON does not allow comments, but SilentLauncher reads `launcher.json` with comment skipping and trailing-comma support.

The comments are only documentation. You can delete all `//` comment lines after editing the configuration, and SilentLauncher will work the same way.

## Quick Start

1. Download the repository.
2. Configure [launcher.example.json](launcher.example.json), or use [launcher.example.zh-CN.json](launcher.example.zh-CN.json) if you prefer Simplified Chinese comments, then rename the chosen file to `launcher.json`.

   Most settings do not need to be changed. Usually you only need to edit the `apps` section and add the applications you want to start.

   For example, service-style programs such as Jellyfin and Kavita, or normal desktop applications such as Sideloadly, which can refresh apps automatically when a phone is connected.

   Note:

   When `"hideWindow": true` is enabled for a normal desktop application, its window will not appear in the taskbar or on the Windows desktop. To close it, open Task Manager, search for the program, and end it there.

3. Run `01-InstallTask.cmd` as administrator to install the task.
4. Run `02-TestTask.cmd` as administrator to test the task.
