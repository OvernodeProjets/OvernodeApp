using System;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.Services;

namespace Overnode.App.ViewModels;

public partial class DashboardViewModel : ObservableObject
{
    private readonly AuthService _authService = AuthService.Instance;
    private readonly ServerService _serverService = ServerService.Shared;
    private readonly LocalizationManager _loc = LocalizationManager.Instance;

    private System.Timers.Timer? _autoRefreshTimer;
    private DateTime? _lastServersSectionRefresh;
    private const double ServersRefreshCooldownSeconds = 5.0;

    [ObservableProperty]
    private ResourcesResponse? _resources;

    [ObservableProperty]
    private PlatformStatsResponse? _platformStats;

    [ObservableProperty]
    private ObservableCollection<ServerInstance> _servers = new();

    [ObservableProperty]
    private bool _isLoading;

    [ObservableProperty]
    private string? _errorMessage;

    [ObservableProperty]
    private DateTime? _lastUpdated;

    [ObservableProperty]
    private NavigationTab _selectedTab = NavigationTab.Dashboard;

    [ObservableProperty]
    private ServerInstance? _selectedServer;

    [ObservableProperty]
    private int _userCoins;

    public LocalizationManager Loc => _loc;

    public DashboardViewModel(ResourcesResponse? initialResources = null)
    {
        if (initialResources != null)
        {
            Resources = initialResources;
            LastUpdated = DateTime.UtcNow;
        }

        if (Environment.GetEnvironmentVariable("OVERNODE_TEST_SERVERS_TAB") == "1")
        {
            SelectedTab = NavigationTab.Servers;
        }

        StartAutoRefresh();
        _ = LoadDashboardDataAsync(force: true);
    }

    public void StartAutoRefresh()
    {
        StopAutoRefresh();
        _autoRefreshTimer = new System.Timers.Timer(20000); // 20s
        _autoRefreshTimer.Elapsed += (s, e) =>
        {
            _ = LoadDashboardDataAsync(isBackground: true);
        };
        _autoRefreshTimer.AutoReset = true;
        _autoRefreshTimer.Start();
    }

    public void StopAutoRefresh()
    {
        if (_autoRefreshTimer != null)
        {
            _autoRefreshTimer.Stop();
            _autoRefreshTimer.Dispose();
            _autoRefreshTimer = null;
        }
    }

    public void SetInitialResourcesIfNeeded(ResourcesResponse? res)
    {
        if (Resources == null && res != null)
        {
            Resources = res;
            LastUpdated = DateTime.UtcNow;
        }
    }

    public void RefreshServersOnNavigatingToServersSection(bool force = false)
    {
        if (!force && _lastServersSectionRefresh != null &&
            (DateTime.UtcNow - _lastServersSectionRefresh.Value).TotalSeconds < ServersRefreshCooldownSeconds)
        {
            return;
        }

        _lastServersSectionRefresh = DateTime.UtcNow;
        _ = LoadDashboardDataAsync(force: true, isBackground: Servers.Count > 0);
    }

    [RelayCommand]
    public async Task RefreshAsync()
    {
        await LoadDashboardDataAsync(force: true);
    }

    public async Task LoadDashboardDataAsync(bool force = false, bool isBackground = false)
    {
        if (IsLoading && !force) return;
        if (!force && LastUpdated != null && (DateTime.UtcNow - LastUpdated.Value).TotalSeconds < 2.0)
        {
            return;
        }

        if (!isBackground)
        {
            IsLoading = true;
        }
        ErrorMessage = null;

        // Check for Demo Mode
        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1")
        {
            var demoServers = new ObservableCollection<ServerInstance>
            {
                new()
                {
                    Id = 1,
                    Identifier = "7f4c9a12",
                    Name = "Minecraft Survival",
                    Node = "Node FR-01",
                    Suspended = false,
                    State = "running",
                    MemoryUsedMB = 2840,
                    MemoryLimitMB = 4096,
                    CpuUsedPercent = 32.5,
                    CpuLimitPercent = 200,
                    DiskUsedMB = 8120,
                    DiskLimitMB = 15360,
                    IsOwner = true
                },
                new()
                {
                    Id = 2,
                    Identifier = "a3b8d104",
                    Name = "BungeeCord Proxy",
                    Node = "Node FR-01",
                    Suspended = false,
                    State = "running",
                    MemoryUsedMB = 420,
                    MemoryLimitMB = 1024,
                    CpuUsedPercent = 8.2,
                    CpuLimitPercent = 100,
                    DiskUsedMB = 1200,
                    DiskLimitMB = 5120,
                    IsOwner = false
                }
            };

            Servers = demoServers;
            PlatformStats = new PlatformStatsResponse(1268, 91, 4, 2);
            Resources = new ResourcesResponse
            {
                Package = "Titanium",
                Allowed = new ResourceBucket(8192, 40960, 400, 4),
                Remaining = new ResourceBucket(4932, 24000, 259, 2),
                Current = new ResourceBucket(3260, 9320, 141, 2),
                Limits = new ResourceBucket(8192, 40960, 400, 4)
            };
            LastUpdated = DateTime.UtcNow;
            UserCoins = 350;
            IsLoading = false;

            if (Environment.GetEnvironmentVariable("OVERNODE_TEST_SERVER_DETAIL") == "1")
            {
                SelectedServer = Servers.FirstOrDefault();
            }
            return;
        }

        try
        {
            var srvsTask = _authService.FetchServersStatusAsync();
            var statsTask = _authService.FetchPlatformStatsAsync();
            var resTask = _authService.FetchResourcesAsync();
            var coinsTask = _authService.FetchCoinsAsync();

            await Task.WhenAll(srvsTask, statsTask, resTask, coinsTask);

            var srvs = await srvsTask;
            if (srvs != null)
            {
                Servers.Clear();
                foreach (var s in srvs)
                {
                    Servers.Add(s);
                }
                OnPropertyChanged(nameof(Servers));
            }

            PlatformStats = await statsTask;

            try
            {
                var res = await resTask;
                if (res != null) Resources = res;
            }
            catch
            {
                if (Resources == null) Resources = ResourcesResponse.Empty;
            }

            try
            {
                UserCoins = await coinsTask;
            }
            catch { }

            LastUpdated = DateTime.UtcNow;
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

    public void OnServerDeleted(ServerInstance server)
    {
        var match = Servers.FirstOrDefault(s => s.Identifier == server.Identifier || s.Id == server.Id);
        if (match != null)
        {
            Servers.Remove(match);
        }

        if (Resources != null)
        {
            var cur = Resources;
            var updatedCurrent = new ResourceBucket(
                Math.Max(0, cur.Current.Ram - server.MemoryLimitMB),
                Math.Max(0, cur.Current.Disk - server.DiskLimitMB),
                Math.Max(0, cur.Current.Cpu - server.CpuLimitPercent),
                Math.Max(0, cur.Current.Servers - 1)
            );
            var updatedRemaining = new ResourceBucket(
                cur.Remaining.Ram + server.MemoryLimitMB,
                cur.Remaining.Disk + server.DiskLimitMB,
                cur.Remaining.Cpu + server.CpuLimitPercent,
                cur.Remaining.Servers + 1
            );

            Resources = new ResourcesResponse
            {
                Package = cur.Package,
                Allowed = cur.Allowed,
                Remaining = updatedRemaining,
                Current = updatedCurrent,
                Limits = cur.Limits
            };
        }

        _ = Task.Run(async () =>
        {
            await Task.Delay(1000);
            await LoadDashboardDataAsync(force: true, isBackground: true);
        });
    }

    [RelayCommand]
    public async Task DeleteServerAsync(ServerInstance server)
    {
        await _serverService.DeleteServerAsync(server.Identifier);
        OnServerDeleted(server);
    }
}
