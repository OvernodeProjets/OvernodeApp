using System;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Overnode.App.Localization;
using Overnode.App.ViewModels;

namespace Overnode.App.Views.Server;

public sealed partial class ServerRenewalTabControl : UserControl
{
    public ServerDetailViewModel? ViewModel => DataContext as ServerDetailViewModel;
    private ServerDetailViewModel? _boundViewModel;

    public ServerRenewalTabControl()
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
            if (_boundViewModel.RenewalStatus == null && !_boundViewModel.IsLoading)
            {
                _ = _boundViewModel.LoadRenewalAsync();
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
            if (ViewModel.RenewalStatus == null && !ViewModel.IsLoading)
            {
                await ViewModel.LoadRenewalAsync();
            }
            UpdateUI();
        }
    }

    private void UpdateLocalization()
    {
        var loc = LocalizationManager.Instance;
        RenewalTitleText.Text = loc.GetString("renewal_title");
        RenewalSubtitleText.Text = loc.GetString("renewal_subtitle");
        StatNextDateTitle.Text = loc.GetString("renewal_next_date");
        StatRemainingTimeTitle.Text = loc.GetString("renewal_remaining_time");
        StatCountTitle.Text = loc.GetString("renewal_count");
        ActionTitleText.Text = loc.GetString("renewal_action_title");
        ActionDescText.Text = loc.GetString("renewal_action_desc");
        RenewButtonText.Text = loc.GetString("renewal_button_now");
        OwnerOnlyText.Text = loc.GetString("server_renewal_owner_only");
    }

    public void UpdateUI()
    {
        if (ViewModel == null) return;
        var loc = LocalizationManager.Instance;

        bool isOwner = ViewModel.Server.IsOwner;
        OwnerOnlyBanner.Visibility = !isOwner ? Visibility.Visible : Visibility.Collapsed;

        var status = ViewModel.RenewalStatus;
        if (status != null)
        {
            StatNextDateValue.Text = FormatDate(status.NextRenewalAt) ?? loc.GetString("renewal_not_configured");
            StatRemainingTimeValue.Text = status.CalculatedTimeRemaining;
            StatCountValue.Text = (status.RenewalCount ?? 0).ToString();

            if (status.IsExpired == true)
            {
                StatRemainingTimeValue.Foreground = new Microsoft.UI.Xaml.Media.SolidColorBrush(Windows.UI.Color.FromArgb(255, 239, 68, 68));
            }
            else
            {
                StatRemainingTimeValue.Foreground = (Microsoft.UI.Xaml.Media.Brush)Application.Current.Resources["OvernodeTextPrimaryBrush"];
            }

            bool canRenew = (status.CanRenew ?? false) && ViewModel.Server.CanRenew && isOwner;
            RenewNowButton.IsEnabled = canRenew && !ViewModel.IsRenewing;

            // Available in Banner
            string? avail = status.CalculatedAvailableIn ?? status.AvailableIn;
            if (!canRenew && !string.IsNullOrEmpty(avail) && string.IsNullOrEmpty(ViewModel.ErrorMessage))
            {
                AvailableInBannerText.Text = $"{loc.GetString("renewal_not_available_yet")} {loc.GetString("renewal_available_in")} {avail}";
                AvailableInBanner.Visibility = Visibility.Visible;
            }
            else
            {
                AvailableInBanner.Visibility = Visibility.Collapsed;
            }
        }
        else
        {
            StatNextDateValue.Text = "—";
            StatRemainingTimeValue.Text = "—";
            StatCountValue.Text = "0";
            RenewNowButton.IsEnabled = isOwner && !ViewModel.IsRenewing;
            AvailableInBanner.Visibility = Visibility.Collapsed;
        }

        RenewProgressRing.IsActive = ViewModel.IsRenewing;
        RenewProgressRing.Visibility = ViewModel.IsRenewing ? Visibility.Visible : Visibility.Collapsed;
        RenewBoltIcon.Visibility = ViewModel.IsRenewing ? Visibility.Collapsed : Visibility.Visible;

        if (!string.IsNullOrEmpty(ViewModel.RenewalSuccessMessage))
        {
            SuccessBannerText.Text = ViewModel.RenewalSuccessMessage;
            SuccessBanner.Visibility = Visibility.Visible;
        }
        else
        {
            SuccessBanner.Visibility = Visibility.Collapsed;
        }

        if (!string.IsNullOrEmpty(ViewModel.ErrorMessage))
        {
            ErrorBannerText.Text = ViewModel.ErrorMessage;
            ErrorBanner.Visibility = Visibility.Visible;
            AvailableInBanner.Visibility = Visibility.Collapsed;
        }
        else
        {
            ErrorBanner.Visibility = Visibility.Collapsed;
        }
    }

    private string? FormatDate(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw)) return null;
        if (DateTime.TryParse(raw, null, System.Globalization.DateTimeStyles.AdjustToUniversal, out var dt))
        {
            return dt.ToLocalTime().ToString("dd MMM yyyy, HH:mm");
        }
        return raw;
    }

    private async void OnRefreshRenewalClicked(object sender, RoutedEventArgs e)
    {
        if (ViewModel != null)
        {
            await ViewModel.LoadRenewalAsync(force: true);
            UpdateUI();
        }
    }

    private async void OnRenewNowClicked(object sender, RoutedEventArgs e)
    {
        if (ViewModel != null)
        {
            await ViewModel.RenewServerAsync();
            UpdateUI();
        }
    }
}
