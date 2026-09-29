using System.ComponentModel;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Overnode.App.Localization;
using Overnode.App.ViewModels;

namespace Overnode.App.Views;

public sealed partial class TwoFactorVerificationView : UserControl
{
    public TwoFactorViewModel? ViewModel { get; private set; }

    public TwoFactorVerificationView()
    {
        InitializeComponent();
        Loaded += OnLoaded;
        Unloaded += OnUnloaded;
    }

    public void Initialize(TwoFactorViewModel viewModel)
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
        CodeInput.Focus(FocusState.Programmatic);
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
        TitleText.Text = loc["2fa_title"];
        SubtitleText.Text = loc["2fa_subtitle"];
        VerifyButtonText.Text = loc["2fa_verify_button"];
        CancelButtonText.Text = loc["2fa_cancel_button"];
    }

    private void UpdateState()
    {
        if (ViewModel == null) return;

        bool loading = ViewModel.IsLoading;
        VerifyButton.IsEnabled = ViewModel.CanVerify && !loading;
        CancelButton.IsEnabled = !loading;
        CodeInput.IsEnabled = !loading;

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
    }

    private void CodeInput_TextChanged(object sender, TextChangedEventArgs e)
    {
        if (ViewModel != null)
        {
            ViewModel.Code = CodeInput.Text;
            UpdateState();
        }
    }

    private async void CodeInput_KeyDown(object sender, KeyRoutedEventArgs e)
    {
        if (e.Key == Windows.System.VirtualKey.Enter && ViewModel?.CanVerify == true)
        {
            e.Handled = true;
            await ViewModel.VerifyCommand.ExecuteAsync(null);
        }
    }

    private async void VerifyButton_Click(object sender, RoutedEventArgs e)
    {
        if (ViewModel != null)
        {
            await ViewModel.VerifyCommand.ExecuteAsync(null);
        }
    }

    private void CancelButton_Click(object sender, RoutedEventArgs e)
    {
        ViewModel?.CancelCommand.Execute(null);
    }
}
