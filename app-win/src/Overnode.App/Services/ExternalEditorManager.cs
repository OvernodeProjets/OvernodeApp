using System;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

namespace Overnode.App.Services;

/// <summary>
/// Manages staging server files locally, opening them with Windows shell-associated text editors,
/// and synchronizing modifications back to the remote server automatically.
/// </summary>
public sealed class ExternalEditorManager
{
    private static readonly Lazy<ExternalEditorManager> _instance = new(() => new ExternalEditorManager());
    public static ExternalEditorManager Instance => _instance.Value;
    public static ExternalEditorManager Shared => _instance.Value;

    private const string SettingKey = "overnode_always_open_external_editor";
    private readonly string _settingsFilePath;
    private bool _alwaysOpenInExternalEditor;

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
                if (doc.RootElement.TryGetProperty(SettingKey, out var prop))
                {
                    _alwaysOpenInExternalEditor = prop.GetBoolean();
                }
            }
        }
        catch
        {
            _alwaysOpenInExternalEditor = false;
        }
    }

    private void SaveSettings()
    {
        try
        {
            var data = new { overnode_always_open_external_editor = _alwaysOpenInExternalEditor };
            string json = JsonSerializer.Serialize(data, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(_settingsFilePath, json);
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"[ExternalEditorManager] Failed to save settings: {ex.Message}");
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

        // 3. Open file using Windows default association for its extension
        try
        {
            var startInfo = new ProcessStartInfo(localFilePath)
            {
                UseShellExecute = true
            };
            Process.Start(startInfo);
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"[ExternalEditorManager] Failed to launch editor for {localFilePath}: {ex.Message}");
            // Fallback: try notepad.exe if shell execution fails
            try
            {
                Process.Start(new ProcessStartInfo("notepad.exe", $"\"{localFilePath}\"") { UseShellExecute = true });
            }
            catch { }
        }

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

    private sealed class ExternalEditSession : IDisposable
    {
        public string ServerId { get; }
        public string RemotePath { get; }
        public string FileName { get; }
        public string LocalFilePath { get; }

        private readonly Func<string, Task> _onSave;
        private readonly Action<string, string> _onFileSynced;
        private string _lastKnownContent;
        private FileSystemWatcher? _watcher;
        private Timer? _debounceTimer;
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
            _lastKnownContent = initialContent;
            _onSave = onSave;
            _onFileSynced = onFileSynced;
        }

        public void Start()
        {
            try
            {
                string? dir = Path.GetDirectoryName(LocalFilePath);
                if (string.IsNullOrEmpty(dir) || !Directory.Exists(dir)) return;

                _watcher = new FileSystemWatcher(dir, Path.GetFileName(LocalFilePath))
                {
                    NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.Size | NotifyFilters.FileName,
                    EnableRaisingEvents = true
                };

                _watcher.Changed += OnFileChanged;
                _watcher.Created += OnFileChanged;
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"[ExternalEditorSession] Watcher init error: {ex.Message}");
            }
        }

        private void OnFileChanged(object sender, FileSystemEventArgs e)
        {
            if (_disposed) return;

            // Debounce saves by 500ms
            _debounceTimer?.Dispose();
            _debounceTimer = new Timer(async _ => await SyncBackAsync(), null, 500, Timeout.Infinite);
        }

        private async Task SyncBackAsync()
        {
            if (_disposed) return;
            if (Interlocked.CompareExchange(ref _isSyncing, 1, 0) != 0) return;

            try
            {
                if (!File.Exists(LocalFilePath)) return;

                string? currentContent = null;
                // Retry reading up to 3 times in case the external editor holds an exclusive lock momentarily
                for (int attempt = 0; attempt < 3; attempt++)
                {
                    try
                    {
                        using var stream = new FileStream(LocalFilePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
                        using var reader = new StreamReader(stream, Encoding.UTF8);
                        currentContent = await reader.ReadToEndAsync();
                        break;
                    }
                    catch (IOException)
                    {
                        await Task.Delay(150);
                    }
                }

                if (currentContent == null || currentContent == _lastKnownContent)
                {
                    return;
                }

                _lastKnownContent = currentContent;
                await _onSave(currentContent);
                _onFileSynced(ServerId, FileName);
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
            _debounceTimer?.Dispose();
            if (_watcher != null)
            {
                _watcher.EnableRaisingEvents = false;
                _watcher.Changed -= OnFileChanged;
                _watcher.Created -= OnFileChanged;
                _watcher.Dispose();
                _watcher = null;
            }
        }
    }
}
