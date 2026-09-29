using System;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Overnode.App.Localization;
using Overnode.App.Models;

namespace Overnode.App.Views.Settings;

public sealed partial class SettingsControl : UserControl
{
    private readonly LocalizationManager _loc = LocalizationManager.Instance;
    private User? _currentUser;

    public event EventHandler? LogoutRequested;

    public User? CurrentUser
    {
        get => _currentUser;
        set
        {
            _currentUser = value;
            UpdateUserInfo();
        }
    }

    public SettingsControl()
    {
        InitializeComponent();
        _loc.LanguageChanged += (_, _) =>
        {
            UpdateLocalization();
            UpdateLanguageButtons();
        };

        UpdateLocalization();
        UpdateLanguageButtons();
    }

    public void Refresh()
    {
        UpdateLocalization();
        UpdateLanguageButtons();
        UpdateUserInfo();
    }

    private void UpdateLocalization()
    {
        SettingsTitle.Text = _loc.GetString("nav_settings");
        LanguageTitle.Text = _loc.GetString("settings_language_title");
        AccountTitle.Text = _loc.GetString("account_info");
        LogoutButtonText.Text = _loc.GetString("nav_logout");
        ExternalEditorTitle.Text = _loc.GetString("settings_external_editor_title");
        ExternalEditorDesc.Text = _loc.GetString("settings_external_editor_desc");
        AlwaysOpenLabel.Text = _loc.GetString("settings_external_editor_always_toggle");
        AlwaysOpenDesc.Text = _loc.GetString("settings_external_editor_always_desc");
        UpdatesTitle.Text = _loc.GetString("update_section_title");
        CheckUpdatesBtnText.Text = _loc.GetString("update_check_button");
        UpToDateText.Text = _loc.GetString("update_up_to_date");
    }

    private void UpdateLanguageButtons()
    {
        var isFr = _loc.CurrentLanguage == AppLanguage.Fr;

        var goldBrush = (SolidColorBrush)Application.Current.Resources["OvernodeAccentGoldBrush"];
        var subtleBorderBrush = (SolidColorBrush)Application.Current.Resources["OvernodeBorderSubtleBrush"];
        var activeBgBrush = new SolidColorBrush(ColorHelper.FromArgb(35, 245, 158, 11));
        var transparentBrush = new SolidColorBrush(Colors.Transparent);

        BtnLangFr.Background = isFr ? activeBgBrush : transparentBrush;
        BtnLangFr.BorderBrush = isFr ? goldBrush : subtleBorderBrush;

        BtnLangEn.Background = !isFr ? activeBgBrush : transparentBrush;
        BtnLangEn.BorderBrush = !isFr ? goldBrush : subtleBorderBrush;
    }

    private void UpdateUserInfo()
    {
        if (_currentUser != null)
        {
            UsernameText.Text = _currentUser.DisplayName;
            UserInitialText.Text = _currentUser.Initial;
            UserEmailText.Text = !string.IsNullOrWhiteSpace(_currentUser.Email) ? _currentUser.Email : "email@overnode.fr";
            UserRoleText.Text = !string.IsNullOrWhiteSpace(_currentUser.Role) ? _currentUser.Role.ToUpperInvariant() : "MEMBRE";
        }
        else
        {
            UsernameText.Text = "Utilisateur";
            UserInitialText.Text = "U";
            UserEmailText.Text = "—";
            UserRoleText.Text = "MEMBRE";
        }
    }

    private void OnFrenchSelected(object sender, RoutedEventArgs e)
    {
        _loc.SetLanguage(AppLanguage.Fr);
        UpdateLanguageButtons();
    }

    private void OnEnglishSelected(object sender, RoutedEventArgs e)
    {
        _loc.SetLanguage(AppLanguage.En);
        UpdateLanguageButtons();
    }

    private void OnLogoutClicked(object sender, RoutedEventArgs e)
    {
        LogoutRequested?.Invoke(this, EventArgs.Empty);
    }

    private void OnExternalEditorToggled(object sender, RoutedEventArgs e)
    {
        // Saved locally for preferences
    }

    private void OnCheckUpdatesClicked(object sender, RoutedEventArgs e)
    {
        UpToDateText.Text = _loc.GetString("update_up_to_date");
    }
}
