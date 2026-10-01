using System;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Overnode.App.Localization;
using Overnode.App.Models;
using Windows.UI;

namespace Overnode.App.Views.Components;

public sealed partial class DashboardServerCardControl : UserControl
{
    public static readonly DependencyProperty ServerProperty =
        DependencyProperty.Register(nameof(Server), typeof(ServerInstance), typeof(DashboardServerCardControl),
            new PropertyMetadata(null, (d, e) => ((DashboardServerCardControl)d).OnServerChanged(e.OldValue as ServerInstance, e.NewValue as ServerInstance)));

    public ServerInstance? Server
    {
        get => (ServerInstance?)GetValue(ServerProperty);
        set => SetValue(ServerProperty, value);
    }

    public event EventHandler<ServerInstance>? ManageRequested;
    public event EventHandler<ServerInstance>? DeleteRequested;

    public DashboardServerCardControl()
    {
        this.InitializeComponent();

        this.DataContextChanged += (s, e) =>
        {
            if (DataContext is ServerInstance srv)
            {
                Server = srv;
            }
        };

        this.Loaded += (s, e) =>
        {
            if (DataContext is ServerInstance srv && Server == null)
            {
                Server = srv;
            }
            UpdateUI();
        };

        this.Unloaded += (s, e) =>
        {
            if (Server != null)
            {
                Server.PropertyChanged -= OnServerPropertyChanged;
            }
        };

        LocalizationManager.Instance.LanguageChanged += (s, e) => UpdateUI();
    }

    private void OnServerChanged(ServerInstance? oldServer, ServerInstance? newServer)
    {
        if (oldServer != null)
        {
            oldServer.PropertyChanged -= OnServerPropertyChanged;
        }
        if (newServer != null)
        {
            newServer.PropertyChanged += OnServerPropertyChanged;
        }
        UpdateUI();
    }

    private void OnServerPropertyChanged(object? sender, System.ComponentModel.PropertyChangedEventArgs e)
    {
        DispatcherQueue?.TryEnqueue(UpdateUI);
    }

    private void UpdateUI()
    {
        if (Server == null) return;

        var loc = LocalizationManager.Instance;
        ServerNameText.Text = Server.Name;
        ManageButtonText.Text = loc.GetString("server_manage_button");
        FlyoutManageItem.Text = loc.GetString("server_manage_button");
        FlyoutDeleteItem.Text = loc.GetString("settings_delete_button") ?? "Supprimer";

        // Shared Badge
        SharedBadge.Visibility = Server.IsShared ? Visibility.Visible : Visibility.Collapsed;
        SharedBadgeText.Text = loc.GetString("server_badge_shared");

        // Status Text & Color
        StatusText.Text = loc.GetString(Server.StatusKey);
        StatusDot.Fill = new SolidColorBrush(ParseHexColor(Server.StatusColorHex));

        // Consumptions
        MemoryLabelText.Text = loc.GetString("dashboard_gauge_memory");
        MemoryText.Text = Server.MemoryDisplay;
        MemoryProgress.Value = Server.MemoryPercentValue;

        CpuLabelText.Text = loc.GetString("dashboard_gauge_cpu");
        CpuText.Text = Server.CpuDisplay;
        CpuProgress.Value = Server.CpuPercentValue;

        DiskLabelText.Text = loc.GetString("dashboard_gauge_disk");
        DiskText.Text = Server.DiskDisplay;
        DiskProgress.Value = Server.DiskPercentValue;

        // Context flyout permissions
        FlyoutDeleteItem.IsEnabled = Server.CanDelete;
    }

    private static Color ParseHexColor(string hex)
    {
        hex = hex.TrimStart('#');
        if (hex.Length == 6)
        {
            var r = Convert.ToByte(hex.Substring(0, 2), 16);
            var g = Convert.ToByte(hex.Substring(2, 2), 16);
            var b = Convert.ToByte(hex.Substring(4, 2), 16);
            return Color.FromArgb(255, r, g, b);
        }
        return Colors.Gray;
    }

    private void OnManageClicked(object sender, RoutedEventArgs e)
    {
        if (Server != null)
        {
            ManageRequested?.Invoke(this, Server);
        }
    }

    private void OnDeleteClicked(object sender, RoutedEventArgs e)
    {
        if (Server != null)
        {
            DeleteRequested?.Invoke(this, Server);
        }
    }
}
