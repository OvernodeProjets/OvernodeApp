using System;
using System.Threading.Tasks;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.ViewModels;

namespace Overnode.App.Views.Store;

public sealed partial class StoreView : UserControl
{
    private readonly LocalizationManager _loc = LocalizationManager.Instance;
    public StoreViewModel ViewModel { get; } = new();

    public event Action<int>? ResourcePurchased;

    public StoreView()
    {
        InitializeComponent();
        ViewModel.PropertyChanged += (_, _) => UpdateUI();
        _loc.LanguageChanged += (_, _) => UpdateLocalization();
        UpdateLocalization();
    }

    public async Task InitializeAsync()
    {
        await ViewModel.LoadDataAsync();
        UpdateUI();
    }

    private void UpdateLocalization()
    {
        TitleText.Text = _loc.GetString("store_title");
        SubtitleText.Text = _loc.GetString("store_subtitle");
        TabResourcesText.Text = _loc.GetString("store_tab_resources");
        TabBundlesText.Text = _loc.GetString("store_tab_bundles");
        RamTitle.Text = _loc.GetString("store_ram_title");
        RamDesc.Text = _loc.GetString("store_ram_desc");
        DiskTitle.Text = _loc.GetString("store_disk_title");
        DiskDesc.Text = _loc.GetString("store_disk_desc");
        CpuTitle.Text = _loc.GetString("store_cpu_title");
        CpuDesc.Text = _loc.GetString("store_cpu_desc");
        ServersTitle.Text = _loc.GetString("store_servers_title");
        ServersDesc.Text = _loc.GetString("store_servers_desc");
    }

    private void UpdateUI()
    {
        UserCoinsText.Text = $"{ViewModel.UserCoins:N0} {_loc.GetString("wallet_coins_suffix")}";

        bool isResources = ViewModel.SelectedTab == StoreTab.Resources;
        ResourcesPanel.Visibility = isResources ? Visibility.Visible : Visibility.Collapsed;
        BundlesPanel.Visibility = !isResources ? Visibility.Visible : Visibility.Collapsed;

        TabResourcesText.FontWeight = isResources ? Microsoft.UI.Text.FontWeights.SemiBold : Microsoft.UI.Text.FontWeights.Normal;
        TabResourcesText.Foreground = isResources ? (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"] : (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"];

        TabBundlesText.FontWeight = !isResources ? Microsoft.UI.Text.FontWeights.SemiBold : Microsoft.UI.Text.FontWeights.Normal;
        TabBundlesText.Foreground = !isResources ? (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"] : (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"];

        if (!string.IsNullOrEmpty(ViewModel.SuccessMessage))
        {
            SuccessBanner.Visibility = Visibility.Visible;
            SuccessBannerText.Text = ViewModel.SuccessMessage;
        }
        else
        {
            SuccessBanner.Visibility = Visibility.Collapsed;
        }

        UpdatePricesAndAffordability();
        UpdateBundles();
    }

    private void UpdatePricesAndAffordability()
    {
        var prices = ViewModel.StoreConfig?.Prices?.Resources;
        int ramPrice = prices != null && prices.TryGetValue("ram", out var r) ? r : 600;
        int diskPrice = prices != null && prices.TryGetValue("disk", out var d) ? d : 400;
        int cpuPrice = prices != null && prices.TryGetValue("cpu", out var c) ? c : 500;
        int srvPrice = prices != null && prices.TryGetValue("servers", out var s) ? s : 200;

        RamPriceText.Text = $"{ramPrice} coins";
        DiskPriceText.Text = $"{diskPrice} coins";
        CpuPriceText.Text = $"{cpuPrice} coins";
        ServersPriceText.Text = $"{srvPrice} coins";

        BuyRamBtn.IsEnabled = ViewModel.UserCoins >= ramPrice && !ViewModel.IsPurchasing;
        BuyDiskBtn.IsEnabled = ViewModel.UserCoins >= diskPrice && !ViewModel.IsPurchasing;
        BuyCpuBtn.IsEnabled = ViewModel.UserCoins >= cpuPrice && !ViewModel.IsPurchasing;
        BuyServersBtn.IsEnabled = ViewModel.UserCoins >= srvPrice && !ViewModel.IsPurchasing;
    }

    private void UpdateBundles()
    {
        BundlesList.ItemsSource = ViewModel.Bundles.ConvertAll(b => CreateBundleCard(b));
    }

    private FrameworkElement CreateBundleCard(StoreBundle bundle)
    {
        var border = new Border
        {
            Background = (SolidColorBrush)Application.Current.Resources["OvernodeCardBrush"],
            BorderBrush = (SolidColorBrush)Application.Current.Resources["OvernodeBorderSubtleBrush"],
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(10),
            Margin = new Thickness(6)
        };

        var stack = new StackPanel();

        // Header
        var headerBorder = new Border
        {
            BorderBrush = (SolidColorBrush)Application.Current.Resources["OvernodeBorderSubtleBrush"],
            BorderThickness = new Thickness(0, 0, 0, 1),
            Padding = new Thickness(16)
        };
        var headerStack = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 10 };
        headerStack.Children.Add(new Border
        {
            Width = 32, Height = 32, CornerRadius = new CornerRadius(16),
            Background = new SolidColorBrush(ColorHelper.FromArgb(30, 245, 158, 11)),
            Child = new FontIcon { Glyph = bundle.IconGlyph, FontSize = 14, Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeAccentGoldBrush"] }
        });
        headerStack.Children.Add(new TextBlock { Text = bundle.Title, FontSize = 14, FontWeight = Microsoft.UI.Text.FontWeights.SemiBold, Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"], VerticalAlignment = VerticalAlignment.Center });
        headerBorder.Child = headerStack;
        stack.Children.Add(headerBorder);

        // Body
        var body = new StackPanel { Spacing = 14, Padding = new Thickness(16) };
        var priceRow = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 4 };
        priceRow.Children.Add(new TextBlock { Text = bundle.Price, FontSize = 22, FontWeight = Microsoft.UI.Text.FontWeights.Bold, FontFamily = new FontFamily("Consolas"), Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"] });
        priceRow.Children.Add(new TextBlock { Text = bundle.Period, FontSize = 12, Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"], VerticalAlignment = VerticalAlignment.Bottom, Margin = new Thickness(0, 0, 0, 3) });
        body.Children.Add(priceRow);

        body.Children.Add(new TextBlock { Text = bundle.Description, FontSize = 11.5, Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"], TextWrapping = TextWrapping.Wrap });

        var featStack = new StackPanel { Spacing = 6 };
        foreach (var feat in bundle.Features)
        {
            var row = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8 };
            row.Children.Add(new FontIcon { Glyph = "\uE73E", FontSize = 11, Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeAccentSuccessBrush"] });
            row.Children.Add(new TextBlock { Text = feat, FontSize = 11.5, Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"] });
            featStack.Children.Add(row);
        }
        body.Children.Add(featStack);

        var subBtn = new Button
        {
            Content = new TextBlock { Text = _loc.GetString("store_subscribe"), FontSize = 12.5, FontWeight = Microsoft.UI.Text.FontWeights.SemiBold, Foreground = new SolidColorBrush(Colors.Black) },
            Background = (SolidColorBrush)Application.Current.Resources["OvernodeAccentGoldBrush"],
            CornerRadius = new CornerRadius(6),
            BorderThickness = new Thickness(0),
            HorizontalAlignment = HorizontalAlignment.Stretch,
            Padding = new Thickness(0, 8, 0, 8),
            Margin = new Thickness(0, 8, 0, 0)
        };
        subBtn.Click += (_, _) => ViewModel.SubscribeBundle(bundle);
        body.Children.Add(subBtn);

        stack.Children.Add(body);
        border.Child = stack;
        return border;
    }

    private void OnTabResourcesClicked(object sender, RoutedEventArgs e) => ViewModel.SelectedTab = StoreTab.Resources;
    private void OnTabBundlesClicked(object sender, RoutedEventArgs e) => ViewModel.SelectedTab = StoreTab.Bundles;

    private async void OnBuyRamClicked(object sender, RoutedEventArgs e) => await HandleBuyAsync("ram", 1024);
    private async void OnBuyDiskClicked(object sender, RoutedEventArgs e) => await HandleBuyAsync("disk", 5120);
    private async void OnBuyCpuClicked(object sender, RoutedEventArgs e) => await HandleBuyAsync("cpu", 100);
    private async void OnBuyServersClicked(object sender, RoutedEventArgs e) => await HandleBuyAsync("servers", 1);

    private async Task HandleBuyAsync(string type, int amount)
    {
        if (await ViewModel.BuyResourceAsync(type, amount))
        {
            ResourcePurchased?.Invoke(ViewModel.UserCoins);
        }
    }
}
