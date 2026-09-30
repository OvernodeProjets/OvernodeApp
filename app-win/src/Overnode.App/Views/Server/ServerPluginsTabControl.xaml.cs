using System;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.ViewModels;
using Windows.System;
using Windows.UI;

namespace Overnode.App.Views.Server;

public sealed partial class ServerPluginsTabControl : UserControl
{
    private static readonly SolidColorBrush ActiveTabBrush = new(Color.FromArgb(32, 255, 255, 255));
    private static readonly SolidColorBrush InactiveTabBrush = new(Microsoft.UI.Colors.Transparent);
    private static readonly SolidColorBrush ActiveTextBrush = new(Microsoft.UI.Colors.White);
    private static readonly SolidColorBrush InactiveTextBrush = new(Color.FromArgb(255, 149, 161, 173));

    public ServerDetailViewModel? ViewModel => DataContext as ServerDetailViewModel;
    private ServerDetailViewModel? _boundViewModel;

    public ServerPluginsTabControl()
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
            if (_boundViewModel.InstalledPlugins.Count == 0 && !_boundViewModel.IsLoading)
            {
                _ = _boundViewModel.LoadPluginsAsync();
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
            if (ViewModel.InstalledPlugins.Count == 0 && !ViewModel.IsLoading)
            {
                await ViewModel.LoadPluginsAsync();
            }
            UpdateUI();
        }
    }

    private void UpdateLocalization()
    {
        var loc = LocalizationManager.Instance;
        TabInstalledText.Text = loc.GetString("plugins_tab_installed");
        TabSearchText.Text = loc.GetString("plugins_tab_search");
        NoneInstalledText.Text = loc.GetString("plugins_none_installed");
        SearchBox.PlaceholderText = loc.GetString("plugins_search_placeholder");
        SearchButtonText.Text = loc.GetString("plugins_search_btn");
        NoSearchResultsText.Text = loc.GetString("plugins_no_results");
    }

    public void UpdateUI()
    {
        if (ViewModel == null) return;

        bool isInstalledTab = ViewModel.PluginSubTab == 0;
        TabInstalledBtn.Background = isInstalledTab ? ActiveTabBrush : InactiveTabBrush;
        TabInstalledText.Foreground = isInstalledTab ? ActiveTextBrush : InactiveTextBrush;
        TabInstalledText.FontWeight = isInstalledTab ? Microsoft.UI.Text.FontWeights.SemiBold : Microsoft.UI.Text.FontWeights.Medium;

        TabSearchBtn.Background = !isInstalledTab ? ActiveTabBrush : InactiveTabBrush;
        TabSearchText.Foreground = !isInstalledTab ? ActiveTextBrush : InactiveTextBrush;
        TabSearchText.FontWeight = !isInstalledTab ? Microsoft.UI.Text.FontWeights.SemiBold : Microsoft.UI.Text.FontWeights.Medium;

        InstalledSection.Visibility = isInstalledTab ? Visibility.Visible : Visibility.Collapsed;
        SearchSection.Visibility = !isInstalledTab ? Visibility.Visible : Visibility.Collapsed;

        // Installed view
        InstalledProgressRing.IsActive = ViewModel.IsLoading;
        InstalledProgressRing.Visibility = ViewModel.IsLoading ? Visibility.Visible : Visibility.Collapsed;
        InstalledItemsControl.ItemsSource = ViewModel.InstalledPlugins;
        InstalledEmptyState.Visibility = (!ViewModel.IsLoading && ViewModel.InstalledPlugins.Count == 0)
            ? Visibility.Visible : Visibility.Collapsed;

        // Search view
        SearchProgressRing.IsActive = ViewModel.IsSearchingPlugins;
        SearchProgressRing.Visibility = ViewModel.IsSearchingPlugins ? Visibility.Visible : Visibility.Collapsed;
        SearchItemsControl.ItemsSource = ViewModel.PluginSearchResults;
        SearchEmptyState.Visibility = (!ViewModel.IsSearchingPlugins && ViewModel.PluginSearchResults.Count == 0 && !string.IsNullOrEmpty(ViewModel.PluginSearchQuery))
            ? Visibility.Visible : Visibility.Collapsed;

        // Feedback Banners
        if (!string.IsNullOrEmpty(ViewModel.SuccessMessage))
        {
            PluginSuccessText.Text = ViewModel.SuccessMessage;
            PluginSuccessBanner.Visibility = Visibility.Visible;
        }
        else
        {
            PluginSuccessBanner.Visibility = Visibility.Collapsed;
        }

        if (!string.IsNullOrEmpty(ViewModel.ErrorMessage))
        {
            PluginErrorText.Text = ViewModel.ErrorMessage;
            PluginErrorBanner.Visibility = Visibility.Visible;
        }
        else
        {
            PluginErrorBanner.Visibility = Visibility.Collapsed;
        }
    }

    private void OnTabInstalledClicked(object sender, RoutedEventArgs e)
    {
        if (ViewModel != null)
        {
            ViewModel.PluginSubTab = 0;
            UpdateUI();
        }
    }

    private async void OnTabSearchClicked(object sender, RoutedEventArgs e)
    {
        if (ViewModel != null)
        {
            ViewModel.PluginSubTab = 1;
            UpdateUI();
            if (ViewModel.PluginSearchResults.Count == 0)
            {
                ViewModel.PluginSearchQuery = "world";
                SearchBox.Text = "world";
                await ViewModel.SearchPluginsAsync();
                UpdateUI();
            }
        }
    }

    private async void OnRefreshClicked(object sender, RoutedEventArgs e)
    {
        if (ViewModel != null)
        {
            if (ViewModel.PluginSubTab == 0)
            {
                await ViewModel.LoadPluginsAsync(force: true);
            }
            else
            {
                await ViewModel.SearchPluginsAsync();
            }
            UpdateUI();
        }
    }

    private async void OnSearchSubmitClicked(object sender, RoutedEventArgs e)
    {
        if (ViewModel != null)
        {
            ViewModel.PluginSearchQuery = SearchBox.Text;
            await ViewModel.SearchPluginsAsync();
            UpdateUI();
        }
    }

    private async void OnSearchBoxKeyDown(object sender, Microsoft.UI.Xaml.Input.KeyRoutedEventArgs e)
    {
        if (e.Key == VirtualKey.Enter && ViewModel != null)
        {
            ViewModel.PluginSearchQuery = SearchBox.Text;
            await ViewModel.SearchPluginsAsync();
            UpdateUI();
        }
    }

    private async void OnInstallPluginClicked(object sender, RoutedEventArgs e)
    {
        if (sender is Button btn && btn.Tag is ServerPluginItem plugin && ViewModel != null)
        {
            await ViewModel.InstallPluginAsync(plugin);
            UpdateUI();
        }
    }

    private async void OnUninstallPluginClicked(object sender, RoutedEventArgs e)
    {
        if (sender is Button btn && btn.Tag is ServerPluginItem plugin && ViewModel != null)
        {
            await ViewModel.UninstallPluginAsync(plugin);
            UpdateUI();
        }
    }
}
