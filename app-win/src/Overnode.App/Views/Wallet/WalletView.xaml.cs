using System;
using System.Globalization;
using System.Threading.Tasks;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.ViewModels;

namespace Overnode.App.Views.Wallet;

public sealed partial class WalletView : UserControl
{
    private readonly LocalizationManager _loc = LocalizationManager.Instance;
    public WalletViewModel ViewModel { get; } = new();

    public WalletView()
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
        WalletTitleText.Text = _loc.GetString("wallet_title");
        WalletSubtitleText.Text = _loc.GetString("wallet_subtitle");
        TabOverviewText.Text = _loc.GetString("wallet_tab_overview");
        TabLeaderboardText.Text = _loc.GetString("wallet_tab_leaderboard");
        TabActivityText.Text = _loc.GetString("wallet_tab_activity");
        CoinBalanceTitle.Text = _loc.GetString("wallet_coin_balance_title");
        CoinBalanceSuffix.Text = _loc.GetString("wallet_coins_suffix");
        CoinBalanceDesc.Text = _loc.GetString("wallet_coin_balance_desc");
        CreditBalanceTitle.Text = _loc.GetString("wallet_credit_balance_title");
        AddFundsBtnText.Text = _loc.GetString("wallet_add_funds");
        StripeSecureText.Text = _loc.GetString("wallet_stripe_secure");
        PurchaseCoinsTitle.Text = _loc.GetString("wallet_purchase_coins_title");
        RankHeader.Text = _loc.GetString("wallet_rank");
        UserHeader.Text = _loc.GetString("wallet_user");
        CoinsHeader.Text = _loc.GetString("wallet_coins_suffix");
        ActivityTypeHeader.Text = _loc.GetString("wallet_activity_type");
        ActivityIdHeader.Text = _loc.GetString("wallet_activity_id");
        ActivityAmountHeader.Text = _loc.GetString("wallet_activity_amount");
        UserRankLabel.Text = _loc.GetString("wallet_user_rank");
    }

    private void UpdateUI()
    {
        LoadingSpinner.Visibility = ViewModel.IsLoading ? Visibility.Visible : Visibility.Collapsed;

        // Subtabs selection styling
        bool isOverview = ViewModel.SelectedTab == WalletTab.Overview;
        bool isLeaderboard = ViewModel.SelectedTab == WalletTab.Leaderboard;
        bool isActivity = ViewModel.SelectedTab == WalletTab.Activity;

        OverviewPanel.Visibility = isOverview ? Visibility.Visible : Visibility.Collapsed;
        LeaderboardPanel.Visibility = isLeaderboard ? Visibility.Visible : Visibility.Collapsed;
        ActivityPanel.Visibility = isActivity ? Visibility.Visible : Visibility.Collapsed;

        TabOverviewText.FontWeight = isOverview ? Microsoft.UI.Text.FontWeights.SemiBold : Microsoft.UI.Text.FontWeights.Normal;
        TabOverviewText.Foreground = isOverview ? (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"] : (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"];

        TabLeaderboardText.FontWeight = isLeaderboard ? Microsoft.UI.Text.FontWeights.SemiBold : Microsoft.UI.Text.FontWeights.Normal;
        TabLeaderboardText.Foreground = isLeaderboard ? (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"] : (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"];

        TabActivityText.FontWeight = isActivity ? Microsoft.UI.Text.FontWeights.SemiBold : Microsoft.UI.Text.FontWeights.Normal;
        TabActivityText.Foreground = isActivity ? (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"] : (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"];

        UpdateBalances();
        UpdatePackages();
        UpdateLeaderboard();
        UpdateActivity();
    }

    private void UpdateBalances()
    {
        var balances = ViewModel.BillingInfo?.Balances;
        int coins = balances?.Coins ?? 0;
        double credit = balances?.CreditEur ?? 0.0;

        CoinBalanceAmount.Text = coins.ToString("N0", CultureInfo.InvariantCulture);
        CreditBalanceAmount.Text = $"{credit:F2} €";
    }

    private void UpdatePackages()
    {
        PackagesList.Children.Clear();
        var packages = ViewModel.BillingInfo?.CoinPackages;
        if (packages == null || packages.Count == 0) return;

        foreach (var pkg in packages)
        {
            var btn = new Button
            {
                Padding = new Thickness(12, 8, 12, 8),
                CornerRadius = new CornerRadius(8),
                Background = new SolidColorBrush(ColorHelper.FromArgb(10, 255, 255, 255)),
                BorderBrush = (SolidColorBrush)Application.Current.Resources["OvernodeBorderSubtleBrush"],
                BorderThickness = new Thickness(1),
                HorizontalAlignment = HorizontalAlignment.Stretch,
                HorizontalContentAlignment = HorizontalAlignment.Stretch
            };

            var grid = new Grid();
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

            var coinText = new TextBlock
            {
                Text = $"{pkg.Amount:N0} {_loc.GetString("wallet_coins_suffix")}",
                FontSize = 12.5,
                FontWeight = Microsoft.UI.Text.FontWeights.Medium,
                Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"],
                VerticalAlignment = VerticalAlignment.Center
            };
            Grid.SetColumn(coinText, 0);
            grid.Children.Add(coinText);

            var priceBadge = new Border
            {
                Background = (SolidColorBrush)Application.Current.Resources["OvernodeSecondaryCardBrush"],
                BorderBrush = new SolidColorBrush(ColorHelper.FromArgb(25, 255, 255, 255)),
                BorderThickness = new Thickness(1),
                CornerRadius = new CornerRadius(6),
                Padding = new Thickness(8, 3, 8, 3),
                Child = new TextBlock
                {
                    Text = $"{pkg.PriceEur:F2} €",
                    FontSize = 11.5,
                    FontFamily = new FontFamily("Consolas"),
                    FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
                    Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"]
                }
            };
            Grid.SetColumn(priceBadge, 1);
            grid.Children.Add(priceBadge);

            btn.Content = grid;
            btn.Click += (_, _) => ViewModel.PurchaseCoinsPackage(pkg.Amount);
            PackagesList.Children.Add(btn);
        }
    }

    private void UpdateLeaderboard()
    {
        LeaderboardRows.Children.Clear();
        var lboard = ViewModel.Leaderboard;
        if (lboard == null) return;

        if (lboard.UserRank != null)
        {
            UserRankValue.Text = $"#{lboard.UserRank.Rank}";
            UserRankUsername.Text = lboard.UserRank.Username;
            UserRankCoins.Text = $"{lboard.UserRank.Coins:N0} {_loc.GetString("wallet_coins_suffix")}";
        }

        foreach (var entry in lboard.Leaderboard)
        {
            var border = new Border
            {
                BorderBrush = (SolidColorBrush)Application.Current.Resources["OvernodeBorderSubtleBrush"],
                BorderThickness = new Thickness(0, 0, 0, 1),
                Padding = new Thickness(16, 10, 16, 10)
            };

            var grid = new Grid();
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(80) });
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(120) });

            var rankBrush = entry.Rank switch
            {
                1 => (SolidColorBrush)Application.Current.Resources["OvernodeAccentGoldBrush"],
                2 => new SolidColorBrush(ColorHelper.FromArgb(255, 203, 213, 225)), // Silver
                3 => new SolidColorBrush(ColorHelper.FromArgb(255, 217, 119, 6)),   // Bronze
                _ => (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"]
            };

            var rankText = new TextBlock { Text = $"#{entry.Rank}", FontSize = 12.5, FontWeight = Microsoft.UI.Text.FontWeights.Bold, FontFamily = new FontFamily("Consolas"), Foreground = rankBrush };
            Grid.SetColumn(rankText, 0);
            grid.Children.Add(rankText);

            var userText = new TextBlock { Text = entry.Username, FontSize = 12.5, FontWeight = Microsoft.UI.Text.FontWeights.Medium, Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"] };
            Grid.SetColumn(userText, 1);
            grid.Children.Add(userText);

            var coinsText = new TextBlock { Text = entry.Coins.ToString("N0", CultureInfo.InvariantCulture), FontSize = 12.5, FontWeight = Microsoft.UI.Text.FontWeights.SemiBold, FontFamily = new FontFamily("Consolas"), Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"], HorizontalAlignment = HorizontalAlignment.Right };
            Grid.SetColumn(coinsText, 2);
            grid.Children.Add(coinsText);

            border.Child = grid;
            LeaderboardRows.Children.Add(border);
        }
    }

    private void UpdateActivity()
    {
        ActivityRows.Children.Clear();
        foreach (var tx in ViewModel.Transactions)
        {
            var border = new Border
            {
                BorderBrush = (SolidColorBrush)Application.Current.Resources["OvernodeBorderSubtleBrush"],
                BorderThickness = new Thickness(0, 0, 0, 1),
                Padding = new Thickness(16, 10, 16, 10)
            };

            var grid = new Grid();
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(150) });
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(120) });

            var typeBadge = new Border
            {
                Background = (SolidColorBrush)Application.Current.Resources["OvernodeSecondaryCardBrush"],
                CornerRadius = new CornerRadius(4),
                Padding = new Thickness(8, 3, 8, 3),
                HorizontalAlignment = HorizontalAlignment.Left,
                Child = new TextBlock { Text = tx.Type.Replace('_', ' ').ToUpperInvariant(), FontSize = 10, FontWeight = Microsoft.UI.Text.FontWeights.SemiBold, Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"] }
            };
            Grid.SetColumn(typeBadge, 0);
            grid.Children.Add(typeBadge);

            var idText = new TextBlock { Text = tx.Id, FontSize = 12, FontFamily = new FontFamily("Consolas"), Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"], VerticalAlignment = VerticalAlignment.Center };
            Grid.SetColumn(idText, 1);
            grid.Children.Add(idText);

            bool isPositive = tx.Amount >= 0;
            var amountText = new TextBlock
            {
                Text = $"{(isPositive ? "+" : "")}{tx.Amount:F0} {_loc.GetString("wallet_coins_suffix")}",
                FontSize = 12.5,
                FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
                FontFamily = new FontFamily("Consolas"),
                Foreground = isPositive ? (SolidColorBrush)Application.Current.Resources["OvernodeAccentSuccessBrush"] : (SolidColorBrush)Application.Current.Resources["OvernodeAccentDangerBrush"],
                HorizontalAlignment = HorizontalAlignment.Right,
                VerticalAlignment = VerticalAlignment.Center
            };
            Grid.SetColumn(amountText, 2);
            grid.Children.Add(amountText);

            border.Child = grid;
            ActivityRows.Children.Add(border);
        }
    }

    private void OnTabOverviewClicked(object sender, RoutedEventArgs e) => ViewModel.SelectedTab = WalletTab.Overview;
    private void OnTabLeaderboardClicked(object sender, RoutedEventArgs e) => ViewModel.SelectedTab = WalletTab.Leaderboard;
    private void OnTabActivityClicked(object sender, RoutedEventArgs e) => ViewModel.SelectedTab = WalletTab.Activity;
    private async void OnRefreshClicked(object sender, RoutedEventArgs e) => await ViewModel.LoadDataAsync();
    private void OnAddFundsClicked(object sender, RoutedEventArgs e) => ViewModel.OpenAddFunds();
}
