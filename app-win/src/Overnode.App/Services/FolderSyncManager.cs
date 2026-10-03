using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Overnode.App.Models;

namespace Overnode.App.Services;

/// <summary>
/// Gestionnaire central orchestrant la synchronisation en temps réel entre les dossiers Windows
/// locaux et les dossiers distants hébergés sur les serveurs Overnode.
/// </summary>
public sealed class FolderSyncManager
{
    private static readonly Lazy<FolderSyncManager> _instance = new(() => new FolderSyncManager());
    public static FolderSyncManager Shared => _instance.Value;
    public static FolderSyncManager Instance => _instance.Value;

    private readonly string _storageFilePath;
    private readonly object _lock = new();
    private readonly Dictionary<string, SyncedFolderConfig> _configs = new(StringComparer.OrdinalIgnoreCase);
    private readonly Dictionary<string, FileSystemWatcher> _watchers = new(StringComparer.OrdinalIgnoreCase);
    private readonly Dictionary<string, Dictionary<string, LocalFileRecord>> _snapshots = new(StringComparer.OrdinalIgnoreCase);
    private readonly Dictionary<string, Timer> _debounceTimers = new(StringComparer.OrdinalIgnoreCase);
    private readonly ConcurrentDictionary<string, byte> _activeSyncs = new(StringComparer.OrdinalIgnoreCase);
    private readonly ConcurrentDictionary<string, byte> _internalDownloads = new(StringComparer.OrdinalIgnoreCase);

    public event EventHandler? ConfigChanged;
    public event Action<string, string, int>? FolderSynced; // serverId, folderName, totalCount

    public IReadOnlyList<SyncedFolderConfig> AllConfigs
    {
        get
        {
            lock (_lock)
            {
                return _configs.Values.ToList();
            }
        }
    }

    private FolderSyncManager()
    {
        string appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        string folder = Path.Combine(appData, "Overnode");
        Directory.CreateDirectory(folder);
        _storageFilePath = Path.Combine(folder, "synced_folders.json");

        LoadConfigs();
    }

    public static string NormalizeRemotePath(string? path)
    {
        if (string.IsNullOrWhiteSpace(path)) return "/";
        string p = path.Trim().Replace('\\', '/');
        while (p.Contains("//", StringComparison.Ordinal))
        {
            p = p.Replace("//", "/");
        }
        if (!p.StartsWith('/')) p = "/" + p;
        while (p.Length > 1 && p.EndsWith('/'))
        {
            p = p[..^1];
        }
        return p;
    }

    public bool IsFolderSynced(string serverId, string remotePath)
    {
        string norm = NormalizeRemotePath(remotePath);
        lock (_lock)
        {
            return _configs.Values.Any(c =>
                string.Equals(c.ServerId, serverId, StringComparison.OrdinalIgnoreCase) &&
                string.Equals(NormalizeRemotePath(c.RemotePath), norm, StringComparison.OrdinalIgnoreCase) &&
                c.IsEnabled);
        }
    }

    public SyncedFolderConfig? GetConfigFor(string serverId, string remotePath)
    {
        string norm = NormalizeRemotePath(remotePath);
        lock (_lock)
        {
            return _configs.Values.FirstOrDefault(c =>
                string.Equals(c.ServerId, serverId, StringComparison.OrdinalIgnoreCase) &&
                string.Equals(NormalizeRemotePath(c.RemotePath), norm, StringComparison.OrdinalIgnoreCase));
        }
    }

    public async Task<SyncedFolderConfig> RegisterSyncedFolderAsync(
        string serverId,
        string remotePath,
        string localPath,
        bool initialPull = true)
    {
        string norm = NormalizeRemotePath(remotePath);
        var config = new SyncedFolderConfig
        {
            ServerId = serverId,
            RemotePath = norm,
            LocalPath = Path.GetFullPath(localPath),
            IsEnabled = true,
            LastSyncDate = null
        };

        if (!Directory.Exists(config.LocalPath))
        {
            Directory.CreateDirectory(config.LocalPath);
        }

        lock (_lock)
        {
            _configs[config.Id] = config;
            SaveConfigs();
        }

        if (initialPull)
        {
            await FolderSyncExecutor.PullRemoteFilesAsync(
                serverId: config.ServerId,
                remotePath: config.RemotePath,
                localRoot: config.LocalPath,
                onDownloadStarted: p => _internalDownloads.TryAdd(p, 0),
                onDownloadCompleted: p => _internalDownloads.TryRemove(p, out _)
            );
        }

        lock (_lock)
        {
            _snapshots[config.Id] = FolderSyncScanner.Scan(config.LocalPath);
            StartWatcher(config);
        }

        ConfigChanged?.Invoke(this, EventArgs.Empty);
        return config;
    }

    public void StopSync(string configId)
    {
        lock (_lock)
        {
            if (_watchers.TryGetValue(configId, out var watcher))
            {
                try
                {
                    watcher.EnableRaisingEvents = false;
                    watcher.Dispose();
                }
                catch { }
                _watchers.Remove(configId);
            }

            if (_debounceTimers.TryGetValue(configId, out var timer))
            {
                timer.Dispose();
                _debounceTimers.Remove(configId);
            }

            _snapshots.Remove(configId);
            _configs.Remove(configId);
            SaveConfigs();
        }

        ConfigChanged?.Invoke(this, EventArgs.Empty);
    }

    public void OpenInExplorer(SyncedFolderConfig config)
    {
        if (Directory.Exists(config.LocalPath))
        {
            try
            {
                Process.Start(new ProcessStartInfo
                {
                    FileName = "explorer.exe",
                    Arguments = $"\"{config.LocalPath}\"",
                    UseShellExecute = true
                });
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"[FolderSyncManager] Open in explorer error: {ex.Message}");
            }
        }
    }

    public async Task ProcessLocalChangesAsync(string configId)
    {
        SyncedFolderConfig? config;
        lock (_lock)
        {
            if (!_configs.TryGetValue(configId, out config) || !config.IsEnabled)
            {
                return;
            }
        }

        if (!_activeSyncs.TryAdd(configId, 0))
        {
            return;
        }

        try
        {
            Dictionary<string, LocalFileRecord> oldSnap;
            lock (_lock)
            {
                _snapshots.TryGetValue(configId, out oldSnap!);
                oldSnap ??= new Dictionary<string, LocalFileRecord>(StringComparer.OrdinalIgnoreCase);
            }

            var currentSnap = FolderSyncScanner.Scan(config.LocalPath);
            var diff = FolderSyncScanner.Diff(oldSnap, currentSnap);

            if (!diff.HasChanges)
            {
                return;
            }

            // Exclure les fichiers venant d'être téléchargés
            var filesToUpload = diff.AddedOrModifiedFiles.Where(rec =>
            {
                string fullLocal = Path.Combine(config.LocalPath, rec.RelativePath.Replace('/', Path.DirectorySeparatorChar));
                return !_internalDownloads.ContainsKey(fullLocal);
            }).ToList();

            // 1. Créer les sous-dossiers distants d'abord
            await FolderSyncExecutor.CreateRemoteDirectoriesAsync(config.ServerId, config.RemotePath, diff.AddedDirectories);

            // 2. Téléverser les fichiers ajoutés ou modifiés
            await FolderSyncExecutor.UploadChangedFilesAsync(config.ServerId, config.RemotePath, config.LocalPath, filesToUpload);

            // 3. Supprimer les éléments retirés localement
            await FolderSyncExecutor.DeleteRemotePathsAsync(config.ServerId, config.RemotePath, diff.DeletedPaths);

            lock (_lock)
            {
                _snapshots[configId] = currentSnap;
                config.LastSyncDate = DateTime.UtcNow;
                SaveConfigs();
            }

            FolderSynced?.Invoke(config.ServerId, config.FolderName, diff.TotalCount);
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"[FolderSyncManager] ProcessLocalChangesAsync error: {ex.Message}");
        }
        finally
        {
            _activeSyncs.TryRemove(configId, out _);
        }
    }

    private void StartWatcher(SyncedFolderConfig config)
    {
        if (!Directory.Exists(config.LocalPath)) return;

        try
        {
            var watcher = new FileSystemWatcher(config.LocalPath)
            {
                IncludeSubdirectories = true,
                NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.FileName | NotifyFilters.DirectoryName | NotifyFilters.Size | NotifyFilters.CreationTime,
                EnableRaisingEvents = true
            };

            string configId = config.Id;

            watcher.Changed += (s, e) => ScheduleDebouncedSync(configId);
            watcher.Created += (s, e) => ScheduleDebouncedSync(configId);
            watcher.Deleted += (s, e) => ScheduleDebouncedSync(configId);
            watcher.Renamed += (s, e) => ScheduleDebouncedSync(configId);
            watcher.Error += (s, e) =>
            {
                Debug.WriteLine($"[FolderSyncWatcher] Error for {config.LocalPath}: {e.GetException()?.Message}");
                try
                {
                    watcher.EnableRaisingEvents = false;
                    watcher.EnableRaisingEvents = true;
                }
                catch { }
            };

            _watchers[config.Id] = watcher;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"[FolderSyncManager] Failed to start watcher for {config.LocalPath}: {ex.Message}");
        }
    }

    private void ScheduleDebouncedSync(string configId)
    {
        lock (_lock)
        {
            if (!_configs.TryGetValue(configId, out var config) || !config.IsEnabled)
            {
                return;
            }

            if (_debounceTimers.TryGetValue(configId, out var oldTimer))
            {
                oldTimer.Dispose();
            }

            _debounceTimers[configId] = new Timer(async _ =>
            {
                await ProcessLocalChangesAsync(configId);
            }, null, 500, Timeout.Infinite);
        }
    }

    private void LoadConfigs()
    {
        try
        {
            if (File.Exists(_storageFilePath))
            {
                string json = File.ReadAllText(_storageFilePath);
                var list = JsonSerializer.Deserialize<List<SyncedFolderConfig>>(json);
                if (list != null)
                {
                    lock (_lock)
                    {
                        foreach (var cfg in list)
                        {
                            _configs[cfg.Id] = cfg;
                            if (cfg.IsEnabled && Directory.Exists(cfg.LocalPath))
                            {
                                _snapshots[cfg.Id] = FolderSyncScanner.Scan(cfg.LocalPath);
                                StartWatcher(cfg);
                            }
                        }
                    }
                }
            }
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"[FolderSyncManager] LoadConfigs error: {ex.Message}");
        }
    }

    private void SaveConfigs()
    {
        try
        {
            var list = _configs.Values.ToList();
            string json = JsonSerializer.Serialize(list, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(_storageFilePath, json);
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"[FolderSyncManager] SaveConfigs error: {ex.Message}");
        }
    }
}
