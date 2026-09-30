using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

namespace Overnode.App.Services;

/// <summary>
/// Detected editor description for settings UI and launching.
/// </summary>
public record DetectedEditor(string Name, string Path, bool IsDefault);

/// <summary>
/// Manages staging server files locally, opening them with Windows text/code editors (never CMD),
/// and synchronizing modifications back to the remote server automatically upon save.
/// </summary>
public sealed class ExternalEditorManager
{
    private static readonly Lazy<ExternalEditorManager> _instance = new(() => new ExternalEditorManager());
    public static ExternalEditorManager Instance => _instance.Value;
    public static ExternalEditorManager Shared => _instance.Value;

    private const string SettingAlwaysOpenKey = "overnode_always_open_external_editor";
    private const string SettingEditorPathKey = "overnode_external_editor_app_path";
    private const string SettingEditorNameKey = "overnode_external_editor_app_name";

    private readonly string _settingsFilePath;
    private bool _alwaysOpenInExternalEditor;
    private string? _selectedEditorAppPath;
    private string? _selectedEditorAppName;

    private readonly ConcurrentDictionary<string, ExternalEditSession> _activeSessions = new();

    public event EventHandler? DidChange;
    public event Action<string, string>? FileSynced; // serverId, fileName

    public bool AlwaysOpenInExternalEditor
    {
        get => _alwaysOpenInExternalEditor;
        set
        {
            if (_alwaysOpenInExternalEditor != value)
            {
                _alwaysOpenInExternalEditor = value;
                SaveSettings();
                DidChange?.Invoke(this, EventArgs.Empty);
            }
        }
    }

    public string? SelectedEditorAppPath
    {
        get => _selectedEditorAppPath;
        set
        {
            string? normalized = string.IsNullOrWhiteSpace(value) ? null : value.Trim();
            if (_selectedEditorAppPath != normalized)
            {
                _selectedEditorAppPath = normalized;
                if (!string.IsNullOrEmpty(normalized) && File.Exists(normalized))
                {
                    try
                    {
                        var info = FileVersionInfo.GetVersionInfo(normalized);
                        _selectedEditorAppName = !string.IsNullOrWhiteSpace(info.FileDescription)
                            ? info.FileDescription
                            : Path.GetFileNameWithoutExtension(normalized);
                    }
                    catch
                    {
                        _selectedEditorAppName = Path.GetFileNameWithoutExtension(normalized);
                    }
                }
                else
                {
                    _selectedEditorAppName = null;
                }

                SaveSettings();
                DidChange?.Invoke(this, EventArgs.Empty);
            }
        }
    }

    public string? SelectedEditorAppName => _selectedEditorAppName;

    private ExternalEditorManager()
    {
        string appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        string folder = Path.Combine(appData, "Overnode");
        Directory.CreateDirectory(folder);
        _settingsFilePath = Path.Combine(folder, "external_editor.json");

        LoadSettings();
    }

    private void LoadSettings()
    {
        try
        {
            if (File.Exists(_settingsFilePath))
            {
                string json = File.ReadAllText(_settingsFilePath);
                var doc = JsonDocument.Parse(json);
                if (doc.RootElement.TryGetProperty(SettingAlwaysOpenKey, out var propAlways))
                {
                    _alwaysOpenInExternalEditor = propAlways.GetBoolean();
                }
                if (doc.RootElement.TryGetProperty(SettingEditorPathKey, out var propPath))
                {
                    _selectedEditorAppPath = propPath.GetString();
                }
                if (doc.RootElement.TryGetProperty(SettingEditorNameKey, out var propName))
                {
                    _selectedEditorAppName = propName.GetString();
                }
            }
        }
        catch
        {
            _alwaysOpenInExternalEditor = false;
            _selectedEditorAppPath = null;
            _selectedEditorAppName = null;
        }
    }

    private void SaveSettings()
    {
        try
        {
            var data = new Dictionary<string, object?>
            {
                [SettingAlwaysOpenKey] = _alwaysOpenInExternalEditor,
                [SettingEditorPathKey] = _selectedEditorAppPath,
                [SettingEditorNameKey] = _selectedEditorAppName
            };
            string json = JsonSerializer.Serialize(data, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(_settingsFilePath, json);
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"[ExternalEditorManager] Failed to save settings: {ex.Message}");
        }
    }

    /// <summary>
    /// Returns the list of detected text/code editors installed on the current machine.
    /// </summary>
    public List<DetectedEditor> GetDetectedEditors()
    {
        var editors = new List<DetectedEditor>();
        var seenPaths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        // 1. VS Code
        string? vsCode = FindVsCode();
        if (!string.IsNullOrEmpty(vsCode) && File.Exists(vsCode) && seenPaths.Add(vsCode))
        {
            editors.Add(new DetectedEditor("Visual Studio Code", vsCode, IsDefault: true));
        }

        // 2. Notepad++
        string? npp = FindNotepadPlusPlus();
        if (!string.IsNullOrEmpty(npp) && File.Exists(npp) && seenPaths.Add(npp))
        {
            editors.Add(new DetectedEditor("Notepad++", npp, IsDefault: false));
        }

        // 3. Sublime Text
        string? sublime = FindSublimeText();
        if (!string.IsNullOrEmpty(sublime) && File.Exists(sublime) && seenPaths.Add(sublime))
        {
            editors.Add(new DetectedEditor("Sublime Text", sublime, IsDefault: false));
        }

        // 4. Windows Notepad
        string notepad = FindWindowsNotepad();
        if (seenPaths.Add(notepad))
        {
            editors.Add(new DetectedEditor("Bloc-notes Windows (Notepad)", notepad, IsDefault: editors.Count == 0));
        }

        return editors;
    }

    /// <summary>
    /// Resolves the absolute path to the editor executable to launch.
    /// Never returns cmd.exe or a raw script.
    /// </summary>
    public string ResolveEditorExecutable()
    {
        if (!string.IsNullOrWhiteSpace(_selectedEditorAppPath) && File.Exists(_selectedEditorAppPath))
        {
            return _selectedEditorAppPath;
        }

        string? vsCode = FindVsCode();
        if (!string.IsNullOrEmpty(vsCode) && File.Exists(vsCode))
        {
            return vsCode;
        }

        string? npp = FindNotepadPlusPlus();
        if (!string.IsNullOrEmpty(npp) && File.Exists(npp))
        {
            return npp;
        }

        string? sublime = FindSublimeText();
        if (!string.IsNullOrEmpty(sublime) && File.Exists(sublime))
        {
            return sublime;
        }

        return FindWindowsNotepad();
    }

    private static string? FindVsCode()
    {
        string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        string programFiles = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
        string programFilesX86 = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86);

        string p1 = Path.Combine(localAppData, "Programs", "Microsoft VS Code", "Code.exe");
        if (File.Exists(p1)) return p1;

        string p2 = Path.Combine(programFiles, "Microsoft VS Code", "Code.exe");
        if (File.Exists(p2)) return p2;

        if (!string.IsNullOrEmpty(programFilesX86))
        {
            string p3 = Path.Combine(programFilesX86, "Microsoft VS Code", "Code.exe");
            if (File.Exists(p3)) return p3;
        }

        string? fromPath = FindExecutableInPath("Code.exe");
        if (!string.IsNullOrEmpty(fromPath) && File.Exists(fromPath)) return fromPath;

        string? cmdPath = FindExecutableInPath("code.cmd");
        if (!string.IsNullOrEmpty(cmdPath))
        {
            string? binDir = Path.GetDirectoryName(cmdPath);
            if (!string.IsNullOrEmpty(binDir))
            {
                string sibling = Path.GetFullPath(Path.Combine(binDir, "..", "Code.exe"));
                if (File.Exists(sibling)) return sibling;
            }
        }

        return null;
    }

    private static string? FindNotepadPlusPlus()
    {
        string programFiles = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
        string programFilesX86 = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86);

        string p1 = Path.Combine(programFiles, "Notepad++", "notepad++.exe");
        if (File.Exists(p1)) return p1;

        if (!string.IsNullOrEmpty(programFilesX86))
        {
            string p2 = Path.Combine(programFilesX86, "Notepad++", "notepad++.exe");
            if (File.Exists(p2)) return p2;
        }

        return FindExecutableInPath("notepad++.exe");
    }

    private static string? FindSublimeText()
    {
        string programFiles = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
        string p1 = Path.Combine(programFiles, "Sublime Text", "sublime_text.exe");
        if (File.Exists(p1)) return p1;
        return FindExecutableInPath("sublime_text.exe");
    }

    private static string FindWindowsNotepad()
    {
        string systemRoot = Environment.GetFolderPath(Environment.SpecialFolder.Windows);
        string notepad = Path.Combine(systemRoot, "System32", "notepad.exe");
        if (File.Exists(notepad)) return notepad;
        return "notepad.exe";
    }

    private static string? FindExecutableInPath(string exeName)
    {
        try
        {
            string? pathEnv = Environment.GetEnvironmentVariable("PATH");
            if (string.IsNullOrEmpty(pathEnv)) return null;

            var paths = pathEnv.Split(Path.PathSeparator, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
            foreach (var p in paths)
            {
                try
                {
                    string candidate = Path.Combine(p, exeName);
                    if (File.Exists(candidate))
                    {
                        return candidate;
                    }
                }
                catch { }
            }
        }
        catch { }
        return null;
    }

    /// <summary>
    /// Launches the resolved editor executable with the target file without showing any CMD window.
    /// </summary>
    public bool LaunchEditor(string localFilePath)
    {
        string editorPath = ResolveEditorExecutable();

        try
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = editorPath,
                Arguments = $"\"{localFilePath}\"",
                UseShellExecute = false,
                CreateNoWindow = true,
                WindowStyle = ProcessWindowStyle.Normal
            };
            var proc = Process.Start(startInfo);
            return proc != null;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"[ExternalEditorManager] Failed to launch editor '{editorPath}': {ex.Message}");
            try
            {
                var fallbackInfo = new ProcessStartInfo
                {
                    FileName = "notepad.exe",
                    Arguments = $"\"{localFilePath}\"",
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    WindowStyle = ProcessWindowStyle.Normal
                };
                var proc = Process.Start(fallbackInfo);
                return proc != null;
            }
            catch (Exception fallbackEx)
            {
                Debug.WriteLine($"[ExternalEditorManager] Fallback notepad launch also failed: {fallbackEx.Message}");
                return false;
            }
        }
    }

    public async Task<string> OpenAndWatchFileAsync(
        string serverId,
        string remotePath,
        string fileName,
        string initialContent,
        Func<string, Task>? onSave = null)
    {
        // 1. Prepare local staging directory
        string stagingDir = Path.Combine(Path.GetTempPath(), "Overnode", "ExternalEdits", serverId, Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(stagingDir);

        string localFilePath = Path.Combine(stagingDir, fileName);
        await File.WriteAllTextAsync(localFilePath, initialContent ?? string.Empty, Encoding.UTF8);

        // 2. Register active session
        string sessionKey = $"{serverId}:{remotePath}";
        if (_activeSessions.TryRemove(sessionKey, out var oldSession))
        {
            oldSession.Dispose();
        }

        var session = new ExternalEditSession(
            serverId,
            remotePath,
            fileName,
            localFilePath,
            initialContent ?? string.Empty,
            onSave ?? (async (newContent) =>
            {
                await ServerFilesService.Shared.WriteFileAsync(serverId, remotePath, newContent);
            }),
            (sId, fName) => FileSynced?.Invoke(sId, fName)
        );

        _activeSessions[sessionKey] = session;
        session.Start();

        // 3. Open file in GUI editor without showing any CMD prompt
        LaunchEditor(localFilePath);

        return localFilePath;
    }

    public void StopWatching(string serverId, string remotePath)
    {
        string sessionKey = $"{serverId}:{remotePath}";
        if (_activeSessions.TryRemove(sessionKey, out var session))
        {
            session.Dispose();
        }
    }

    public void PurgeAllTemporaryFiles()
    {
        foreach (var kvp in _activeSessions)
        {
            kvp.Value.Dispose();
        }
        _activeSessions.Clear();

        try
        {
            string baseDir = Path.Combine(Path.GetTempPath(), "Overnode", "ExternalEdits");
            if (Directory.Exists(baseDir))
            {
                Directory.Delete(baseDir, true);
            }
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"[ExternalEditorManager] Error purging temporary files: {ex.Message}");
        }
    }

    /// <summary>
    /// Staged file session monitoring local saves and syncing changes to the remote server.
    /// Combines FileSystemWatcher (including Renamed for atomic saves) with a periodic polling
    /// heartbeat to guarantee that saves are never missed.
    /// </summary>
    public sealed class ExternalEditSession : IDisposable
    {
        public string ServerId { get; }
        public string RemotePath { get; }
        public string FileName { get; }
        public string LocalFilePath { get; }

        private readonly Func<string, Task> _onSave;
        private readonly Action<string, string> _onFileSynced;
        private string _lastKnownContent;
        private DateTime _lastKnownWriteTime;
        private long _lastKnownLength;
        private FileSystemWatcher? _watcher;
        private Timer? _debounceTimer;
        private Timer? _pollingTimer;
        private readonly object _syncLock = new();
        private int _isSyncing;
        private bool _disposed;

        public ExternalEditSession(
            string serverId,
            string remotePath,
            string fileName,
            string localFilePath,
            string initialContent,
            Func<string, Task> onSave,
            Action<string, string> onFileSynced)
        {
            ServerId = serverId;
            RemotePath = remotePath;
            FileName = fileName;
            LocalFilePath = localFilePath;
            _lastKnownContent = initialContent ?? string.Empty;
            _onSave = onSave;
            _onFileSynced = onFileSynced;

            if (File.Exists(localFilePath))
            {
                _lastKnownWriteTime = File.GetLastWriteTimeUtc(localFilePath);
                _lastKnownLength = new FileInfo(localFilePath).Length;
            }
        }

        public void Start()
        {
            try
            {
                string? dir = Path.GetDirectoryName(LocalFilePath);
                string targetFileName = Path.GetFileName(LocalFilePath);

                if (!string.IsNullOrEmpty(dir) && Directory.Exists(dir))
                {
                    _watcher = new FileSystemWatcher(dir)
                    {
                        Filter = targetFileName,
                        NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.Size | NotifyFilters.FileName | NotifyFilters.CreationTime,
                        EnableRaisingEvents = true
                    };

                    _watcher.Changed += OnFileChanged;
                    _watcher.Created += OnFileChanged;
                    _watcher.Renamed += OnFileRenamed;
                    _watcher.Error += OnWatcherError;
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"[ExternalEditorSession] Watcher init error: {ex.Message}");
            }

            // Fallback polling timer every 1000ms to guarantee capture of atomic editor saves
            _pollingTimer = new Timer(async _ =>
            {
                await CheckFileModificationsAsync();
            }, null, TimeSpan.FromSeconds(1), TimeSpan.FromSeconds(1));
        }

        private void OnFileChanged(object sender, FileSystemEventArgs e)
        {
            if (_disposed) return;
            TriggerDebouncedSync();
        }

        private void OnFileRenamed(object sender, RenamedEventArgs e)
        {
            if (_disposed) return;
            if (string.Equals(e.Name, Path.GetFileName(LocalFilePath), StringComparison.OrdinalIgnoreCase) ||
                string.Equals(e.FullPath, LocalFilePath, StringComparison.OrdinalIgnoreCase))
            {
                TriggerDebouncedSync();
            }
        }

        private void OnWatcherError(object sender, ErrorEventArgs e)
        {
            Debug.WriteLine($"[ExternalEditorSession] Watcher error: {e.GetException()?.Message}");
            try
            {
                if (_watcher != null && !_disposed)
                {
                    _watcher.EnableRaisingEvents = false;
                    _watcher.EnableRaisingEvents = true;
                }
            }
            catch { }
        }

        private void TriggerDebouncedSync()
        {
            if (_disposed) return;
            lock (_syncLock)
            {
                _debounceTimer?.Dispose();
                _debounceTimer = new Timer(async _ => await SyncBackAsync(), null, 350, Timeout.Infinite);
            }
        }

        private async Task CheckFileModificationsAsync()
        {
            if (_disposed || _isSyncing != 0) return;
            if (!File.Exists(LocalFilePath)) return;

            try
            {
                var writeTime = File.GetLastWriteTimeUtc(LocalFilePath);
                long length = new FileInfo(LocalFilePath).Length;

                if (writeTime != _lastKnownWriteTime || length != _lastKnownLength)
                {
                    await SyncBackAsync();
                }
            }
            catch { }
        }

        public async Task SyncBackAsync()
        {
            if (_disposed) return;
            if (Interlocked.CompareExchange(ref _isSyncing, 1, 0) != 0) return;

            try
            {
                if (!File.Exists(LocalFilePath)) return;

                string? currentContent = null;
                // Retry reading up to 8 times with 120ms delays to accommodate momentary editor file locks
                for (int attempt = 0; attempt < 8; attempt++)
                {
                    try
                    {
                        using var stream = new FileStream(LocalFilePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete);
                        using var reader = new StreamReader(stream, Encoding.UTF8);
                        currentContent = await reader.ReadToEndAsync();
                        break;
                    }
                    catch (IOException)
                    {
                        await Task.Delay(120);
                    }
                    catch (UnauthorizedAccessException)
                    {
                        await Task.Delay(120);
                    }
                }

                if (currentContent == null || currentContent == _lastKnownContent)
                {
                    return;
                }

                _lastKnownContent = currentContent;
                if (File.Exists(LocalFilePath))
                {
                    _lastKnownWriteTime = File.GetLastWriteTimeUtc(LocalFilePath);
                    _lastKnownLength = new FileInfo(LocalFilePath).Length;
                }

                Debug.WriteLine($"[ExternalEditorSession] Local file {FileName} modified, uploading to server {ServerId}...");
                await _onSave(currentContent);
                _onFileSynced(ServerId, FileName);
                Debug.WriteLine($"[ExternalEditorSession] Successfully uploaded {FileName} to server {ServerId}!");
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"[ExternalEditorSession] Error auto-syncing {FileName}: {ex.Message}");
            }
            finally
            {
                Interlocked.Exchange(ref _isSyncing, 0);
            }
        }

        public void Dispose()
        {
            _disposed = true;
            lock (_syncLock)
            {
                _debounceTimer?.Dispose();
                _debounceTimer = null;
            }

            _pollingTimer?.Dispose();
            _pollingTimer = null;

            if (_watcher != null)
            {
                try
                {
                    _watcher.EnableRaisingEvents = false;
                    _watcher.Changed -= OnFileChanged;
                    _watcher.Created -= OnFileChanged;
                    _watcher.Renamed -= OnFileRenamed;
                    _watcher.Error -= OnWatcherError;
                    _watcher.Dispose();
                }
                catch { }
                _watcher = null;
            }
        }
    }
}
