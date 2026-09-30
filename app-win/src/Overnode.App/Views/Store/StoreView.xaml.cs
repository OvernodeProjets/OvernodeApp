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
        BundlesPanel.Children.Clear();
        for (int i = 0; i < ViewModel.Bundles.Count; i++)
        {
            var bundle = ViewModel.Bundles[i];
            var card = CreateBundleCard(bundle);
            Grid.SetColumn(card, i % 3);
            BundlesPanel.Children.Add(card);
        }
    }

    private FrameworkElement CreateBundleCard(StoreBundle bundle)
    {
        var border = new Border
        {
            Background = (SolidColorBrush)Application.Current.Resources["OvernodeCardBrush"],
            BorderBrush = (SolidColorBrush)Application.Current.Resources["OvernodeBorderSubtleBrush"],
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(10),
            VerticalAlignment = VerticalAlignment.Stretch
        };

        Windows.UI.Color accentColor = ColorHelper.FromArgb(255, 229, 184, 66);
        if (!string.IsNullOrWhiteSpace(bundle.ColorHex) && bundle.ColorHex.StartsWith("#") && bundle.ColorHex.Length == 7)
        {
            try
            {
                byte r = Convert.ToByte(bundle.ColorHex.Substring(1, 2), 16);
                byte g = Convert.ToByte(bundle.ColorHex.Substring(3, 2), 16);
                byte b = Convert.ToByte(bundle.ColorHex.Substring(5, 2), 16);
                accentColor = ColorHelper.FromArgb(255, r, g, b);
            }
            catch { }
        }

        var accentBrush = new SolidColorBrush(accentColor);
        var accentBgBrush = new SolidColorBrush(ColorHelper.FromArgb(30, accentColor.R, accentColor.G, accentColor.B));

        var mainGrid = new Grid();
        mainGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        mainGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        mainGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

        // Header
        var headerBorder = new Border
        {
            BorderBrush = (SolidColorBrush)Application.Current.Resources["OvernodeBorderSubtleBrush"],
            BorderThickness = new Thickness(0, 0, 0, 1),
            Padding = new Thickness(16, 14, 16, 14)
        };
        var headerStack = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 10 };
        headerStack.Children.Add(new Border
        {
            Width = 34,
            Height = 34,
            CornerRadius = new CornerRadius(17),
            Background = accentBgBrush,
            Child = new FontIcon { Glyph = bundle.IconGlyph, FontSize = 15, Foreground = accentBrush }
        });
        headerStack.Children.Add(new TextBlock
        {
            Text = bundle.Title,
            FontSize = 14,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"],
            VerticalAlignment = VerticalAlignment.Center
        });
        headerBorder.Child = headerStack;
        Grid.SetRow(headerBorder, 0);
        mainGrid.Children.Add(headerBorder);

        // Body Content
        var bodyStack = new StackPanel { Spacing = 12, Padding = new Thickness(16, 16, 16, 12) };

        var priceRow = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 4 };
        priceRow.Children.Add(new TextBlock
        {
            Text = bundle.Price,
            FontSize = 22,
            FontWeight = Microsoft.UI.Text.FontWeights.Bold,
            FontFamily = new FontFamily("Consolas"),
            Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"]
        });
        priceRow.Children.Add(new TextBlock
        {
            Text = bundle.Period,
            FontSize = 12,
            Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"],
            VerticalAlignment = VerticalAlignment.Bottom,
            Margin = new Thickness(0, 0, 0, 3)
        });
        bodyStack.Children.Add(priceRow);

        bodyStack.Children.Add(new TextBlock
        {
            Text = bundle.Description,
            FontSize = 11.5,
            Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"],
            TextWrapping = TextWrapping.Wrap,
            MinHeight = 34
        });

        var featStack = new StackPanel { Spacing = 6, Margin = new Thickness(0, 4, 0, 0) };
        foreach (var feat in bundle.Features)
        {
            var row = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8 };
            row.Children.Add(new FontIcon { Glyph = "\uE73E", FontSize = 11, Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeAccentSuccessBrush"] });
            row.Children.Add(new TextBlock { Text = feat, FontSize = 11.5, Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"] });
            featStack.Children.Add(row);
        }
        bodyStack.Children.Add(featStack);

        Grid.SetRow(bodyStack, 1);
        mainGrid.Children.Add(bodyStack);

        // Footer Button
        var footerBorder = new Border { Padding = new Thickness(16, 0, 16, 16) };
        var subBtn = new Button
        {
            Content = new TextBlock
            {
                Text = _loc.GetString("store_subscribe"),
                FontSize = 12.5,
                FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
                Foreground = new SolidColorBrush(Colors.Black)
            },
            Background = (SolidColorBrush)Application.Current.Resources["OvernodeAccentGoldBrush"],
            CornerRadius = new CornerRadius(6),
            BorderThickness = new Thickness(0),
            HorizontalAlignment = HorizontalAlignment.Stretch,
            Padding = new Thickness(0, 8, 0, 8)
        };
        subBtn.Click += (_, _) => ViewModel.SubscribeBundle(bundle);
        footerBorder.Child = subBtn;
        Grid.SetRow(footerBorder, 2);
        mainGrid.Children.Add(footerBorder);

        border.Child = mainGrid;
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
