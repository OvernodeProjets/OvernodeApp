using System;
using System.ComponentModel;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.ViewModels;

namespace Overnode.App.Views.Components;

public sealed partial class UpdateModalControl : UserControl
{
    private UpdateViewModel? _vm;
    private readonly LocalizationManager _loc = LocalizationManager.Instance;

    public UpdateModalControl()
    {
        InitializeComponent();
        _loc.LanguageChanged += (_, _) => UpdateLocalizedStrings();
    }

    public void Initialize(UpdateViewModel vm)
    {
        if (_vm != null)
        {
            _vm.PropertyChanged -= OnViewModelPropertyChanged;
        }

        _vm = vm;
        _vm.PropertyChanged += OnViewModelPropertyChanged;

        UpdateLocalizedStrings();
        UpdateVisualState();
    }

    private void OnViewModelPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        DispatcherQueue.TryEnqueue(UpdateVisualState);
    }

    private void UpdateLocalizedStrings()
    {
        BadgeText.Text = _loc.GetString("update_badge").ToUpperInvariant();
        TitleText.Text = _loc.GetString("update_title");
        NotesTitleText.Text = _loc.GetString("update_notes_title");
        DownloadingLabelText.Text = _loc.GetString("update_downloading");
        RestartingText.Text = _loc.GetString("update_restarting");
        LaterButton.Content = _loc.GetString("update_later");
        UpdateNowBtnText.Text = _vm?.ErrorMessage != null ? _loc.GetString("update_retry") : _loc.GetString("update_now_button");
    }

    private void UpdateVisualState()
    {
        if (_vm == null) return;

        Visibility = _vm.ShowModal ? Visibility.Visible : Visibility.Collapsed;

        if (_vm.AvailableUpdate != null)
        {
            CurrentVersionText.Text = $"v{_vm.AvailableUpdate.ClientVersion}";
            LatestVersionText.Text = $"v{_vm.AvailableUpdate.LatestVersion}";
            ReleaseNotesContentText.Text = !string.IsNullOrWhiteSpace(_vm.AvailableUpdate.ReleaseNotes)
                ? _vm.AvailableUpdate.ReleaseNotes
                : _loc.GetString("update_default_notes");

            LaterButton.Visibility = _vm.AvailableUpdate.Mandatory || _vm.State == UpdateStatus.ReadyToRestart
                ? Visibility.Collapsed
                : Visibility.Visible;
        }

        // Error message
        if (!string.IsNullOrEmpty(_vm.ErrorMessage))
        {
            ErrorBanner.Visibility = Visibility.Visible;
            ErrorMessageText.Text = _vm.ErrorMessage;
            UpdateNowBtnText.Text = _loc.GetString("update_retry");
        }
        else
        {
            ErrorBanner.Visibility = Visibility.Collapsed;
            UpdateNowBtnText.Text = _loc.GetString("update_now_button");
        }

        // Progress section
        if (_vm.State == UpdateStatus.Downloading)
        {
            ProgressSection.Visibility = Visibility.Visible;
            RestartingSection.Visibility = Visibility.Collapsed;
            DownloadProgressBar.Value = _vm.DownloadProgress * 100.0;
            ProgressPercentText.Text = $"{Math.Round(_vm.DownloadProgress * 100.0):0}%";
            UpdateNowButton.IsEnabled = false;
        }
        else if (_vm.State == UpdateStatus.ReadyToRestart)
        {
            ProgressSection.Visibility = Visibility.Collapsed;
            RestartingSection.Visibility = Visibility.Visible;
            UpdateNowButton.IsEnabled = false;
            LaterButton.Visibility = Visibility.Collapsed;
        }
        else
        {
            ProgressSection.Visibility = Visibility.Collapsed;
            RestartingSection.Visibility = Visibility.Collapsed;
            UpdateNowButton.IsEnabled = true;
        }
    }

    private void OnLaterClicked(object sender, RoutedEventArgs e)
    {
        _vm?.Dismiss();
    }

    private void OnUpdateNowClicked(object sender, RoutedEventArgs e)
    {
        if (_vm == null) return;
        _ = _vm.StartDownloadAndInstallAsync();
    }
}
