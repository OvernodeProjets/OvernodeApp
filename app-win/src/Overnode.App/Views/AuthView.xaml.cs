using System;
using System.ComponentModel;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Overnode.App.Localization;
using Overnode.App.ViewModels;

namespace Overnode.App.Views;

public sealed partial class AuthView : UserControl
{
    public AuthViewModel? ViewModel { get; private set; }

    public AuthView()
    {
        InitializeComponent();
        Loaded += OnLoaded;
        Unloaded += OnUnloaded;
    }

    public void Initialize(AuthViewModel viewModel)
    {
        if (ViewModel != null)
        {
            ViewModel.PropertyChanged -= OnViewModelPropertyChanged;
        }

        ViewModel = viewModel;
        ViewModel.PropertyChanged += OnViewModelPropertyChanged;
        UpdateLocalization();
        UpdateState();
    }

    private void OnLoaded(object sender, RoutedEventArgs e)
    {
        LocalizationManager.Instance.PropertyChanged += OnLocalizationChanged;
        UpdateLocalization();
        UpdateState();
    }

    private void OnUnloaded(object sender, RoutedEventArgs e)
    {
        LocalizationManager.Instance.PropertyChanged -= OnLocalizationChanged;
        if (ViewModel != null)
        {
            ViewModel.PropertyChanged -= OnViewModelPropertyChanged;
        }
    }

    private void OnLocalizationChanged(object? sender, PropertyChangedEventArgs e)
    {
        DispatcherQueue.TryEnqueue(UpdateLocalization);
    }

    private void OnViewModelPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        DispatcherQueue.TryEnqueue(UpdateState);
    }

    private void UpdateLocalization()
    {
        var loc = LocalizationManager.Instance;
        TitleText.Text = loc["auth_title"];
        SubtitleText.Text = loc["auth_subtitle"];
        DiscordButtonText.Text = ViewModel?.IsLoading == true ? loc["auth_logging_in"] : loc["auth_login_discord"];
        PasskeyButtonText.Text = loc["auth_login_passkey"];
        PasskeyNoticeText.Text = loc["auth_passkey_notice"];

        bool isFr = loc.CurrentLanguage == AppLanguage.Fr;
        FrButton.Background = isFr ? new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(0x33, 0xFF, 0xFF, 0xFF)) : new SolidColorBrush(Microsoft.UI.Colors.Transparent);
        EnButton.Background = !isFr ? new SolidColorBrush(Microsoft.UI.ColorHelper.FromArgb(0x33, 0xFF, 0xFF, 0xFF)) : new SolidColorBrush(Microsoft.UI.Colors.Transparent);
    }

    private void UpdateState()
    {
        if (ViewModel == null) return;

        bool loading = ViewModel.IsLoading;
        DiscordButton.IsEnabled = !loading;
        PasskeyButton.IsEnabled = !loading;
        LoadingRing.IsActive = loading;
        LoadingRing.Visibility = loading ? Visibility.Visible : Visibility.Collapsed;

        if (!string.IsNullOrEmpty(ViewModel.ErrorMessage))
        {
            ErrorText.Text = ViewModel.ErrorMessage;
            ErrorBorder.Visibility = Visibility.Visible;
        }
        else
        {
            ErrorBorder.Visibility = Visibility.Collapsed;
        }

        var loc = LocalizationManager.Instance;
        DiscordButtonText.Text = loading ? loc["auth_logging_in"] : loc["auth_login_discord"];
    }

    private async void DiscordButton_Click(object sender, RoutedEventArgs e)
    {
        if (ViewModel != null)
        {
            await ViewModel.LoginWithDiscordAsync();
        }
    }

    private void PasskeyButton_Click(object sender, RoutedEventArgs e)
    {
        ViewModel?.LoginWithPasskey();
    }

    private void FrButton_Click(object sender, RoutedEventArgs e)
    {
        LocalizationManager.Instance.SetLanguage(AppLanguage.Fr);
    }

    private void EnButton_Click(object sender, RoutedEventArgs e)
    {
        LocalizationManager.Instance.SetLanguage(AppLanguage.En);
    }
}
