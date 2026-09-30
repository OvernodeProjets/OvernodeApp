using System;
using System.Collections.Specialized;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Overnode.App.Localization;
using Overnode.App.ViewModels;
using Windows.System;
using Windows.UI;

namespace Overnode.App.Views.Server;

public sealed partial class ServerConsoleTabControl : UserControl
{
    private static readonly SolidColorBrush RedBrush = new(Color.FromArgb(255, 248, 113, 113));
    private static readonly SolidColorBrush YellowBrush = new(Color.FromArgb(255, 251, 191, 36));
    private static readonly SolidColorBrush CyanBrush = new(Color.FromArgb(255, 56, 189, 248));
    private static readonly SolidColorBrush NormalBrush = new(Color.FromArgb(255, 203, 213, 225));

    public ServerDetailViewModel? ViewModel => DataContext as ServerDetailViewModel;
    private ServerDetailViewModel? _boundViewModel;

    public ServerConsoleTabControl()
    {
        this.InitializeComponent();
        LocalizationManager.Instance.LanguageChanged += (s, e) => UpdateLocalization();
        DataContextChanged += OnDataContextChanged;
        UpdateLocalization();
    }

    private void OnDataContextChanged(FrameworkElement sender, DataContextChangedEventArgs args)
    {
        if (_boundViewModel != null)
        {
            _boundViewModel.ConsoleLines.CollectionChanged -= OnConsoleLinesChanged;
            _boundViewModel.PropertyChanged -= OnViewModelPropertyChanged;
        }

        _boundViewModel = DataContext as ServerDetailViewModel;
        if (_boundViewModel != null)
        {
            ConsoleItemsControl.ItemsSource = _boundViewModel.ConsoleLines;
            _boundViewModel.ConsoleLines.CollectionChanged += OnConsoleLinesChanged;
            _boundViewModel.PropertyChanged += OnViewModelPropertyChanged;
            UpdateStatsUI();
        }
    }

    private void OnViewModelPropertyChanged(object? sender, System.ComponentModel.PropertyChangedEventArgs e)
    {
        DispatcherQueue.TryEnqueue(() => UpdateStatsUI());
    }

    private void OnConsoleLinesChanged(object? sender, NotifyCollectionChangedEventArgs e)
    {
        DispatcherQueue.TryEnqueue(() =>
        {
            ConsoleScrollViewer.ChangeView(null, ConsoleScrollViewer.ScrollableHeight, null, false);
        });
    }

    private void UpdateLocalization()
    {
        var loc = LocalizationManager.Instance;
        ResourceCpuLabel.Text = loc.GetString("resource_cpu").ToUpperInvariant();
        ResourceRamLabel.Text = loc.GetString("resource_ram").ToUpperInvariant();
        ResourceDiskLabel.Text = loc.GetString("resource_disk").ToUpperInvariant();
        CommandTextBox.PlaceholderText = loc.GetString("console_input_placeholder");
        SendText.Text = loc.GetString("console_send");
        ClearText.Text = loc.GetString("console_clear");
        UpdateStatsUI();
    }

    public void UpdateStatsUI()
    {
        if (ViewModel == null) return;
        var srv = ViewModel.Server;
        CpuText.Text = $"{srv.CpuUsedPercent:F1}% / {srv.CpuLimitPercent:F0}%";
        RamText.Text = $"{srv.MemoryUsedMB:F0} / {srv.MemoryLimitMB:F0} MB";
        DiskText.Text = $"{srv.DiskUsedMB:F0} / {srv.DiskLimitMB:F0} MB";
    }

    private void OnConsoleLineLoaded(object sender, RoutedEventArgs e)
    {
        if (sender is TextBlock tb && tb.Text is string text)
        {
            if (text.Contains("[Error]", StringComparison.OrdinalIgnoreCase) ||
                text.Contains("Exception", StringComparison.OrdinalIgnoreCase) ||
                text.Contains("ERROR", StringComparison.OrdinalIgnoreCase))
            {
                tb.Foreground = RedBrush;
            }
            else if (text.Contains("[Action]", StringComparison.OrdinalIgnoreCase) ||
                     text.Contains("WARN", StringComparison.OrdinalIgnoreCase))
            {
                tb.Foreground = YellowBrush;
            }
            else if (text.StartsWith("> "))
            {
                tb.Foreground = CyanBrush;
            }
            else
            {
                tb.Foreground = NormalBrush;
            }
        }
    }

    private async void OnSendCommandClicked(object sender, RoutedEventArgs e)
    {
        await SendCommandInternalAsync();
    }

    private async void OnCommandKeyDown(object sender, KeyRoutedEventArgs e)
    {
        if (e.Key == VirtualKey.Enter)
        {
            e.Handled = true;
            await SendCommandInternalAsync();
        }
    }

    private async System.Threading.Tasks.Task SendCommandInternalAsync()
    {
        if (ViewModel == null) return;
        var text = CommandTextBox.Text;
        if (string.IsNullOrWhiteSpace(text)) return;
        CommandTextBox.Text = string.Empty;

        ViewModel.CommandInput = text;
        await ViewModel.SendConsoleCommandAsync();
    }

    private void OnClearConsoleClicked(object sender, RoutedEventArgs e)
    {
        ViewModel?.ConsoleLines.Clear();
    }
}
