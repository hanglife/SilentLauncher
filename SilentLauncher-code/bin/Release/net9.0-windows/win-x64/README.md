# SilentLauncher 中文使用说明

`SilentLauncher.exe` 是一个 Windows 隐藏启动器。它自己的程序类型是 `WinExe`，所以双击不会弹出黑色控制台窗口；它会读取 `launcher.json`，按配置启动一个或多个软件，并尝试隐藏或最小化目标软件窗口。

它适合处理这类需求：

- 登录 Windows 后自动启动 Kavita、Jellyfin、Sideloadly、同步工具等软件。
- 不想让这些软件启动时弹到前台。
- 不想把 GUI 软件硬塞进 Windows Service。
- 想给每个软件设置延迟、防重复启动、工作目录、启动参数和日志。

## 文件说明

发布目录里主要有这些文件：

```text
SilentLauncher.exe       主程序
launcher.example.json    示例配置文件，里面有中文注释
README.md                本说明
SilentLauncher.pdb       调试符号，可删除，不影响运行
```

正式使用时，把 `launcher.example.json` 复制一份，改名为：

```text
launcher.json
```

然后把 `SilentLauncher.exe` 和 `launcher.json` 放在同一个目录。

## 编译

在项目目录执行：

```powershell
dotnet publish .\SilentLauncher.csproj -c Release -r win-x64 --self-contained false -p:PublishSingleFile=true
```

输出位置：

```text
bin\Release\net9.0-windows\win-x64\publish\SilentLauncher.exe
```

### 编译参数说明

`-c Release`

使用 Release 模式编译。适合日常使用，体积和性能更合适。

`-r win-x64`

生成 Windows 64 位版本。你的电脑一般用这个即可。

`--self-contained false`

不把 .NET 运行时打包进 exe。优点是 exe 小；缺点是目标电脑需要安装对应 .NET 运行时。你的电脑已经有 .NET 9，所以可以这样用。

`-p:PublishSingleFile=true`

尽量发布成单个 exe。这样复制和管理更方便。

## 配置文件

`launcher.json` 支持 `//` 中文注释和尾逗号，因为程序读取配置时已经开启了：

- `ReadCommentHandling = JsonCommentHandling.Skip`
- `AllowTrailingCommas = true`

所以你可以直接在配置文件里写说明，不需要删掉注释。

### 全局配置

`startupDelaySeconds`

全局启动延迟，单位是秒。设置为 `20` 表示 SilentLauncher 启动后先等 20 秒，再开始启动软件。

适合解决 Windows 刚登录时环境还没准备好的问题，例如网络没起来、USB 服务没起来、移动硬盘没挂载、杀毒软件还在扫描。设为 `0` 表示不等待。

`logFile`

日志路径。可以写相对路径，也可以写绝对路径。

例如：

```json
"logFile": "SilentLauncher.log"
```

表示日志写到 `SilentLauncher.exe` 所在目录。日志能帮你判断软件是否启动、是否被防重复逻辑跳过、是否路径错误。隐藏启动器没有界面，所以建议保留日志。

`apps`

软件列表。里面可以放多个程序，SilentLauncher 会按顺序启动。

## 单个软件配置

`name`

显示在日志里的名字。只影响日志，不影响启动。

`path`

要启动的 exe 路径，必填。支持绝对路径、相对路径和环境变量。

推荐使用绝对路径，例如：

```json
"path": "D:\\Apps\\Kavita\\Kavita.exe"
```

路径错误会导致启动失败，并写入日志。

`workingDirectory`

工作目录。很多绿色软件、服务端软件都依赖工作目录读取配置、插件或数据文件。

如果你不确定，通常填 exe 所在目录最稳：

```json
"workingDirectory": "D:\\Apps\\Kavita"
```

删除此项时，程序会自动使用 exe 所在目录。

`arguments`

启动参数。没有参数就写 `""` 或删除。

例如某些软件支持指定端口、配置目录、无界面模式，就可以写在这里。参数是否有效取决于目标软件本身。

`delaySeconds`

当前软件的单独延迟，单位是秒。

例如 Sideloadly 依赖 USB/iTunes 相关服务，你可以给它设置 `10` 或 `30`，让它晚一点启动。这个延迟会影响当前软件，也会让排在它后面的软件更晚启动。

`hideWindow`

是否隐藏目标软件窗口。

可选值：

```json
"hideWindow": true
"hideWindow": false
```

`true` 适合 Kavita、Jellyfin、后台常驻工具。`false` 适合需要你登录、确认、选择设备的软件。GUI 软件建议先设为 `false` 测试能正常启动，再改为 `true`。

`minimizeWindow`

是否最小化窗口。

如果 `hideWindow=true`，会优先隐藏，`minimizeWindow` 通常不会生效。想让软件在任务栏可见但不挡屏幕，就用：

```json
"hideWindow": false,
"minimizeWindow": true
```

`preventDuplicate`

是否防止重复启动。

`true` 表示如果同一路径的 exe 已经运行，就跳过。适合服务器和后台工具，防止计划任务重复触发导致多开。

`false` 表示每次都尝试启动新进程。只有你明确需要多开时才建议这样设置。

`waitForWindowMs`

等待目标软件主窗口出现的最长时间，单位是毫秒。

很多 GUI 软件不是一启动就有窗口，可能过几秒才创建窗口。这个值太小，窗口可能来不及被隐藏；这个值大一点，隐藏成功率更高。

常用值：

```json
"waitForWindowMs": 8000
"waitForWindowMs": 12000
"waitForWindowMs": 30000
```

`enabled`

是否启用这一项。

排查问题时可以改成 `false`，临时跳过某个软件，不用删除整段配置。

`useShellExecute`

是否使用 Windows Shell 启动。

默认建议：

```json
"useShellExecute": false
```

这时启动行为更可控，隐藏窗口和防重复逻辑更稳定。

如果某个软件直接启动失败，但你手动双击能启动，可以尝试：

```json
"useShellExecute": true
```

副作用是隐藏窗口的控制力可能变弱，因为它更接近“让 Windows 帮你双击打开”。

## 手动运行

使用同目录的 `launcher.json`：

```powershell
.\SilentLauncher.exe
```

指定配置文件：

```powershell
.\SilentLauncher.exe "D:\Launchers\launcher.json"
```

如果没有 `launcher.json`，SilentLauncher 会尝试启动同目录下第一个其他 `.exe`。这个模式适合把启动器直接放进某个软件目录，做成类似 `openjellfyin server.exe` 那样的单软件启动器。

## 创建计划任务

推荐使用“用户登录后启动”，不要用于“电脑开机但用户未登录”。GUI 软件需要当前用户桌面环境，未登录时强行启动容易失败或不可见。

```powershell
$exe = "D:\Launchers\SilentLauncher.exe"
$config = "D:\Launchers\launcher.json"

$action = New-ScheduledTaskAction -Execute $exe -Argument "`"$config`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel LeastPrivilege
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hours 0) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask -TaskName "SilentLauncher" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "登录后隐藏启动指定软件"
```

### 计划任务配置说明

`New-ScheduledTaskTrigger -AtLogOn`

表示用户登录后启动。适合 Sideloadly 这类 GUI 软件，因为它们需要桌面、托盘、用户配置和 USB 相关环境。

`-LogonType Interactive`

表示只在当前用户交互式登录后运行。这样程序运行在你的桌面会话里，隐藏/最小化窗口才有意义。

`-RunLevel LeastPrivilege`

普通权限运行。优点是更安全，也更接近你手动双击软件的状态。如果目标软件必须管理员权限，可以改成 `Highest`，但会带来 UAC/权限差异问题。

`-ExecutionTimeLimit (New-TimeSpan -Hours 0)`

不限制运行时间。虽然 SilentLauncher 自己启动完就退出，但这个设置可以避免 Windows 误判长任务超时。

`-RestartCount 3 -RestartInterval 1 minute`

如果任务启动失败，最多重试 3 次，每次间隔 1 分钟。能缓解刚登录时系统资源还没准备好的问题。

## 列出计划任务

查看相关任务：

```powershell
Get-ScheduledTask |
  Where-Object TaskName -match "SilentLauncher|Kavita|Sideloadly" |
  Select-Object TaskName,TaskPath,State
```

查看 SilentLauncher 上次运行结果：

```powershell
Get-ScheduledTaskInfo -TaskName "SilentLauncher"
```

## 删除计划任务

```powershell
Unregister-ScheduledTask -TaskName "SilentLauncher" -Confirm:$false
```

## 常见问题

### 软件启动了，但窗口没有隐藏

把 `waitForWindowMs` 调大，例如 `30000`。有些软件启动很慢，主窗口出现得晚。

如果还是不行，可能这个软件不是普通主窗口，或者启动后又创建了第二个窗口。外部隐藏工具不一定能控制所有窗口。

### 软件没有启动

先看 `SilentLauncher.log`。重点检查：

- `path` 是否写错。
- `workingDirectory` 是否正确。
- 软件是否需要管理员权限。
- 软件是否必须等网络、USB、磁盘准备好，可以调大 `startupDelaySeconds` 或 `delaySeconds`。

### 任务栏或托盘还有图标

隐藏主窗口不等于隐藏托盘图标。托盘图标是软件自己创建的，外部启动器通常不应该强行删除。否则可能影响软件状态、菜单和通知。

### Kavita 应该用这个还是 Windows Service

如果 Kavita 作为纯后台服务稳定运行，Windows Service 仍然更像服务器方案。

如果你更想要“像双击一样以当前用户启动，但窗口隐藏”，用 SilentLauncher 更合适。

### Sideloadly 应该用这个还是 Windows Service

Sideloadly 这类 GUI/设备相关软件，不建议做 Windows Service。推荐用计划任务登录后启动，再由 SilentLauncher 隐藏或最小化。
