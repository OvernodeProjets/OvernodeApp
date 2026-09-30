using System;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.ViewModels;
using Windows.UI;

namespace Overnode.App.Views.Server;

public sealed partial class ServerDetailControl : UserControl
{
    private static readonly SolidColorBrush OnlineBrush = new(Color.FromArgb(255, 64, 199, 128));
    private static readonly SolidColorBrush TransitionBrush = new(Color.FromArgb(255, 245, 158, 11));
    private static readonly SolidColorBrush OfflineBrush = new(Color.FromArgb(255, 113, 128, 150));

    public ServerDetailViewModel? ViewModel => DataContext as ServerDetailViewModel;

    public event EventHandler? ServerDeleted;

    public ServerDetailControl()
    {
        this.InitializeComponent();
        LocalizationManager.Instance.LanguageChanged += (s, e) => UpdateLocalization();
        DataContextChanged += OnDataContextChanged;
        SettingsTab.ServerDeleted += (s, e) => ServerDeleted?.Invoke(this, EventArgs.Empty);
        UpdateLocalization();
    }

    private void OnDataContextChanged(FrameworkElement sender, DataContextChangedEventArgs args)
    {
        if (ViewModel != null)
        {
            ConsoleTab.DataContext = ViewModel;
            RenewalTab.DataContext = ViewModel;
            FilesTab.DataContext = ViewModel;
            SubdomainsTab.DataContext = ViewModel;
            SubusersTab.DataContext = ViewModel;
            PackageTab.DataContext = ViewModel;
            PluginsTab.DataContext = ViewModel;
            LogsTab.DataContext = ViewModel;
            SettingsTab.DataContext = ViewModel;

            ViewModel.PropertyChanged += (ps, pe) =>
            {
                if (pe.PropertyName == nameof(ServerDetailViewModel.SelectedTab))
                {
                    SwitchTab(ViewModel.SelectedTab);
                }
                else if (pe.PropertyName == nameof(ServerDetailViewModel.Server) ||
                         pe.PropertyName == nameof(ServerDetailViewModel.IsPowerLoading) ||
                         pe.PropertyName == nameof(ServerDetailViewModel.ErrorMessage))
                {
                    DispatcherQueue.TryEnqueue(() => UpdateHeaderUI());
                }
            };

            UpdateHeaderUI();
            SwitchTab(ViewModel.SelectedTab);
        }
    }

    private void UpdateLocalization()
    {
        SharedBadgeText.Text = LocalizationManager.Instance.GetString("server_badge_shared");
    }

    public void UpdateHeaderUI()
    {
        if (ViewModel == null) return;
        var srv = ViewModel.Server;

        ServerNameText.Text = srv.Name;
        ServerIdentifierText.Text = srv.Identifier;
        SharedBadge.Visibility = !srv.IsOwner ? Visibility.Visible : Visibility.Collapsed;

        // Status color
        string state = srv.State.ToLowerInvariant();
        if (state == "running")
        {
            StatusDot.Fill = OnlineBrush;
        }
        else if (state is "starting" or "stopping")
        {
            StatusDot.Fill = TransitionBrush;
        }
        else
        {
            StatusDot.Fill = OfflineBrush;
        }

        // Button enabled and loading states
        bool isPowerLoading = ViewModel.IsPowerLoading;
        StartBtn.IsEnabled = srv.CanStart && state != "running" && state != "starting" && !isPowerLoading;
        RestartBtn.IsEnabled = srv.CanRestart && state == "running" && !isPowerLoading;
        StopBtn.IsEnabled = srv.CanStop && state != "offline" && !isPowerLoading;
        KillBtn.IsEnabled = srv.CanStop && !isPowerLoading;

        StartIcon.Visibility = isPowerLoading ? Visibility.Collapsed : Visibility.Visible;
        StartProgress.Visibility = isPowerLoading ? Visibility.Visible : Visibility.Collapsed;
        StartProgress.IsActive = isPowerLoading;

        if (!string.IsNullOrEmpty(ViewModel.ErrorMessage))
        {
            ErrorBannerText.Text = ViewModel.ErrorMessage;
            ErrorBanner.Visibility = Visibility.Visible;
        }
        else
        {
            ErrorBanner.Visibility = Visibility.Collapsed;
        }
    }

    public void SwitchTab(ServerTab tab)
    {
        ConsoleTab.Visibility = tab == ServerTab.Console ? Visibility.Visible : Visibility.Collapsed;
        RenewalTab.Visibility = tab == ServerTab.Renewal ? Visibility.Visible : Visibility.Collapsed;
        FilesTab.Visibility = tab == ServerTab.Files ? Visibility.Visible : Visibility.Collapsed;
        SubdomainsTab.Visibility = tab == ServerTab.Subdomains ? Visibility.Visible : Visibility.Collapsed;
        SubusersTab.Visibility = tab == ServerTab.Subusers ? Visibility.Visible : Visibility.Collapsed;
        PackageTab.Visibility = tab == ServerTab.Package ? Visibility.Visible : Visibility.Collapsed;
        PluginsTab.Visibility = tab == ServerTab.Plugins ? Visibility.Visible : Visibility.Collapsed;
        LogsTab.Visibility = tab == ServerTab.Logs ? Visibility.Visible : Visibility.Collapsed;
        SettingsTab.Visibility = tab == ServerTab.Settings ? Visibility.Visible : Visibility.Collapsed;

        if (tab == ServerTab.Console)
        {
            ConsoleTab.UpdateStatsUI();
        }
        else if (tab == ServerTab.Renewal)
        {
            RenewalTab.UpdateUI();
        }
        else if (tab == ServerTab.Files)
        {
            FilesTab.UpdateUI();
        }
        else if (tab == ServerTab.Subdomains)
        {
            SubdomainsTab.UpdateUI();
        }
        else if (tab == ServerTab.Subusers)
        {
            SubusersTab.UpdateUI();
        }
        else if (tab == ServerTab.Package)
        {
            PackageTab.UpdateUI();
        }
        else if (tab == ServerTab.Plugins)
        {
            PluginsTab.UpdateUI();
        }
        else if (tab == ServerTab.Logs)
        {
            LogsTab.UpdateUI();
        }
        else if (tab == ServerTab.Settings)
        {
            SettingsTab.UpdateUI();
        }
    }

    private async void OnStartClicked(object sender, RoutedEventArgs e)
    {
        if (ViewModel != null)
        {
            await ViewModel.SendPowerSignalAsync(ServerPowerSignal.Start);
            UpdateHeaderUI();
        }
    }

    private async void OnRestartClicked(object sender, RoutedEventArgs e)
    {
        if (ViewModel != null)
        {
            await ViewModel.SendPowerSignalAsync(ServerPowerSignal.Restart);
            UpdateHeaderUI();
        }
    }

    private async void OnStopClicked(object sender, RoutedEventArgs e)
    {
        if (ViewModel != null)
        {
            await ViewModel.SendPowerSignalAsync(ServerPowerSignal.Stop);
            UpdateHeaderUI();
        }
    }

    private async void OnKillClicked(object sender, RoutedEventArgs e)
    {
        if (ViewModel == null || XamlRoot == null) return;

        var loc = LocalizationManager.Instance;
        var dialog = new ContentDialog
        {
            XamlRoot = this.XamlRoot,
            Title = loc.GetString("power_kill_confirm_title"),
            Content = loc.GetString("power_kill_confirm_msg"),
            PrimaryButtonText = loc.GetString("power_kill"),
            CloseButtonText = loc.GetString("generic_cancel"),
            DefaultButton = ContentDialogButton.Close
        };

        var result = await dialog.ShowAsync();
        if (result == ContentDialogResult.Primary)
        {
            await ViewModel.SendPowerSignalAsync(ServerPowerSignal.Kill);
            UpdateHeaderUI();
        }
    }

    private void OnErrorDismissClicked(object sender, RoutedEventArgs e)
    {
        if (ViewModel != null)
        {
            ViewModel.ErrorMessage = null;
        }
        ErrorBanner.Visibility = Visibility.Collapsed;
    }
}
