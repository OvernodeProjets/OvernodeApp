using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.Services;
using Overnode.App.ViewModels;

namespace Overnode.App.Views;

public sealed partial class DashboardView : UserControl
{
    public static readonly DependencyProperty AuthVMProperty =
        DependencyProperty.Register(nameof(AuthVM), typeof(AuthViewModel), typeof(DashboardView),
            new PropertyMetadata(null, (d, e) => ((DashboardView)d).OnAuthVMChanged()));

    public AuthViewModel? AuthVM
    {
        get => (AuthViewModel?)GetValue(AuthVMProperty);
        set => SetValue(AuthVMProperty, value);
    }

    public DashboardViewModel ViewModel { get; }

    public DashboardView()
    {
        ViewModel = new DashboardViewModel();
        this.InitializeComponent();

        ViewModel.PropertyChanged += OnViewModelPropertyChanged;
        ViewModel.Servers.CollectionChanged += (s, e) => UpdateServersView();
        LocalizationManager.Instance.LanguageChanged += (s, e) => UpdateLocalization();
        ServerDetailView.ServerDeleted += (s, e) =>
        {
            OnSidebarBackToServersRequested(this, EventArgs.Empty);
            ViewModel.RefreshServersOnNavigatingToServersSection();
        };

        CreateServerModal.Dismissed += OnModalDismissed;
        CreateServerModal.ServerCreated += OnServerCreated;
        SettingsViewContent.LogoutRequested += OnLogoutRequested;
        SettingsViewContent.NavigateToStoreRequested += (s, e) =>
        {
            ViewModel.SelectedTab = NavigationTab.Store;
            Sidebar.SelectedTab = NavigationTab.Store;
            UpdateTabContent();
        };
        SettingsViewContent.OpenDiscordVIPModalRequested += (s, e) => OpenDiscordVIPModal();
        StoreViewContent.ResourcePurchased += OnResourcePurchased;
        DailyRewardViewContent.RewardClaimed += (s, e) => _ = RefreshCoinsAsync();

        DiscordVIPModal.Dismissed += (s, e) =>
        {
            DiscordVIPModalOverlay.Visibility = Visibility.Collapsed;
        };
        DiscordVIPModal.VIPActivated += (s, e) =>
        {
            SettingsViewContent.Refresh();
            ThemeManager.Shared.ApplyCurrentColorsToApplicationResources();
        };
        DiscordVIPModal.VIPUnlinked += (s, e) =>
        {
            SettingsViewContent.Refresh();
        };

        ThemeManager.Shared.PropertyChanged += (s, e) =>
        {
            DispatcherQueue.TryEnqueue(UpdateThemeCustomizations);
        };

        var testTabEnv = Environment.GetEnvironmentVariable("OVERNODE_TEST_TAB");
        if (!string.IsNullOrEmpty(testTabEnv) && Enum.TryParse<NavigationTab>(testTabEnv, true, out var initialNavTab))
        {
            ViewModel.SelectedTab = initialNavTab;
            Sidebar.SelectedTab = initialNavTab;
        }
        else
        {
            var landingTab = ThemeManager.Shared.ResolvedLandingTab;
            ViewModel.SelectedTab = landingTab;
            Sidebar.SelectedTab = landingTab;
        }

        EasterEggOverlay.Dismissed += (s, e) =>
        {
            EasterEggOverlay.Visibility = Visibility.Collapsed;
        };
        PreviewKeyDown += OnDashboardPreviewKeyDown;

        if (Environment.GetEnvironmentVariable("OVERNODE_TEST_CREATE_MODAL") == "1")
        {
            DispatcherQueue.TryEnqueue(async () =>
            {
                await OpenCreateServerModalAsync();
            });
        }

        if (Environment.GetEnvironmentVariable("OVERNODE_TEST_EASTER_EGG") == "1")
        {
            DispatcherQueue.TryEnqueue(() =>
            {
                ViewModel.SelectedTab = NavigationTab.Settings;
                UpdateTabContent();
                OpenEasterEgg();
            });
        }

        UpdateLocalization();
        UpdateUI();
        UpdateThemeCustomizations();
    }

    private void OnAuthVMChanged()
    {
        if (AuthVM != null)
        {
            Sidebar.CurrentUser = AuthVM.CurrentUser;
            SettingsViewContent.CurrentUser = AuthVM.CurrentUser;
            DiscordVIPModal.CurrentUser = AuthVM.CurrentUser;
            _ = GodPackService.Shared.CheckAccessAsync(AuthVM.CurrentUser);
            UpdateThemeCustomizations();

            if (AuthVM.CurrentUser != null)
            {
                StoreViewContent.ViewModel.UserCoins = AuthVM.CurrentUser.Coins;
                Sidebar.UpdateCoins(AuthVM.CurrentUser.Coins);
            }

            ViewModel.SetInitialResourcesIfNeeded(AuthVM.InitialResources);
            AuthVM.PropertyChanged += (s, e) =>
            {
                if (e.PropertyName == nameof(AuthViewModel.CurrentUser))
                {
                    Sidebar.CurrentUser = AuthVM.CurrentUser;
                    SettingsViewContent.CurrentUser = AuthVM.CurrentUser;
                    DiscordVIPModal.CurrentUser = AuthVM.CurrentUser;
                    _ = GodPackService.Shared.CheckAccessAsync(AuthVM.CurrentUser);
                    if (AuthVM.CurrentUser != null)
                    {
                        StoreViewContent.ViewModel.UserCoins = AuthVM.CurrentUser.Coins;
                        Sidebar.UpdateCoins(AuthVM.CurrentUser.Coins);
                    }
                }
            };

            _ = RefreshCoinsAsync();
        }
    }

    private void OnViewModelPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        DispatcherQueue.TryEnqueue(() =>
        {
            if (e.PropertyName == nameof(DashboardViewModel.Resources))
            {
                UpdateGauges();
            }
            else if (e.PropertyName == nameof(DashboardViewModel.PlatformStats))
            {
                UpdatePlatformStats();
            }
            else if (e.PropertyName == nameof(DashboardViewModel.UserCoins))
            {
                if (AuthVM?.CurrentUser != null)
                {
                    AuthVM.CurrentUser.Coins = ViewModel.UserCoins;
                }
                Sidebar.UpdateCoins(ViewModel.UserCoins);
                StoreViewContent.ViewModel.UserCoins = ViewModel.UserCoins;
            }
            else if (e.PropertyName == nameof(DashboardViewModel.Servers))
            {
                UpdateServersView();
            }
            else if (e.PropertyName == nameof(DashboardViewModel.IsLoading))
            {
                UpdateServersView();
            }
            else if (e.PropertyName == nameof(DashboardViewModel.SelectedTab))
            {
                UpdateTabContent();
            }
            else if (e.PropertyName == nameof(DashboardViewModel.SelectedServer))
            {
                if (ViewModel.SelectedServer != null)
                {
                    OnCardManageRequested(this, ViewModel.SelectedServer);
                }
            }
        });
    }

    private void UpdateLocalization()
    {
        var loc = LocalizationManager.Instance;
        DashboardTitleText.Text = loc.GetString("dashboard_title");
        ServersSectionTitle.Text = loc.GetString("dashboard_servers_title");
        CreateServerBtnText.Text = loc.GetString("create_server_button");
        ServersLoadingText.Text = loc.GetString("servers_loading");
        ServersNoneFoundText.Text = loc.GetString("servers_none_found");
        EmptyRefreshText.Text = loc.GetString("status_refresh");

        PlatformStatsTitle.Text = loc.GetString("dashboard_platform_stats");
        StatUsersLabel.Text = loc.GetString("stats_total_users");
        StatServersLabel.Text = loc.GetString("stats_active_servers");
        StatNodesLabel.Text = loc.GetString("stats_nodes");
        StatLocationsLabel.Text = loc.GetString("stats_locations");

        ServersPageTitle.Text = loc.GetString("nav_servers");
        ServersPageSubtitle.Text = loc.GetString("servers_page_subtitle");
        ServersPageCreateBtnText.Text = loc.GetString("create_server_button");

        UpdateGauges();
        UpdateTabContent();
    }

    private void UpdateUI()
    {
        UpdateGauges();
        UpdateServersView();
        UpdatePlatformStats();
        if (ViewModel.SelectedServer != null)
        {
            OnCardManageRequested(this, ViewModel.SelectedServer);
        }
        else
        {
            UpdateTabContent();
        }
    }

    private void UpdateGauges()
    {
        var loc = LocalizationManager.Instance;
        var res = ViewModel.Resources ?? ResourcesResponse.Empty;

        // RAM Gauge
        RamGauge.Title = loc.GetString("resource_ram");
        RamGauge.UsedFormatted = $"{res.RamUsedGB:F0}";
        RamGauge.TotalFormatted = $"{res.RamTotalGB:F0}";
        RamGauge.Unit = "GB";
        RamGauge.Percentage = res.RamPercentage;

        // CPU Gauge
        CpuGauge.Title = loc.GetString("resource_cpu");
        CpuGauge.UsedFormatted = $"{res.Current.Cpu:F0}";
        CpuGauge.TotalFormatted = $"{res.Limits.Cpu:F0}";
        CpuGauge.Unit = "%";
        CpuGauge.Percentage = res.CpuPercentage;

        // Disk Gauge
        DiskGauge.Title = loc.GetString("resource_disk");
        DiskGauge.UsedFormatted = $"{res.DiskUsedGB:F0}";
        DiskGauge.TotalFormatted = $"{res.DiskTotalGB:F0}";
        DiskGauge.Unit = "GB";
        DiskGauge.Percentage = res.DiskPercentage;

        // Servers Gauge
        ServersGauge.Title = loc.GetString("resource_servers");
        ServersGauge.UsedFormatted = $"{res.Current.Servers}";
        ServersGauge.TotalFormatted = $"{res.Limits.Servers}";
        ServersGauge.Unit = "";
        ServersGauge.Percentage = res.ServersPercentage;
    }

    private void UpdateServersView()
    {
        ServersCardsItemsControl.ItemsSource = null;
        ServersCardsItemsControl.ItemsSource = ViewModel.Servers;
        ServersCardsItemsControl.Visibility = ViewModel.Servers.Count > 0 ? Visibility.Visible : Visibility.Collapsed;

        ServersPageItemsControl.ItemsSource = null;
        ServersPageItemsControl.ItemsSource = ViewModel.Servers;
        ServersPageItemsControl.Visibility = ViewModel.Servers.Count > 0 ? Visibility.Visible : Visibility.Collapsed;

        Sidebar.Servers = null;
        Sidebar.Servers = ViewModel.Servers;

        ServersCountText.Text = ViewModel.Servers.Count.ToString();
        ServersCountBadge.Visibility = ViewModel.Servers.Count > 0 ? Visibility.Visible : Visibility.Collapsed;

        bool isEmpty = ViewModel.Servers.Count == 0 && !ViewModel.IsLoading;
        ServersEmptyPanel.Visibility = isEmpty ? Visibility.Visible : Visibility.Collapsed;
        ServersLoadingPanel.Visibility = (ViewModel.IsLoading && ViewModel.Servers.Count == 0)
            ? Visibility.Visible
            : Visibility.Collapsed;

        TrayIconManager.Shared.UpdateServers(ViewModel.Servers);
        SettingsViewContent.SetServers(ViewModel.Servers);
    }

    private void UpdatePlatformStats()
    {
        var stats = ViewModel.PlatformStats;
        if (stats != null)
        {
            PlatformStatsPanel.Visibility = Visibility.Visible;
            StatUsersValue.Text = stats.TotalUsers?.ToString("N0") ?? "0";
            StatServersValue.Text = stats.TotalServers?.ToString("N0") ?? "0";
            StatNodesValue.Text = stats.TotalNodes?.ToString("N0") ?? "0";
            StatLocationsValue.Text = stats.TotalLocations?.ToString("N0") ?? "0";
        }
        else
        {
            PlatformStatsPanel.Visibility = Visibility.Collapsed;
        }
    }

    private void UpdateTabContent()
    {
        OverviewContent.Visibility = Visibility.Collapsed;
        ServersListContent.Visibility = Visibility.Collapsed;
        WalletViewContent.Visibility = Visibility.Collapsed;
        DailyRewardViewContent.Visibility = Visibility.Collapsed;
        StoreViewContent.Visibility = Visibility.Collapsed;
        SupportViewContent.Visibility = Visibility.Collapsed;
        AFKViewContent.Visibility = Visibility.Collapsed;
        SettingsViewContent.Visibility = Visibility.Collapsed;
        ServerDetailView.Visibility = Visibility.Collapsed;

        switch (ViewModel.SelectedTab)
        {
            case NavigationTab.Dashboard:
                OverviewContent.Visibility = Visibility.Visible;
                break;

            case NavigationTab.Servers:
                ServersListContent.Visibility = Visibility.Visible;
                ViewModel.RefreshServersOnNavigatingToServersSection();
                break;

            case NavigationTab.Wallet:
                WalletViewContent.Visibility = Visibility.Visible;
                _ = WalletViewContent.InitializeAsync();
                break;

            case NavigationTab.DailyReward:
                DailyRewardViewContent.Visibility = Visibility.Visible;
                _ = DailyRewardViewContent.InitializeAsync();
                break;

            case NavigationTab.Store:
                StoreViewContent.Visibility = Visibility.Visible;
                if (AuthVM?.CurrentUser != null)
                {
                    StoreViewContent.ViewModel.UserCoins = AuthVM.CurrentUser.Coins;
                }
                _ = StoreViewContent.InitializeAsync();
                break;

            case NavigationTab.Support:
                SupportViewContent.Visibility = Visibility.Visible;
                _ = SupportViewContent.InitializeAsync();
                break;

            case NavigationTab.Afk:
                AFKViewContent.Visibility = Visibility.Visible;
                break;

            case NavigationTab.Settings:
                SettingsViewContent.Visibility = Visibility.Visible;
                SettingsViewContent.CurrentUser = AuthVM?.CurrentUser;
                SettingsViewContent.SetServers(ViewModel.Servers);
                SettingsViewContent.Refresh();
                break;
        }
    }

    private void OnSidebarTabSelected(object? sender, NavigationTab tab)
    {
        CloseEasterEgg();
        ServerDetailView.Visibility = Visibility.Collapsed;
        ServerDetailView.DataContext = null;
        Sidebar.SelectedServer = null;
        ViewModel.SelectedTab = tab;
        UpdateTabContent();
        _ = RefreshCoinsAsync();
    }

    private void OnSidebarServerTabSelected(object? sender, ServerTab tab)
    {
        CloseEasterEgg();
        if (ServerDetailView.DataContext is ServerDetailViewModel vm)
        {
            vm.SelectedTab = tab;
            _ = vm.LoadCurrentTabDataAsync();
            ServerDetailView.SwitchTab(tab);
        }
    }

    private void OnSidebarBackToServersRequested(object? sender, EventArgs e)
    {
        CloseEasterEgg();
        ServerDetailView.Visibility = Visibility.Collapsed;
        ServerDetailView.DataContext = null;
        Sidebar.SelectedServer = null;
        UpdateTabContent();
    }

    private void OnQuickServerSelected(object? sender, ServerInstance server)
    {
        OnCardManageRequested(this, server);
    }

    private void OnRefreshRequested(object? sender, EventArgs e)
    {
        AuthVM?.CheckSessionCommand.Execute(null);
        _ = RefreshCoinsAsync();
        ViewModel.RefreshCommand.Execute(null);
    }

    private void OnRefreshRequested(object? sender, RoutedEventArgs e)
    {
        OnRefreshRequested(sender, EventArgs.Empty);
    }

    private async void OnCreateServerClicked(object sender, RoutedEventArgs e)
    {
        await OpenCreateServerModalAsync();
    }

    private async Task OpenCreateServerModalAsync()
    {
        CreateServerModalOverlay.Visibility = Visibility.Visible;
        await CreateServerModal.InitializeAsync();
    }

    private void OnModalDismissed()
    {
        CreateServerModalOverlay.Visibility = Visibility.Collapsed;
    }

    private void OnServerCreated(ServerInstance server)
    {
        CreateServerModalOverlay.Visibility = Visibility.Collapsed;
        var existing = ViewModel.Servers.FirstOrDefault(s => s.Identifier == server.Identifier || (s.Id != 0 && s.Id == server.Id));
        if (existing == null)
        {
            ViewModel.Servers.Insert(0, server);
        }
        UpdateServersView();
        _ = Task.Run(async () =>
        {
            await Task.Delay(1200);
            DispatcherQueue.TryEnqueue(() =>
            {
                _ = ViewModel.LoadDashboardDataAsync(force: true, isBackground: true);
            });
        });
    }

    private void OnModalOverlayTapped(object sender, Microsoft.UI.Xaml.Input.TappedRoutedEventArgs e)
    {
        if (ReferenceEquals(e.OriginalSource, CreateServerModalOverlay))
        {
            OnModalDismissed();
        }
    }

    private void OnCardManageRequested(object? sender, ServerInstance server)
    {
        var initialTab = ServerTab.Console;
        var tabEnv = Environment.GetEnvironmentVariable("OVERNODE_TEST_SERVER_TAB");
        if (!string.IsNullOrEmpty(tabEnv) && Enum.TryParse<ServerTab>(tabEnv, true, out var parsedTab))
        {
            initialTab = parsedTab;
        }

        var detailVm = new ServerDetailViewModel(server, initialTab);
        ServerDetailView.DataContext = detailVm;
        Sidebar.SelectedServer = server;
        Sidebar.SelectedServerTab = initialTab;

        OverviewContent.Visibility = Visibility.Collapsed;
        ServersListContent.Visibility = Visibility.Collapsed;
        WalletViewContent.Visibility = Visibility.Collapsed;
        DailyRewardViewContent.Visibility = Visibility.Collapsed;
        StoreViewContent.Visibility = Visibility.Collapsed;
        SupportViewContent.Visibility = Visibility.Collapsed;
        AFKViewContent.Visibility = Visibility.Collapsed;
        SettingsViewContent.Visibility = Visibility.Collapsed;
        ServerDetailView.Visibility = Visibility.Visible;
        ServerDetailView.SwitchTab(initialTab);
    }

    private void OnResourcePurchased(int remainingCoins)
    {
        if (AuthVM?.CurrentUser != null)
        {
            AuthVM.CurrentUser.Coins = remainingCoins;
        }
        Sidebar.UpdateCoins(remainingCoins);
        ViewModel.UserCoins = remainingCoins;
        StoreViewContent.ViewModel.UserCoins = remainingCoins;
        ViewModel.RefreshCommand.Execute(null);
    }

    public async Task RefreshCoinsAsync()
    {
        try
        {
            var coins = await AuthService.Instance.FetchCoinsAsync();
            DispatcherQueue.TryEnqueue(() =>
            {
                if (AuthVM?.CurrentUser != null)
                {
                    AuthVM.CurrentUser.Coins = coins;
                }
                ViewModel.UserCoins = coins;
                Sidebar.UpdateCoins(coins);
                StoreViewContent.ViewModel.UserCoins = coins;
            });
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[DashboardView] RefreshCoinsAsync error: {ex.Message}");
        }
    }

    private async void OnCardDeleteRequested(object? sender, ServerInstance server)
    {
        var loc = LocalizationManager.Instance;
        var dialog = new ContentDialog
        {
            XamlRoot = this.XamlRoot,
            Title = loc.GetString("settings_delete_confirm_title") ?? "Supprimer le serveur",
            Content = loc.GetString("settings_delete_confirm_msg") ?? "Êtes-vous sûr de vouloir supprimer ce serveur ? Cette action est irréversible.",
            PrimaryButtonText = loc.GetString("settings_delete_confirm_btn") ?? "Supprimer",
            CloseButtonText = loc.GetString("generic_cancel") ?? "Annuler",
            DefaultButton = ContentDialogButton.Close
        };

        var result = await dialog.ShowAsync();
        if (result == ContentDialogResult.Primary)
        {
            await ViewModel.DeleteServerAsync(server);
            AuthVM?.CheckSessionCommand.Execute(null);
        }
    }

    private void OnLogoutRequested(object? sender, EventArgs e)
    {
        CloseEasterEgg();
        AuthVM?.LogoutCommand.Execute(null);
    }

    public void ScrollToQuickAction()
    {
        SettingsViewContent.ScrollToQuickAction();
    }

    public void OpenFirstServerConsole()
    {
        var srv = ViewModel.Servers.FirstOrDefault();
        if (srv != null)
        {
            OnCardManageRequested(this, srv);
        }
    }

    // MARK: - Easter Egg Handlers & Controls
    [DllImport("user32.dll")]
    private static extern short GetAsyncKeyState(int vKey);

    private void OnCtrlTInvoked(KeyboardAccelerator sender, KeyboardAcceleratorInvokedEventArgs args)
    {
        args.Handled = true;
        ToggleEasterEgg();
    }

    private void OnCtrlDInvoked(KeyboardAccelerator sender, KeyboardAcceleratorInvokedEventArgs args)
    {
        args.Handled = true;
        OpenDiscordVIPModal();
    }

    private void OnEscapeInvoked(KeyboardAccelerator sender, KeyboardAcceleratorInvokedEventArgs args)
    {
        if (DiscordVIPModalOverlay.Visibility == Visibility.Visible)
        {
            args.Handled = true;
            DiscordVIPModalOverlay.Visibility = Visibility.Collapsed;
            return;
        }

        if (EasterEggOverlay.Visibility == Visibility.Visible)
        {
            args.Handled = true;
            CloseEasterEgg();
        }
    }

    private void OnDashboardPreviewKeyDown(object sender, KeyRoutedEventArgs e)
    {
        if (DiscordVIPModalOverlay.Visibility == Visibility.Visible && e.Key == Windows.System.VirtualKey.Escape)
        {
            e.Handled = true;
            DiscordVIPModalOverlay.Visibility = Visibility.Collapsed;
            return;
        }

        if (EasterEggOverlay.Visibility == Visibility.Visible && e.Key == Windows.System.VirtualKey.Escape)
        {
            e.Handled = true;
            CloseEasterEgg();
            return;
        }

        if (e.Key == Windows.System.VirtualKey.T)
        {
            bool isCtrl = (GetAsyncKeyState(0x11) & 0x8000) != 0; // VK_CONTROL
            if (isCtrl)
            {
                e.Handled = true;
                ToggleEasterEgg();
            }
        }
        else if (e.Key == Windows.System.VirtualKey.D)
        {
            bool isCtrl = (GetAsyncKeyState(0x11) & 0x8000) != 0; // VK_CONTROL
            if (isCtrl)
            {
                e.Handled = true;
                OpenDiscordVIPModal();
            }
        }
    }

    public void OpenDiscordVIPModal()
    {
        DiscordVIPModal.CurrentUser = AuthVM?.CurrentUser;
        DiscordVIPModal.RefreshState();
        DiscordVIPModalOverlay.Visibility = Visibility.Visible;
    }

    private void OnDiscordVIPModalOverlayTapped(object sender, TappedRoutedEventArgs e)
    {
        if (ReferenceEquals(e.OriginalSource, DiscordVIPModalOverlay))
        {
            DiscordVIPModalOverlay.Visibility = Visibility.Collapsed;
        }
    }

    public void UpdateThemeCustomizations()
    {
        var theme = ThemeManager.Shared;
        bool hasCustomBg = theme.HasActiveCustomBackground;

        if (hasCustomBg && theme.BackgroundBitmap != null)
        {
            CustomBgOverlayGrid.Visibility = Visibility.Visible;
            CustomBgImage.Source = theme.BackgroundBitmap;
            CustomBgImage.Opacity = theme.CurrentConfig.BackgroundOpacity;
            CustomBgDarkOverlay.Opacity = theme.CurrentConfig.BackgroundOverlayDarkness;
            DashboardRootGrid.Background = new SolidColorBrush(Colors.Transparent);
        }
        else
        {
            CustomBgOverlayGrid.Visibility = Visibility.Collapsed;
            DashboardRootGrid.Background = (Brush)Application.Current.Resources["OvernodeBackgroundBrush"];
        }

        if (theme.CurrentConfig.SidebarPosition == SidebarPosition.Right)
        {
            WorkspaceCol0.Width = new GridLength(1, GridUnitType.Star);
            WorkspaceCol1.Width = GridLength.Auto;
            Grid.SetColumn(Sidebar, 1);
            Grid.SetColumn(ContentAreaGrid, 0);
        }
        else
        {
            WorkspaceCol0.Width = GridLength.Auto;
            WorkspaceCol1.Width = new GridLength(1, GridUnitType.Star);
            Grid.SetColumn(Sidebar, 0);
            Grid.SetColumn(ContentAreaGrid, 1);
        }
    }

    public void ToggleEasterEgg()
    {
        if (EasterEggOverlay.Visibility == Visibility.Visible)
        {
            CloseEasterEgg();
        }
        else if (ViewModel.SelectedTab == NavigationTab.Settings && ServerDetailView.Visibility != Visibility.Visible)
        {
            OpenEasterEgg();
        }
    }

    public void OpenEasterEgg()
    {
        EasterEggOverlay.Visibility = Visibility.Visible;
        EasterEggOverlay.InitializeAndStart();
    }

    public void CloseEasterEgg()
    {
        if (EasterEggOverlay.Visibility == Visibility.Visible)
        {
            EasterEggOverlay.Close();
        }
    }
}
