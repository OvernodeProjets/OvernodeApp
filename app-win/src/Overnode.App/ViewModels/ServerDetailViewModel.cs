using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.Services;

namespace Overnode.App.ViewModels;

public partial class ServerDetailViewModel : ObservableObject
{
    private readonly ServerService _serverService = ServerService.Shared;
    private readonly ServerFilesService _filesService = ServerFilesService.Shared;
    private readonly ServerConfigService _configService = ServerConfigService.Shared;

    [ObservableProperty]
    private ServerInstance _server;

    [ObservableProperty]
    private ServerTab _selectedTab = ServerTab.Console;

    [ObservableProperty]
    private bool _isLoading;

    [ObservableProperty]
    private string? _errorMessage;

    [ObservableProperty]
    private string? _successMessage;

    // Console & Power
    [ObservableProperty]
    private ObservableCollection<string> _consoleLines = new();

    [ObservableProperty]
    private string _commandInput = string.Empty;

    [ObservableProperty]
    private bool _isPowerLoading;

    // Renewal
    [ObservableProperty]
    private ServerRenewalStatus? _renewalStatus;

    [ObservableProperty]
    private bool _isRenewing;

    [ObservableProperty]
    private string? _renewalSuccessMessage;

    // Files
    [ObservableProperty]
    private string _currentDirectory = "/";

    [ObservableProperty]
    private ObservableCollection<ServerFileItem> _files = new();

    [ObservableProperty]
    private ServerFileItem? _selectedFile;

    [ObservableProperty]
    private string _fileEditorContent = string.Empty;

    [ObservableProperty]
    private bool _isFileLoading;

    [ObservableProperty]
    private bool _isFileSaving;

    [ObservableProperty]
    private string? _fileSuccessMessage;

    [ObservableProperty]
    private string? _fileErrorMessage;

    // Subdomains & Subusers
    [ObservableProperty]
    private ObservableCollection<ServerSubdomain> _subdomains = new();

    [ObservableProperty]
    private List<string> _availableDomains = new() { "overnode.fr", "overnode.cloud", "play.overnode.fr" };

    [ObservableProperty]
    private ObservableCollection<ServerSubuser> _subusers = new();

    // Settings
    [ObservableProperty]
    private ObservableCollection<ServerStartupVariable> _startupVariables = new();

    [ObservableProperty]
    private string _serverRenameText = string.Empty;

    [ObservableProperty]
    private bool _isDeleting;

    private readonly ServerWebSocketManager _wsManager = ServerWebSocketManager.Shared;

    public ServerDetailViewModel(ServerInstance server, ServerTab initialTab = ServerTab.Console)
    {
        _server = server;
        _selectedTab = initialTab;
        _serverRenameText = server.Name;

        AppendConsoleLine($"[System] Session connected to {server.Name} ({server.Identifier})");
        AppendConsoleLine($"[System] Current state: {server.State.ToUpperInvariant()}");

        SetupWebSocket();

        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1")
        {
            LoadDemoData();
        }
    }

    private void SetupWebSocket()
    {
        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1") return;

        _wsManager.ConsoleOutputReceived += OnWebSocketConsoleOutput;
        _wsManager.StatusChanged += OnWebSocketStatusChanged;
        _wsManager.StatsUpdated += OnWebSocketStatsUpdated;
        _wsManager.Connect(Server.Identifier);
    }

    private void OnWebSocketConsoleOutput(string line)
    {
        AppendRawConsoleLine(line);
    }

    private void OnWebSocketStatusChanged(string status)
    {
        Server.State = status;
        OnPropertyChanged(nameof(Server));
    }

    private void OnWebSocketStatsUpdated(LivePteroStats stats)
    {
        if (stats.CpuAbsolute.HasValue)
        {
            Server.CpuUsedPercent = Math.Round(stats.CpuAbsolute.Value, 1);
        }
        if (stats.MemoryBytes.HasValue)
        {
            Server.MemoryUsedMB = Math.Round(stats.MemoryBytes.Value / 1024.0 / 1024.0);
        }
        if (stats.DiskBytes.HasValue)
        {
            Server.DiskUsedMB = Math.Round(stats.DiskBytes.Value / 1024.0 / 1024.0);
        }
        if (!string.IsNullOrEmpty(stats.State))
        {
            Server.State = stats.State;
        }
        OnPropertyChanged(nameof(Server));
    }

    public void Cleanup()
    {
        _wsManager.ConsoleOutputReceived -= OnWebSocketConsoleOutput;
        _wsManager.StatusChanged -= OnWebSocketStatusChanged;
        _wsManager.StatsUpdated -= OnWebSocketStatsUpdated;
        _wsManager.Disconnect();
    }

    private void LoadDemoData()
    {
        AppendConsoleLine("[Server] Loading properties from server.properties");
        AppendConsoleLine("[Server] Starting Minecraft server on port 25565");
        AppendConsoleLine("[Server] Done (3.421s)! For help, type \"help\"");

        RenewalStatus = new ServerRenewalStatus
        {
            IsActive = true,
            NextRenewalAt = "2026-10-15T12:00:00Z",
            LastRenewedAt = "2026-09-15T12:00:00Z",
            CanRenew = true,
            RequiresRenewal = false,
            IsExpired = false,
            TimeRemaining = "23j 4h",
            RenewalCount = 3
        };

        Files = new ObservableCollection<ServerFileItem>
        {
            new() { Name = "plugins", Size = 0, IsFile = false },
            new() { Name = "world", Size = 0, IsFile = false },
            new() { Name = "world_nether", Size = 0, IsFile = false },
            new() { Name = "server.properties", Size = 1024, IsFile = true },
            new() { Name = "spigot.yml", Size = 3450, IsFile = true },
            new() { Name = "bukkit.yml", Size = 2100, IsFile = true },
            new() { Name = "paper.jar", Size = 45 * 1024 * 1024, IsFile = true }
        };

        Subdomains = new ObservableCollection<ServerSubdomain>
        {
            new() { Id = "1", ServerId = Server.Identifier, Subdomain = "play", DomainName = "overnode.fr" }
        };

        Subusers = new ObservableCollection<ServerSubuser>
        {
            new() { Id = "1", Email = "admin@overnode.fr", TwoFactorEnabled = true, Permissions = new() { "*" } }
        };

        StartupVariables = new ObservableCollection<ServerStartupVariable>
        {
            new() { Name = "Server JAR File", EnvVariable = "SERVER_JARFILE", DefaultValue = "server.jar", ServerValue = "paper.jar", IsEditable = true },
            new() { Name = "Java Version", EnvVariable = "JAVA_VERSION", DefaultValue = "21", ServerValue = "21", IsEditable = true }
        };
    }

    public void AppendConsoleLine(string line)
    {
        string timestamp = DateTime.Now.ToString("HH:mm:ss");
        ConsoleLines.Add($"[{timestamp}] {line}");
        if (ConsoleLines.Count > 500)
        {
            ConsoleLines.RemoveAt(0);
        }
    }

    public void AppendRawConsoleLine(string line)
    {
        if (string.IsNullOrWhiteSpace(line)) return;
        ConsoleLines.Add(line.TrimEnd());
        if (ConsoleLines.Count > 1000)
        {
            ConsoleLines.RemoveAt(0);
        }
    }

    public async Task LoadCurrentTabDataAsync()
    {
        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1") return;

        await RefreshLiveStatsAsync();

        switch (SelectedTab)
        {
            case ServerTab.Renewal:
                await LoadRenewalAsync();
                break;
            case ServerTab.Files:
                await LoadFilesAsync();
                break;
            case ServerTab.Subdomains:
                await LoadSubdomainsAsync();
                break;
            case ServerTab.Subusers:
                await LoadSubusersAsync();
                break;
            case ServerTab.Package:
                InitPackageResources();
                break;
            case ServerTab.Plugins:
                await LoadPluginsAsync();
                break;
            case ServerTab.Logs:
                await LoadLogsAsync();
                break;
            case ServerTab.Settings:
                await LoadSettingsAsync();
                break;
        }
    }

    public async Task RefreshLiveStatsAsync()
    {
        var result = await _serverService.FetchLiveResourcesAsync(Server.Identifier, Server.Id);
        if (result != null)
        {
            var (state, mem, cpu, disk) = result.Value;
            if (string.Equals(Server.State, "starting", StringComparison.OrdinalIgnoreCase) &&
                string.Equals(state, "offline", StringComparison.OrdinalIgnoreCase))
            {
                // Wings hasn't reported starting yet, keep starting
            }
            else if (!string.IsNullOrEmpty(state))
            {
                Server.State = state;
            }
            Server.MemoryUsedMB = mem;
            Server.CpuUsedPercent = cpu;
            Server.DiskUsedMB = disk;
            OnPropertyChanged(nameof(Server));
        }
    }

    [RelayCommand]
    public async Task SendPowerSignalAsync(ServerPowerSignal signal)
    {
        IsPowerLoading = true;
        ErrorMessage = null;
        AppendConsoleLine($"[Action] Power signal: {signal.ToSignalString().ToUpperInvariant()} sent...");

        var previousState = Server.State;
        Server.State = signal switch
        {
            ServerPowerSignal.Start or ServerPowerSignal.Restart => "starting",
            ServerPowerSignal.Stop or ServerPowerSignal.Kill => "stopping",
            _ => Server.State
        };
        OnPropertyChanged(nameof(Server));

        // 1. Send via WebSocket if authenticated
        if (_wsManager.IsAuthenticated)
        {
            _wsManager.SendPowerSignal(signal);
        }

        // 2. Send via REST API fallback
        bool success = false;
        try
        {
            await _serverService.SendPowerSignalAsync(Server.Identifier, signal.ToSignalString(), Server.Id > 0 ? Server.Id.ToString() : null);
            success = true;
            AppendConsoleLine($"[Action] Power signal {signal.ToSignalString().ToUpperInvariant()} acknowledged.");
        }
        catch (Exception ex)
        {
            if (!_wsManager.IsAuthenticated)
            {
                Server.State = previousState;
                OnPropertyChanged(nameof(Server));
            }
            ErrorMessage = ex.Message;
            AppendConsoleLine($"[Error] Failed to send signal: {ex.Message}");
        }
        finally
        {
            IsPowerLoading = false;
        }

        if (success || _wsManager.IsAuthenticated)
        {
            _ = Task.Run(async () =>
            {
                await Task.Delay(2000);
                await RefreshLiveStatsAsync();
            });
        }
    }

    [RelayCommand]
    public async Task SendConsoleCommandAsync()
    {
        string cmd = CommandInput.Trim();
        if (string.IsNullOrEmpty(cmd)) return;

        CommandInput = string.Empty;
        AppendConsoleLine($"> {cmd}");

        // 1. Send via WebSocket immediately if authenticated
        if (_wsManager.IsAuthenticated)
        {
            _wsManager.SendCommand(cmd);
            return;
        }

        // 2. Send via REST API fallback
        try
        {
            await _serverService.SendCommandAsync(Server.Identifier, cmd, Server.Id > 0 ? Server.Id.ToString() : null);
        }
        catch (Exception ex)
        {
            AppendConsoleLine($"[Error] Command failed: {ex.Message}");
        }
    }

    [RelayCommand]
    public async Task LoadRenewalAsync(bool force = false)
    {
        if (IsLoading && !force) return;
        IsLoading = true;
        var status = await _serverService.FetchRenewalStatusAsync(Server.Identifier);
        if (status != null)
        {
            RenewalStatus = status;
        }
        IsLoading = false;
    }

    [RelayCommand]
    public async Task RenewServerAsync()
    {
        IsRenewing = true;
        ErrorMessage = null;
        RenewalSuccessMessage = null;

        try
        {
            var res = await _serverService.RenewServerAsync(Server.Identifier);
            if (!string.IsNullOrEmpty(res.Error))
            {
                string msg = res.Error;
                if (!string.IsNullOrEmpty(res.AvailableIn))
                {
                    msg += $" ({LocalizationManager.Instance.GetString("renewal_available_in")} {res.AvailableIn})";
                }
                ErrorMessage = msg;
                if (res.RenewalData != null)
                {
                    RenewalStatus = res.RenewalData;
                }
            }
            else
            {
                string msg = res.Message ?? "Server renewed successfully";
                RenewalSuccessMessage = msg;
                SuccessMessage = msg;
                if (res.RenewalData != null)
                {
                    RenewalStatus = res.RenewalData;
                }
                else
                {
                    await LoadRenewalAsync(true);
                }
            }
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
        finally
        {
            IsRenewing = false;
        }
    }

    public async Task LoadFilesAsync(string? directory = null, bool force = false)
    {
        if (directory != null) CurrentDirectory = directory;
        if (IsFileLoading && !force) return;
        IsFileLoading = true;
        ErrorMessage = null;

        try
        {
            var loaded = await _filesService.ListFilesAsync(Server.Identifier, CurrentDirectory);
            Files = new ObservableCollection<ServerFileItem>(loaded);
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
        finally
        {
            IsFileLoading = false;
        }
    }

    public async Task OpenFileAsync(ServerFileItem item)
    {
        if (!item.IsFile)
        {
            string nextDir = CurrentDirectory == "/" ? $"/{item.Name}" : $"{CurrentDirectory}/{item.Name}";
            await LoadFilesAsync(nextDir);
            return;
        }

        SelectedFile = item;
        IsFileLoading = true;
        string fullPath = CurrentDirectory == "/" ? $"/{item.Name}" : $"{CurrentDirectory}/{item.Name}";

        try
        {
            FileEditorContent = await _filesService.ReadFileAsync(Server.Identifier, fullPath);
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
            SelectedFile = null;
        }
        finally
        {
            IsFileLoading = false;
        }
    }

    public async Task SaveCurrentFileAsync()
    {
        if (SelectedFile == null) return;
        IsFileSaving = true;
        FileErrorMessage = null;
        string fullPath = CurrentDirectory == "/" ? $"/{SelectedFile.Name}" : $"{CurrentDirectory}/{SelectedFile.Name}";

        try
        {
            await _filesService.WriteFileAsync(Server.Identifier, fullPath, FileEditorContent);
            FileSuccessMessage = LocalizationManager.Instance.GetString("files_save_success");
            _ = Task.Delay(4000).ContinueWith(_ =>
            {
                FileSuccessMessage = null;
            }, TaskScheduler.FromCurrentSynchronizationContext());
        }
        catch (Exception ex)
        {
            FileErrorMessage = ex.Message;
        }
        finally
        {
            IsFileSaving = false;
        }
    }

    public async Task CreateFolderAsync(string name)
    {
        try
        {
            await _filesService.CreateFolderAsync(Server.Identifier, CurrentDirectory, name);
            await LoadFilesAsync(CurrentDirectory, true);
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
    }

    public async Task DeleteFileAsync(ServerFileItem item)
    {
        try
        {
            await _filesService.DeleteFilesAsync(Server.Identifier, CurrentDirectory, new[] { item.Name });
            await LoadFilesAsync(CurrentDirectory, true);
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
    }

    public async Task LoadSubdomainsAsync(bool force = false)
    {
        if (IsLoading && !force) return;
        IsLoading = true;

        try
        {
            var subs = await _configService.FetchSubdomainsAsync(Server.Identifier);
            Subdomains = new ObservableCollection<ServerSubdomain>(subs);
            AvailableDomains = await _configService.FetchAvailableDomainsAsync();
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
        finally
        {
            IsLoading = false;
        }
    }

    public async Task CreateSubdomainAsync(string subdomain, string domainName)
    {
        IsLoading = true;
        try
        {
            await _configService.CreateSubdomainAsync(Server.Identifier, subdomain, domainName);
            await LoadSubdomainsAsync(true);
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
        finally
        {
            IsLoading = false;
        }
    }

    public async Task DeleteSubdomainAsync(string id)
    {
        try
        {
            await _configService.DeleteSubdomainAsync(Server.Identifier, id);
            await LoadSubdomainsAsync(true);
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
    }

    public async Task LoadSubusersAsync(bool force = false)
    {
        if (IsLoading && !force) return;
        IsLoading = true;

        try
        {
            var users = await _configService.FetchSubusersAsync(Server.Identifier);
            Subusers = new ObservableCollection<ServerSubuser>(users);
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
        finally
        {
            IsLoading = false;
        }
    }

    public async Task AddSubuserAsync(string email, List<string> permissions)
    {
        try
        {
            await _configService.CreateSubuserAsync(Server.Identifier, email, permissions);
            await LoadSubusersAsync(true);
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
    }

    public async Task DeleteSubuserAsync(string userId)
    {
        try
        {
            await _configService.DeleteSubuserAsync(Server.Identifier, userId);
            await LoadSubusersAsync(true);
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
    }

    public async Task LoadSettingsAsync(bool force = false)
    {
        if (IsLoading && !force) return;
        IsLoading = true;

        try
        {
            var vars = await _configService.FetchVariablesAsync(Server.Identifier);
            StartupVariables = new ObservableCollection<ServerStartupVariable>(vars);
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
        finally
        {
            IsLoading = false;
        }
    }

    public async Task RenameServerAsync(string newName)
    {
        try
        {
            await _configService.RenameServerAsync(Server.Identifier, newName);
            Server.Name = newName;
            SuccessMessage = LocalizationManager.Instance.GetString("settings_rename_success") ?? "Server renamed successfully";
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
    }

    public async Task ReinstallServerAsync()
    {
        try
        {
            await _configService.ReinstallServerAsync(Server.Identifier);
            SuccessMessage = "Server reinstall initiated";
            AppendConsoleLine("[System] Server reinstallation initiated.");
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
    }

    public async Task<bool> DeleteServerAsync()
    {
        IsDeleting = true;
        ErrorMessage = null;
        try
        {
            await _serverService.DeleteServerAsync(Server.Identifier);
            IsDeleting = false;
            return true;
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
            IsDeleting = false;
            return false;
        }
    }

    public async Task UpdateStartupVariableAsync(string key, string value)
    {
        try
        {
            await _configService.UpdateVariableAsync(Server.Identifier, key, value);
            SuccessMessage = "Variable updated";
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
    }

    // MARK: - Package & Quotas
    [ObservableProperty]
    private double _packageRamMB = 1024;

    [ObservableProperty]
    private double _packageCpuPercent = 100;

    [ObservableProperty]
    private double _packageDiskMB = 2048;

    [ObservableProperty]
    private double _maxAvailableRamMB = 4096;

    [ObservableProperty]
    private double _maxAvailableCpuPercent = 200;

    [ObservableProperty]
    private double _maxAvailableDiskMB = 10240;

    [ObservableProperty]
    private bool _isSavingPackage;

    public void InitPackageResources()
    {
        PackageRamMB = Server.MemoryLimitMB > 0 ? Server.MemoryLimitMB : 1024;
        PackageCpuPercent = Server.CpuLimitPercent > 0 ? Server.CpuLimitPercent : 100;
        PackageDiskMB = Server.DiskLimitMB > 0 ? Server.DiskLimitMB : 2048;
        MaxAvailableRamMB = Math.Max(PackageRamMB, 4096);
        MaxAvailableCpuPercent = Math.Max(PackageCpuPercent, 200);
        MaxAvailableDiskMB = Math.Max(PackageDiskMB, 10240);
    }

    [RelayCommand]
    public void SetMaxPackageResources()
    {
        PackageRamMB = MaxAvailableRamMB;
        PackageCpuPercent = MaxAvailableCpuPercent;
        PackageDiskMB = MaxAvailableDiskMB;
    }

    [RelayCommand]
    public async Task SavePackageChangesAsync()
    {
        IsSavingPackage = true;
        ErrorMessage = null;
        SuccessMessage = null;

        try
        {
            await _configService.ModifyServerResourcesAsync(
                Server.Identifier,
                (int)PackageRamMB,
                (int)PackageDiskMB,
                (int)PackageCpuPercent);

            Server.MemoryLimitMB = PackageRamMB;
            Server.DiskLimitMB = PackageDiskMB;
            Server.CpuLimitPercent = PackageCpuPercent;
            SuccessMessage = LocalizationManager.Instance.GetString("package_save_changes");
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
        finally
        {
            IsSavingPackage = false;
        }
    }

    // MARK: - Plugins
    [ObservableProperty]
    private ObservableCollection<ServerPluginItem> _installedPlugins = new();

    [ObservableProperty]
    private ObservableCollection<ServerPluginItem> _pluginSearchResults = new();

    [ObservableProperty]
    private string _pluginSearchQuery = string.Empty;

    [ObservableProperty]
    private bool _isSearchingPlugins;

    [ObservableProperty]
    private int _pluginSubTab; // 0 = Installed, 1 = Search

    [RelayCommand]
    public async Task LoadPluginsAsync(bool force = false)
    {
        if (IsLoading && !force) return;
        IsLoading = true;
        ErrorMessage = null;
        try
        {
            var loaded = await _configService.FetchInstalledPluginsAsync(Server.Identifier);
            if (loaded.Count == 0 && Server.Id > 0 && Server.Id.ToString() != Server.Identifier)
            {
                var fallback = await _configService.FetchInstalledPluginsAsync(Server.Id.ToString());
                if (fallback.Count > 0)
                {
                    loaded = fallback;
                }
            }
            InstalledPlugins = new ObservableCollection<ServerPluginItem>(loaded);
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
        finally
        {
            IsLoading = false;
        }
    }

    [RelayCommand]
    public async Task SearchPluginsAsync()
    {
        if (string.IsNullOrWhiteSpace(PluginSearchQuery)) return;
        IsSearchingPlugins = true;
        ErrorMessage = null;
        try
        {
            var results = await _configService.SearchPluginsAsync(PluginSearchQuery.Trim());
            PluginSearchResults = new ObservableCollection<ServerPluginItem>(results);
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
        finally
        {
            IsSearchingPlugins = false;
        }
    }

    [RelayCommand]
    public async Task InstallPluginAsync(ServerPluginItem plugin)
    {
        if (plugin == null) return;
        ErrorMessage = null;
        SuccessMessage = null;
        try
        {
            await _configService.InstallPluginAsync(Server.Identifier, plugin.Id, plugin.Platform ?? "spigot");
            plugin.IsInstalled = true;
            SuccessMessage = $"{plugin.Name} installé avec succès.";
            await LoadPluginsAsync(true);
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
    }

    [RelayCommand]
    public async Task UninstallPluginAsync(ServerPluginItem plugin)
    {
        if (plugin == null) return;
        ErrorMessage = null;
        SuccessMessage = null;
        try
        {
            await _configService.UntrackPluginAsync(Server.Identifier, plugin.Id, plugin.Platform ?? "modrinth");
            InstalledPlugins.Remove(plugin);
            SuccessMessage = $"{plugin.Name} désinstallé.";
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
    }

    // MARK: - Activity Logs
    [ObservableProperty]
    private ObservableCollection<ServerActivityLog> _activityLogs = new();

    [RelayCommand]
    public async Task LoadLogsAsync(bool force = false)
    {
        if (IsLoading && !force) return;
        IsLoading = true;
        ErrorMessage = null;
        try
        {
            var logs = await _configService.FetchLogsAsync(Server.Identifier);
            if (logs.Count == 0 && Server.Id > 0 && Server.Id.ToString() != Server.Identifier)
            {
                var fallback = await _configService.FetchLogsAsync(Server.Id.ToString());
                if (fallback.Count > 0)
                {
                    logs = fallback;
                }
            }
            ActivityLogs = new ObservableCollection<ServerActivityLog>(logs);
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
        finally
        {
            IsLoading = false;
        }
    }
}
