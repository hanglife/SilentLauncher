using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace SilentLauncher;

internal static class Program
{
    private const int SW_HIDE = 0;
    private const int SW_SHOWNORMAL = 1;
    private const int SW_SHOWMINIMIZED = 2;

    [DllImport("user32.dll")]
    private static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);

    private static async Task<int> Main(string[] args)
    {
        var baseDir = AppContext.BaseDirectory;
        var configPath = args.Length > 0 ? Path.GetFullPath(args[0]) : Path.Combine(baseDir, "launcher.json");

        try
        {
            if (!File.Exists(configPath))
            {
                var singleExe = FindSingleTargetExe(baseDir);
                if (singleExe is null)
                {
                    WriteFallbackLog(baseDir, $"Config not found: {configPath}");
                    return 2;
                }

                await StartAppAsync(new AppEntry
                {
                    Name = Path.GetFileNameWithoutExtension(singleExe),
                    Path = singleExe,
                    WorkingDirectory = Path.GetDirectoryName(singleExe),
                    HideWindow = true,
                    PreventDuplicate = true,
                    WaitForWindowMs = 8000
                }, baseDir);

                return 0;
            }

            var config = await LoadConfigAsync(configPath);
            var logPath = ResolvePath(config.LogFile, Path.GetDirectoryName(configPath) ?? baseDir, allowMissing: true);

            await LogAsync(logPath, $"SilentLauncher started. Config={configPath}");

            if (config.StartupDelaySeconds > 0)
                await Task.Delay(TimeSpan.FromSeconds(config.StartupDelaySeconds));

            foreach (var app in config.Apps.Where(app => app.Enabled))
            {
                try
                {
                    await StartAppAsync(app, Path.GetDirectoryName(configPath) ?? baseDir, logPath);
                }
                catch (Exception ex)
                {
                    await LogAsync(logPath, $"[{app.NameOrPath}] ERROR: {ex}");
                }
            }

            await LogAsync(logPath, "SilentLauncher finished.");
            return 0;
        }
        catch (Exception ex)
        {
            WriteFallbackLog(baseDir, ex.ToString());
            return 1;
        }
    }

    private static async Task<LauncherConfig> LoadConfigAsync(string configPath)
    {
        await using var stream = File.OpenRead(configPath);
        var config = await JsonSerializer.DeserializeAsync<LauncherConfig>(stream, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true,
            ReadCommentHandling = JsonCommentHandling.Skip,
            AllowTrailingCommas = true
        });

        if (config is null)
            throw new InvalidOperationException("launcher.json is empty or invalid.");

        return config;
    }

    private static async Task StartAppAsync(AppEntry app, string configDir, string? logPath = null)
    {
        var exePath = ResolvePath(app.Path, configDir)
                      ?? throw new InvalidOperationException($"Missing executable path for {app.NameOrPath}.");
        var workingDir = ResolvePath(app.WorkingDirectory, configDir, allowMissing: true)
                         ?? Path.GetDirectoryName(exePath)
                         ?? configDir;

        if (app.PreventDuplicate && IsAlreadyRunning(exePath))
        {
            await LogAsync(logPath, $"[{app.NameOrPath}] skipped: already running.");
            return;
        }

        if (app.DelaySeconds > 0)
            await Task.Delay(TimeSpan.FromSeconds(app.DelaySeconds));

        var startInfo = new ProcessStartInfo
        {
            FileName = exePath,
            Arguments = app.Arguments ?? string.Empty,
            WorkingDirectory = workingDir,
            UseShellExecute = app.UseShellExecute,
            CreateNoWindow = app.HideWindow,
            WindowStyle = app.HideWindow ? ProcessWindowStyle.Hidden :
                          app.MinimizeWindow ? ProcessWindowStyle.Minimized :
                          ProcessWindowStyle.Normal
        };

        var process = Process.Start(startInfo);
        if (process is null)
        {
            await LogAsync(logPath, $"[{app.NameOrPath}] failed: Process.Start returned null.");
            return;
        }

        await LogAsync(logPath, $"[{app.NameOrPath}] started. PID={process.Id}");

        if (app.HideWindow || app.MinimizeWindow)
        {
            await ApplyWindowModeAsync(process, app.HideWindow ? SW_HIDE : SW_SHOWMINIMIZED, app.WaitForWindowMs);
        }
        else
        {
            ShowWindowAsync(process.MainWindowHandle, SW_SHOWNORMAL);
        }
    }

    private static async Task ApplyWindowModeAsync(Process process, int command, int waitForWindowMs)
    {
        var timeout = TimeSpan.FromMilliseconds(Math.Max(waitForWindowMs, 0));
        var watch = Stopwatch.StartNew();

        while (watch.Elapsed <= timeout)
        {
            if (process.HasExited)
                return;

            process.Refresh();
            if (process.MainWindowHandle != IntPtr.Zero)
            {
                ShowWindowAsync(process.MainWindowHandle, command);
                return;
            }

            await Task.Delay(250);
        }
    }

    private static bool IsAlreadyRunning(string exePath)
    {
        var target = Path.GetFullPath(exePath);
        var processName = Path.GetFileNameWithoutExtension(target);

        foreach (var process in Process.GetProcessesByName(processName))
        {
            try
            {
                if (string.Equals(process.MainModule?.FileName, target, StringComparison.OrdinalIgnoreCase))
                    return true;
            }
            catch
            {
                // Access to MainModule can fail for protected/elevated processes. Ignore and continue.
            }
        }

        return false;
    }

    private static string? FindSingleTargetExe(string baseDir)
    {
        var self = Process.GetCurrentProcess().MainModule?.FileName;

        return Directory.EnumerateFiles(baseDir, "*.exe", SearchOption.TopDirectoryOnly)
            .Where(path => !string.Equals(path, self, StringComparison.OrdinalIgnoreCase))
            .Where(path => !string.Equals(Path.GetFileName(path), "SilentLauncher.exe", StringComparison.OrdinalIgnoreCase))
            .OrderBy(path => path, StringComparer.OrdinalIgnoreCase)
            .FirstOrDefault();
    }

    private static string? ResolvePath(string? path, string baseDir, bool allowMissing = false)
    {
        if (string.IsNullOrWhiteSpace(path))
            return null;

        var expanded = Environment.ExpandEnvironmentVariables(path);
        var fullPath = Path.IsPathRooted(expanded) ? expanded : Path.GetFullPath(Path.Combine(baseDir, expanded));

        if (!allowMissing && !File.Exists(fullPath))
            throw new FileNotFoundException($"File not found: {fullPath}", fullPath);

        return fullPath;
    }

    private static async Task LogAsync(string? logPath, string message)
    {
        if (string.IsNullOrWhiteSpace(logPath))
            return;

        var line = $"{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff} {message}{Environment.NewLine}";
        Directory.CreateDirectory(Path.GetDirectoryName(logPath) ?? AppContext.BaseDirectory);
        await File.AppendAllTextAsync(logPath, line);
    }

    private static void WriteFallbackLog(string baseDir, string message)
    {
        try
        {
            var path = Path.Combine(baseDir, "SilentLauncher-error.log");
            File.AppendAllText(path, $"{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff} {message}{Environment.NewLine}");
        }
        catch
        {
            // Nothing else to do: this app intentionally has no UI.
        }
    }
}

internal sealed class LauncherConfig
{
    public int StartupDelaySeconds { get; set; }
    public string? LogFile { get; set; } = "SilentLauncher.log";
    public List<AppEntry> Apps { get; set; } = [];
}

internal sealed class AppEntry
{
    public string? Name { get; set; }
    public string Path { get; set; } = "";
    public string? Arguments { get; set; }
    public string? WorkingDirectory { get; set; }
    public int DelaySeconds { get; set; }
    public int WaitForWindowMs { get; set; } = 8000;
    public bool Enabled { get; set; } = true;
    public bool HideWindow { get; set; } = true;
    public bool MinimizeWindow { get; set; }
    public bool PreventDuplicate { get; set; } = true;
    public bool UseShellExecute { get; set; }

    [JsonIgnore]
    public string NameOrPath => string.IsNullOrWhiteSpace(Name) ? Path : Name;
}
