using System;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.Services;

namespace Overnode.App.Views.Settings;

public sealed partial class DiscordVIPPromptModalControl : UserControl
{
    private readonly LocalizationManager _loc = LocalizationManager.Instance;
    private readonly GodPackService _godPackService = GodPackService.Shared;

    public event EventHandler? Dismissed;
    public event EventHandler? VIPActivated;
    public event EventHandler? VIPUnlinked;

    public User? CurrentUser { get; set; }

    public DiscordVIPPromptModalControl()
    {
        InitializeComponent();
        _loc.LanguageChanged += (_, _) => UpdateLocalization();
        UpdateLocalization();
    }

    public void RefreshState()
    {
        ErrorBanner.Visibility = Visibility.Collapsed;
        VerifyProgressRing.Visibility = Visibility.Collapsed;
        VerifyIcon.Visibility = Visibility.Visible;
        VerifyBtn.IsEnabled = true;

        string? savedId = _godPackService.SavedDiscordId;
        if (!string.IsNullOrEmpty(savedId))
        {
            DiscordIdInput.Text = savedId;
            ActiveVipText.Text = _loc.Format("godpack_vip_active_badge", savedId);
            ActiveVipBadge.Visibility = Visibility.Visible;
        }
        else
        {
            ActiveVipBadge.Visibility = Visibility.Collapsed;
            string? rpcId = DiscordRPCService.Shared.CurrentDiscordUserId?.Trim();
            if (!string.IsNullOrEmpty(rpcId))
            {
                DiscordIdInput.Text = rpcId;
            }
        }

        string? currentRpc = DiscordRPCService.Shared.CurrentDiscordUserId?.Trim();
        if (!string.IsNullOrEmpty(currentRpc))
        {
            DetectedDiscordText.Text = _loc.Format("godpack_vip_detected_discord", currentRpc);
            DetectedDiscordBtn.Visibility = Visibility.Visible;
        }
        else
        {
            DetectedDiscordBtn.Visibility = Visibility.Collapsed;
        }

        UpdateVerifyButtonState();
        UpdateLocalization();
    }

    private void UpdateLocalization()
    {
        ModalTitleText.Text = _loc.GetString("godpack_vip_modal_title");
        ModalSubtitleText.Text = _loc.GetString("godpack_vip_modal_subtitle");
        ModalDescText.Text = _loc.GetString("godpack_vip_modal_desc");
        DiscordIdInput.PlaceholderText = _loc.GetString("godpack_vip_input_placeholder");
        CancelBtnText.Text = _loc.GetString("btn_cancel", "Annuler");
        VerifyBtnText.Text = _loc.GetString("godpack_vip_btn_verify");
        ErrorBannerText.Text = _loc.GetString("godpack_alert_vip_failed");
        UnlinkBtnText.Text = _loc.GetString("godpack_vip_unlink_btn");

        if (!string.IsNullOrEmpty(_godPackService.SavedDiscordId))
        {
            ActiveVipText.Text = _loc.Format("godpack_vip_active_badge", _godPackService.SavedDiscordId);
        }

        string? currentRpc = DiscordRPCService.Shared.CurrentDiscordUserId?.Trim();
        if (!string.IsNullOrEmpty(currentRpc))
        {
            DetectedDiscordText.Text = _loc.Format("godpack_vip_detected_discord", currentRpc);
        }
    }

    private void OnDiscordIdInputChanged(object sender, TextChangedEventArgs e)
    {
        ErrorBanner.Visibility = Visibility.Collapsed;
        UpdateVerifyButtonState();
    }

    private void UpdateVerifyButtonState()
    {
        bool hasInput = !string.IsNullOrWhiteSpace(DiscordIdInput.Text);
        VerifyBtn.IsEnabled = hasInput && !_godPackService.IsChecking;
        VerifyBtn.Opacity = hasInput ? 1.0 : 0.6;
    }

    private void OnUseDetectedDiscordIdClicked(object sender, RoutedEventArgs e)
    {
        string? currentRpc = DiscordRPCService.Shared.CurrentDiscordUserId?.Trim();
        if (!string.IsNullOrEmpty(currentRpc))
        {
            DiscordIdInput.Text = currentRpc;
        }
    }

    private async void OnVerifyClicked(object sender, RoutedEventArgs e)
    {
        string input = DiscordIdInput.Text.Trim();
        if (string.IsNullOrEmpty(input)) return;

        ErrorBanner.Visibility = Visibility.Collapsed;
        VerifyProgressRing.Visibility = Visibility.Visible;
        VerifyIcon.Visibility = Visibility.Collapsed;
        VerifyBtn.IsEnabled = false;

        try
        {
            await _godPackService.CheckAccessAsync(CurrentUser, input);

            if (_godPackService.HasGodPack)
            {
                VIPActivated?.Invoke(this, EventArgs.Empty);
                Dismissed?.Invoke(this, EventArgs.Empty);
            }
            else
            {
                ErrorBanner.Visibility = Visibility.Visible;
            }
        }
        catch (Exception ex)
        {
            ErrorBannerText.Text = ex.Message;
            ErrorBanner.Visibility = Visibility.Visible;
        }
        finally
        {
            VerifyProgressRing.Visibility = Visibility.Collapsed;
            VerifyIcon.Visibility = Visibility.Visible;
            UpdateVerifyButtonState();
        }
    }

    private void OnUnlinkClicked(object sender, RoutedEventArgs e)
    {
        _godPackService.ClearSavedDiscordId();
        DiscordIdInput.Text = string.Empty;
        ActiveVipBadge.Visibility = Visibility.Collapsed;
        VIPUnlinked?.Invoke(this, EventArgs.Empty);
    }

    private void OnCloseClicked(object sender, RoutedEventArgs e)
    {
        Dismissed?.Invoke(this, EventArgs.Empty);
    }
}
