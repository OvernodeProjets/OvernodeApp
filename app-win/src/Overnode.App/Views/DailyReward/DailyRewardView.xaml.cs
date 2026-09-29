using System;
using System.Globalization;
using System.Threading.Tasks;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Overnode.App.Localization;
using Overnode.App.ViewModels;

namespace Overnode.App.Views.DailyReward;

public sealed partial class DailyRewardView : UserControl
{
    private readonly LocalizationManager _loc = LocalizationManager.Instance;
    public DailyRewardViewModel ViewModel { get; } = new();
    public event EventHandler? RewardClaimed;

    public DailyRewardView()
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
        TitleText.Text = _loc.GetString("daily_title");
        SubtitleText.Text = _loc.GetString("daily_subtitle");
        TabClaimText.Text = _loc.GetString("daily_tab_claim");
        TabHistoryText.Text = _loc.GetString("daily_tab_history");
        TabLeaderboardText.Text = _loc.GetString("daily_tab_leaderboard");
        HeroTitle.Text = _loc.GetString("daily_banner_available_title");
        StatCurrentStreakTitle.Text = _loc.GetString("daily_stat_current_streak");
        StatLongestStreakTitle.Text = _loc.GetString("daily_stat_longest_streak");
        StatTotalEarnedTitle.Text = _loc.GetString("daily_stat_coins_earned");
    }

    private void UpdateUI()
    {
        LoadingSpinner.Visibility = ViewModel.IsLoading ? Visibility.Visible : Visibility.Collapsed;

        bool isClaim = ViewModel.SelectedTab == DailyRewardTab.Claim;
        bool isHistory = ViewModel.SelectedTab == DailyRewardTab.History;
        bool isLeaderboard = ViewModel.SelectedTab == DailyRewardTab.Leaderboard;

        ClaimPanel.Visibility = isClaim ? Visibility.Visible : Visibility.Collapsed;
        HistoryPanel.Visibility = isHistory ? Visibility.Visible : Visibility.Collapsed;
        LeaderboardPanel.Visibility = isLeaderboard ? Visibility.Visible : Visibility.Collapsed;

        TabClaimText.FontWeight = isClaim ? Microsoft.UI.Text.FontWeights.SemiBold : Microsoft.UI.Text.FontWeights.Normal;
        TabClaimText.Foreground = isClaim ? (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"] : (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"];

        TabHistoryText.FontWeight = isHistory ? Microsoft.UI.Text.FontWeights.SemiBold : Microsoft.UI.Text.FontWeights.Normal;
        TabHistoryText.Foreground = isHistory ? (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"] : (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"];

        TabLeaderboardText.FontWeight = isLeaderboard ? Microsoft.UI.Text.FontWeights.SemiBold : Microsoft.UI.Text.FontWeights.Normal;
        TabLeaderboardText.Foreground = isLeaderboard ? (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"] : (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"];

        UpdateClaimSection();
        UpdateStatsSection();
        UpdateHistoryTable();
        UpdateLeaderboardTable();
    }

    private void UpdateClaimSection()
    {
        var st = ViewModel.Status;
        if (st == null) return;

        HeroStreakText.Text = $"Série en cours : {st.CurrentStreak} jours consécutifs";
        int amount = st.NextReward?.Amount ?? 25;
        HeroRewardAmount.Text = $"+{amount}";

        if (!string.IsNullOrEmpty(st.NextReward?.MilestoneMessage))
        {
            MilestoneBadge.Visibility = Visibility.Visible;
            MilestoneText.Text = st.NextReward.MilestoneMessage;
        }
        else
        {
            MilestoneBadge.Visibility = Visibility.Collapsed;
        }

        ClaimButton.IsEnabled = st.CanClaim && !ViewModel.IsClaiming;
        ClaimButtonText.Text = st.CanClaim ? "Réclamer maintenant" : "Déjà réclamé aujourd'hui";
        ClaimSpinner.Visibility = ViewModel.IsClaiming ? Visibility.Visible : Visibility.Collapsed;
        ClaimIcon.Visibility = ViewModel.IsClaiming ? Visibility.Collapsed : Visibility.Visible;

        if (!string.IsNullOrEmpty(ViewModel.SuccessMessage))
        {
            SuccessBanner.Visibility = Visibility.Visible;
            SuccessBannerText.Text = ViewModel.SuccessMessage;
        }
        else
        {
            SuccessBanner.Visibility = Visibility.Collapsed;
        }
    }

    private void UpdateStatsSection()
    {
        var st = ViewModel.Status;
        if (st == null) return;

        StatCurrentStreakValue.Text = $"{st.CurrentStreak} jours";
        StatLongestStreakValue.Text = $"{st.LongestStreak} jours";
        StatTotalEarnedValue.Text = $"{st.TotalCoinsEarned:N0} coins";
    }

    private void UpdateHistoryTable()
    {
        HistoryRows.Children.Clear();
        foreach (var item in ViewModel.History)
        {
            var border = new Border
            {
                BorderBrush = (SolidColorBrush)Application.Current.Resources["OvernodeBorderSubtleBrush"],
                BorderThickness = new Thickness(0, 0, 0, 1),
                Padding = new Thickness(16, 10, 16, 10)
            };

            var grid = new Grid();
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(140) });
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(120) });

            var date = DateTimeOffset.FromUnixTimeMilliseconds(item.Timestamp).LocalDateTime;
            var dateText = new TextBlock { Text = date.ToString("dd/MM/yyyy HH:mm"), FontSize = 12, FontFamily = new FontFamily("Consolas"), Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"] };
            Grid.SetColumn(dateText, 0);
            grid.Children.Add(dateText);

            var streakText = new TextBlock { Text = $"Série de {item.Streak} jours", FontSize = 12, FontWeight = Microsoft.UI.Text.FontWeights.Medium, Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"] };
            Grid.SetColumn(streakText, 1);
            grid.Children.Add(streakText);

            var rewardText = new TextBlock { Text = $"+{item.Reward} coins", FontSize = 12.5, FontWeight = Microsoft.UI.Text.FontWeights.Bold, FontFamily = new FontFamily("Consolas"), Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeAccentGoldBrush"], HorizontalAlignment = HorizontalAlignment.Right };
            Grid.SetColumn(rewardText, 2);
            grid.Children.Add(rewardText);

            border.Child = grid;
            HistoryRows.Children.Add(border);
        }
    }

    private void UpdateLeaderboardTable()
    {
        LeaderboardRows.Children.Clear();
        int rank = 1;
        foreach (var entry in ViewModel.Leaderboard)
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

            var rankBrush = rank switch
            {
                1 => (SolidColorBrush)Application.Current.Resources["OvernodeAccentGoldBrush"],
                2 => new SolidColorBrush(ColorHelper.FromArgb(255, 203, 213, 225)),
                3 => new SolidColorBrush(ColorHelper.FromArgb(255, 217, 119, 6)),
                _ => (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"]
            };

            var rankText = new TextBlock { Text = $"#{rank}", FontSize = 12.5, FontWeight = Microsoft.UI.Text.FontWeights.Bold, FontFamily = new FontFamily("Consolas"), Foreground = rankBrush };
            Grid.SetColumn(rankText, 0);
            grid.Children.Add(rankText);

            var userText = new TextBlock { Text = entry.Username, FontSize = 12.5, FontWeight = Microsoft.UI.Text.FontWeights.Medium, Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"] };
            Grid.SetColumn(userText, 1);
            grid.Children.Add(userText);

            var streakText = new TextBlock { Text = $"{entry.CurrentStreak} jours (max: {entry.LongestStreak})", FontSize = 12, FontFamily = new FontFamily("Consolas"), Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"], HorizontalAlignment = HorizontalAlignment.Right };
            Grid.SetColumn(streakText, 2);
            grid.Children.Add(streakText);

            border.Child = grid;
            LeaderboardRows.Children.Add(border);
            rank++;
        }
    }

    private void OnTabClaimClicked(object sender, RoutedEventArgs e) => ViewModel.SelectedTab = DailyRewardTab.Claim;
    private void OnTabHistoryClicked(object sender, RoutedEventArgs e) => ViewModel.SelectedTab = DailyRewardTab.History;
    private void OnTabLeaderboardClicked(object sender, RoutedEventArgs e) => ViewModel.SelectedTab = DailyRewardTab.Leaderboard;
    private async void OnRefreshClicked(object sender, RoutedEventArgs e) => await ViewModel.LoadDataAsync();

    private async void OnClaimClicked(object sender, RoutedEventArgs e)
    {
        await ViewModel.ClaimRewardAsync();
        RewardClaimed?.Invoke(this, EventArgs.Empty);
    }
}
