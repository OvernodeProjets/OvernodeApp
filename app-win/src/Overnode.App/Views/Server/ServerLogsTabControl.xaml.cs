using System;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Overnode.App.Localization;
using Overnode.App.ViewModels;

namespace Overnode.App.Views.Server;

public sealed partial class ServerLogsTabControl : UserControl
{
    public ServerDetailViewModel? ViewModel => DataContext as ServerDetailViewModel;
    private ServerDetailViewModel? _boundViewModel;

    public ServerLogsTabControl()
    {
        this.InitializeComponent();
        LocalizationManager.Instance.LanguageChanged += (s, e) => UpdateLocalization();
        DataContextChanged += OnDataContextChanged;
        Loaded += OnLoaded;
        UpdateLocalization();
    }

    private void OnDataContextChanged(FrameworkElement sender, DataContextChangedEventArgs args)
    {
        if (_boundViewModel != null)
        {
            _boundViewModel.PropertyChanged -= OnViewModelPropertyChanged;
        }

        _boundViewModel = DataContext as ServerDetailViewModel;
        if (_boundViewModel != null)
        {
            _boundViewModel.PropertyChanged += OnViewModelPropertyChanged;
            if (_boundViewModel.ActivityLogs.Count == 0 && !_boundViewModel.IsLoading)
            {
                _ = _boundViewModel.LoadLogsAsync();
            }
        }

        UpdateUI();
    }

    private void OnViewModelPropertyChanged(object? sender, System.ComponentModel.PropertyChangedEventArgs e)
    {
        DispatcherQueue.TryEnqueue(() => UpdateUI());
    }

    private async void OnLoaded(object sender, RoutedEventArgs e)
    {
        if (ViewModel != null)
        {
            if (ViewModel.ActivityLogs.Count == 0 && !ViewModel.IsLoading)
            {
                await ViewModel.LoadLogsAsync();
            }
            UpdateUI();
        }
    }

    private void UpdateLocalization()
    {
        var loc = LocalizationManager.Instance;
        LogsTitleText.Text = loc.GetString("logs_title");
        LogsSubtitleText.Text = loc.GetString("logs_subtitle");
        LogsEmptyText.Text = loc.GetString("logs_empty");
    }

    public void UpdateUI()
    {
        if (ViewModel == null) return;

        LogsProgressRing.IsActive = ViewModel.IsLoading;
        LogsProgressRing.Visibility = ViewModel.IsLoading ? Visibility.Visible : Visibility.Collapsed;

        LogsItemsControl.ItemsSource = ViewModel.ActivityLogs;
        LogsEmptyState.Visibility = (!ViewModel.IsLoading && ViewModel.ActivityLogs.Count == 0)
            ? Visibility.Visible : Visibility.Collapsed;
    }

    private async void OnRefreshClicked(object sender, RoutedEventArgs e)
    {
        if (ViewModel != null)
        {
            await ViewModel.LoadLogsAsync(force: true);
            UpdateUI();
        }
    }
}
