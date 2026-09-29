using System;
using System.Collections.Generic;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Overnode.App.Localization;
using Overnode.App.Models;
using Windows.UI;

namespace Overnode.App.Views.Components;

public sealed partial class SidebarControl : UserControl
{
    private static readonly SolidColorBrush ActiveTabBg = new(Color.FromArgb(20, 255, 255, 255));
    private static readonly SolidColorBrush InactiveTabBg = new(Colors.Transparent);
    private static readonly SolidColorBrush ActiveTabFg = new(Colors.White);
    private static readonly SolidColorBrush InactiveTabFg = new(Color.FromArgb(255, 149, 161, 173));

    public static readonly DependencyProperty SelectedTabProperty =
        DependencyProperty.Register(nameof(SelectedTab), typeof(NavigationTab), typeof(SidebarControl),
            new PropertyMetadata(NavigationTab.Dashboard, (d, e) => ((SidebarControl)d).UpdateTabSelection()));

    public static readonly DependencyProperty CurrentUserProperty =
        DependencyProperty.Register(nameof(CurrentUser), typeof(User), typeof(SidebarControl),
            new PropertyMetadata(null, (d, e) => ((SidebarControl)d).UpdateUserUI()));

    public static readonly DependencyProperty ServersProperty =
        DependencyProperty.Register(nameof(Servers), typeof(IEnumerable<ServerInstance>), typeof(SidebarControl),
            new PropertyMetadata(null, (d, e) => ((SidebarControl)d).UpdateServersUI()));

    public static readonly DependencyProperty SelectedServerProperty =
        DependencyProperty.Register(nameof(SelectedServer), typeof(ServerInstance), typeof(SidebarControl),
            new PropertyMetadata(null, (d, e) => ((SidebarControl)d).UpdateServerModeUI()));

    public static readonly DependencyProperty SelectedServerTabProperty =
        DependencyProperty.Register(nameof(SelectedServerTab), typeof(ServerTab), typeof(SidebarControl),
            new PropertyMetadata(ServerTab.Console, (d, e) => ((SidebarControl)d).UpdateServerTabSelection()));

    public NavigationTab SelectedTab
    {
        get => (NavigationTab)GetValue(SelectedTabProperty);
        set => SetValue(SelectedTabProperty, value);
    }

    public User? CurrentUser
    {
        get => (User?)GetValue(CurrentUserProperty);
        set => SetValue(CurrentUserProperty, value);
    }

    public IEnumerable<ServerInstance>? Servers
    {
        get => (IEnumerable<ServerInstance>?)GetValue(ServersProperty);
        set => SetValue(ServersProperty, value);
    }

    public ServerInstance? SelectedServer
    {
        get => (ServerInstance?)GetValue(SelectedServerProperty);
        set => SetValue(SelectedServerProperty, value);
    }

    public ServerTab SelectedServerTab
    {
        get => (ServerTab)GetValue(SelectedServerTabProperty);
        set => SetValue(SelectedServerTabProperty, value);
    }

    public event EventHandler<NavigationTab>? TabSelected;
    public event EventHandler<ServerInstance>? QuickServerSelected;
    public event EventHandler<ServerTab>? ServerTabSelected;
    public event EventHandler? BackToServersRequested;
    public event EventHandler? LogoutRequested;

    public SidebarControl()
    {
        this.InitializeComponent();
        LocalizationManager.Instance.LanguageChanged += (s, e) => UpdateLocalization();
        UpdateLocalization();
        UpdateTabSelection();
        UpdateServerModeUI();
    }

    private void UpdateLocalization()
    {
        var loc = LocalizationManager.Instance;
        NavDashboardText.Text = loc.GetString("nav_dashboard");
        NavServersText.Text = loc.GetString("nav_servers");
        NavWalletText.Text = loc.GetString("nav_wallet");
        NavDailyRewardText.Text = loc.GetString("nav_daily_reward");
        NavStoreText.Text = loc.GetString("nav_store");
        NavSupportText.Text = loc.GetString("nav_support");
        NavAfkText.Text = loc.GetString("nav_afk");
        NavSettingsText.Text = loc.GetString("nav_settings");

        QuickServersTitle.Text = loc.GetString("dashboard_servers_title").ToUpperInvariant();
        CoinsLabelText.Text = loc.GetString("coins_balance");
        MenuLogoutItem.Text = loc.GetString("nav_logout");

        BackToServersText.Text = loc.GetString("server_back_to_servers");
        ServerTabConsoleText.Text = loc.GetString("server_tab_console");
        ServerTabRenewalText.Text = loc.GetString("server_tab_renewal");
        ServerTabFilesText.Text = loc.GetString("server_tab_files");
        ServerTabSubdomainsText.Text = loc.GetString("server_tab_subdomains");
        ServerTabSubusersText.Text = loc.GetString("server_tab_subusers");
        ServerTabSettingsText.Text = loc.GetString("server_tab_settings");
    }

    private void UpdateTabSelection()
    {
        SetButtonActive(NavDashboardBtn, NavDashboardText, SelectedTab == NavigationTab.Dashboard);
        SetButtonActive(NavServersBtn, NavServersText, SelectedTab == NavigationTab.Servers);
        SetButtonActive(NavWalletBtn, NavWalletText, SelectedTab == NavigationTab.Wallet);
        SetButtonActive(NavDailyRewardBtn, NavDailyRewardText, SelectedTab == NavigationTab.DailyReward);
        SetButtonActive(NavStoreBtn, NavStoreText, SelectedTab == NavigationTab.Store);
        SetButtonActive(NavSupportBtn, NavSupportText, SelectedTab == NavigationTab.Support);
        SetButtonActive(NavAfkBtn, NavAfkText, SelectedTab == NavigationTab.Afk);
        SetButtonActive(NavSettingsBtn, NavSettingsText, SelectedTab == NavigationTab.Settings);
    }

    private void UpdateServerModeUI()
    {
        bool inServerMode = SelectedServer != null;
        GlobalNavContainer.Visibility = inServerMode ? Visibility.Collapsed : Visibility.Visible;
        ServerNavContainer.Visibility = inServerMode ? Visibility.Visible : Visibility.Collapsed;

        if (SelectedServer != null)
        {
            ServerSidebarName.Text = SelectedServer.Name;
            ServerSidebarSharedIcon.Visibility = !SelectedServer.IsOwner ? Visibility.Visible : Visibility.Collapsed;
            ServerSidebarDot.Fill = SelectedServer.IsOnline
                ? new SolidColorBrush(Color.FromArgb(255, 64, 199, 128))
                : new SolidColorBrush(Color.FromArgb(255, 113, 128, 150));
            UpdateServerTabSelection();
        }
    }

    private void UpdateServerTabSelection()
    {
        SetButtonActive(ServerTabConsoleBtn, ServerTabConsoleText, SelectedServerTab == ServerTab.Console);
        SetButtonActive(ServerTabRenewalBtn, ServerTabRenewalText, SelectedServerTab == ServerTab.Renewal);
        SetButtonActive(ServerTabFilesBtn, ServerTabFilesText, SelectedServerTab == ServerTab.Files);
        SetButtonActive(ServerTabSubdomainsBtn, ServerTabSubdomainsText, SelectedServerTab == ServerTab.Subdomains);
        SetButtonActive(ServerTabSubusersBtn, ServerTabSubusersText, SelectedServerTab == ServerTab.Subusers);
        SetButtonActive(ServerTabSettingsBtn, ServerTabSettingsText, SelectedServerTab == ServerTab.Settings);
    }

    private static void SetButtonActive(Button btn, TextBlock textBlock, bool isActive)
    {
        btn.Background = isActive ? ActiveTabBg : InactiveTabBg;
        textBlock.Foreground = isActive ? ActiveTabFg : InactiveTabFg;
        textBlock.FontWeight = isActive ? Microsoft.UI.Text.FontWeights.SemiBold : Microsoft.UI.Text.FontWeights.Medium;
    }

    private void UpdateUserUI()
    {
        if (CurrentUser != null)
        {
            UsernameText.Text = CurrentUser.DisplayName;
            MenuUsernameItem.Text = CurrentUser.DisplayName;
            EmailText.Text = CurrentUser.Email;
            MenuEmailItem.Text = CurrentUser.Email;
            UserCoinsText.Text = CurrentUser.Coins.ToString("N0");
            UserInitialText.Text = CurrentUser.Initial;
        }
        else
        {
            UsernameText.Text = "Overnode";
            EmailText.Text = string.Empty;
            UserCoinsText.Text = "0";
            UserInitialText.Text = "O";
        }
    }

    private void UpdateServersUI()
    {
        QuickServersItemsControl.ItemsSource = Servers;
        bool hasServers = false;
        if (Servers != null)
        {
            foreach (var _ in Servers)
            {
                hasServers = true;
                break;
            }
        }
        QuickServersContainer.Visibility = hasServers ? Visibility.Visible : Visibility.Collapsed;
    }

    private void OnTabClicked(object sender, RoutedEventArgs e)
    {
        if (sender is Button btn && btn.Tag is string tagStr && Enum.TryParse<NavigationTab>(tagStr, out var tab))
        {
            SelectedTab = tab;
            UpdateTabSelection();
            TabSelected?.Invoke(this, tab);
        }
    }

    private void OnServerTabClicked(object sender, RoutedEventArgs e)
    {
        if (sender is Button btn && btn.Tag is string tagStr && Enum.TryParse<ServerTab>(tagStr, out var tab))
        {
            SelectedServerTab = tab;
            UpdateServerTabSelection();
            ServerTabSelected?.Invoke(this, tab);
        }
    }

    private void OnBackToServersClicked(object sender, RoutedEventArgs e)
    {
        SelectedServer = null;
        UpdateServerModeUI();
        BackToServersRequested?.Invoke(this, EventArgs.Empty);
    }

    private void OnQuickServerClicked(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement fe && fe.DataContext is ServerInstance srv)
        {
            QuickServerSelected?.Invoke(this, srv);
        }
    }

    private void OnLogoutClicked(object sender, RoutedEventArgs e)
    {
        LogoutRequested?.Invoke(this, EventArgs.Empty);
    }
}
