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

    public ServerDetailViewModel(ServerInstance server, ServerTab initialTab = ServerTab.Console)
    {
        _server = server;
        _selectedTab = initialTab;
        _serverRenameText = server.Name;

        AppendConsoleLine($"[System] Session connected to {server.Name} ({server.Identifier})");
        AppendConsoleLine($"[System] Current state: {server.State.ToUpperInvariant()}");

        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1")
        {
            LoadDemoData();
        }
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
            case ServerTab.Settings:
                await LoadSettingsAsync();
                break;
        }
    }

    public async Task RefreshLiveStatsAsync()
    {
        var (state, mem, cpu, disk) = await _serverService.FetchLiveResourcesAsync(Server.Identifier);
        Server.State = state;
        Server.MemoryUsedMB = mem;
        Server.CpuUsedPercent = cpu;
        Server.DiskUsedMB = disk;
    }

    [RelayCommand]
    public async Task SendPowerSignalAsync(ServerPowerSignal signal)
    {
        IsPowerLoading = true;
        ErrorMessage = null;
        AppendConsoleLine($"[Action] Power signal: {signal.ToSignalString().ToUpperInvariant()} sent...");

        try
        {
            await _serverService.SendPowerSignalAsync(Server.Identifier, signal.ToSignalString());
            Server.State = signal switch
            {
                ServerPowerSignal.Start or ServerPowerSignal.Restart => "starting",
                ServerPowerSignal.Stop or ServerPowerSignal.Kill => "stopping",
                _ => Server.State
            };
            AppendConsoleLine($"[Action] Power signal {signal.ToSignalString().ToUpperInvariant()} acknowledged.");
            await Task.Delay(1000);
            await RefreshLiveStatsAsync();
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
            AppendConsoleLine($"[Error] Failed to send signal: {ex.Message}");
        }
        finally
        {
            IsPowerLoading = false;
        }
    }

    [RelayCommand]
    public async Task SendConsoleCommandAsync()
    {
        string cmd = CommandInput.Trim();
        if (string.IsNullOrEmpty(cmd)) return;

        CommandInput = string.Empty;
        AppendConsoleLine($"> {cmd}");

        try
        {
            await _serverService.SendCommandAsync(Server.Identifier, cmd);
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
}
