using System;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.ViewModels;

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
        ExternalEditorToggle.IsOn = Services.ExternalEditorManager.Shared.AlwaysOpenInExternalEditor;
        PopulateExternalEditorsCombo();
    }

    public void Refresh()
    {
        UpdateLocalization();
        UpdateLanguageButtons();
        UpdateUserInfo();
        ExternalEditorToggle.IsOn = Services.ExternalEditorManager.Shared.AlwaysOpenInExternalEditor;
        PopulateExternalEditorsCombo();
    }

    private void UpdateLocalization()
    {
        SettingsTitle.Text = _loc.GetString("nav_settings");
        LanguageTitle.Text = _loc.GetString("settings_language_title");
        AccountTitle.Text = _loc.GetString("account_info");
        LogoutButtonText.Text = _loc.GetString("nav_logout");
        ExternalEditorTitle.Text = _loc.GetString("settings_external_editor_title");
        ExternalEditorDesc.Text = _loc.GetString("settings_external_editor_desc");
        ExternalEditorChoiceLabel.Text = _loc.GetString("settings_external_editor_current");
        AlwaysOpenLabel.Text = _loc.GetString("settings_external_editor_always_toggle");
        AlwaysOpenDesc.Text = _loc.GetString("settings_external_editor_always_desc");
        UpdatesTitle.Text = _loc.GetString("update_section_title");
        CheckUpdatesBtnText.Text = _loc.GetString("update_check_button");
        UpToDateText.Text = _loc.GetString("update_up_to_date");
        AppVersionText.Text = $"{_loc.GetString("update_version_label")} : v{UpdateViewModel.Shared.CurrentVersion} (Windows Native x64)";

        QuickActionTitle.Text = _loc.GetString("settings_quickaction_title");
        QuickActionDesc.Text = _loc.GetString("settings_quickaction_desc");
        QuickActionSelectLabel.Text = _loc.GetString("settings_quickaction_select_label");
    }

    private readonly List<ServerInstance> _servers = new();

    public void SetServers(IEnumerable<ServerInstance>? servers)
    {
        _servers.Clear();
        if (servers != null)
        {
            _servers.AddRange(servers);
        }

        PopulateQuickActionCombo();
    }

    private void PopulateQuickActionCombo()
    {
        QuickActionServerCombo.SelectionChanged -= OnQuickActionServerChanged;
        QuickActionServerCombo.Items.Clear();

        var noneItem = new ComboBoxItem
        {
            Content = _loc.GetString("settings_quickaction_none"),
            Tag = ""
        };
        QuickActionServerCombo.Items.Add(noneItem);

        string? selectedId = Services.QuickActionServerStorage.Shared.GetSelectedServerIdentifier();
        int selectedIndex = 0;

        for (int i = 0; i < _servers.Count; i++)
        {
            var s = _servers[i];
            var item = new ComboBoxItem
            {
                Content = $"{s.Name} ({s.Identifier})",
                Tag = s.Identifier
            };
            QuickActionServerCombo.Items.Add(item);

            if (!string.IsNullOrEmpty(selectedId) && (s.Identifier == selectedId || s.Id.ToString() == selectedId))
            {
                selectedIndex = i + 1;
            }
        }

        QuickActionServerCombo.SelectedIndex = selectedIndex;
        QuickActionServerCombo.SelectionChanged += OnQuickActionServerChanged;
        UpdateQuickActionStatusCard();
    }

    private void OnQuickActionServerChanged(object sender, SelectionChangedEventArgs e)
    {
        if (QuickActionServerCombo.SelectedItem is ComboBoxItem item && item.Tag is string id)
        {
            Services.QuickActionServerStorage.Shared.SetSelectedServerIdentifier(string.IsNullOrEmpty(id) ? null : id);
            UpdateQuickActionStatusCard();
        }
    }

    private void UpdateQuickActionStatusCard()
    {
        string? selectedId = Services.QuickActionServerStorage.Shared.GetSelectedServerIdentifier();
        var current = _servers.Find(s => s.Identifier == selectedId || s.Id.ToString() == selectedId);

        if (current != null)
        {
            QuickActionStatusCard.Visibility = Visibility.Visible;
            string state = current.State.ToLowerInvariant();
            if (state == "running")
            {
                QuickActionStatusDot.Fill = new SolidColorBrush(ColorHelper.FromArgb(255, 64, 199, 128));
            }
            else if (state is "starting" or "stopping")
            {
                QuickActionStatusDot.Fill = new SolidColorBrush(ColorHelper.FromArgb(255, 245, 158, 11));
            }
            else
            {
                QuickActionStatusDot.Fill = new SolidColorBrush(ColorHelper.FromArgb(255, 239, 68, 68));
            }

            QuickActionStatusText.Text = $"{_loc.GetString("settings_quickaction_status_label")} : {current.State}";
            QuickActionRamText.Text = $"RAM : {(int)current.MemoryLimitMB} MB";
            QuickActionCpuText.Text = $"CPU : {(int)current.CpuLimitPercent}%";
        }
        else
        {
            QuickActionStatusCard.Visibility = Visibility.Collapsed;
        }
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
        Services.ExternalEditorManager.Shared.AlwaysOpenInExternalEditor = ExternalEditorToggle.IsOn;
    }

    private void PopulateExternalEditorsCombo()
    {
        ExternalEditorComboBox.SelectionChanged -= OnExternalEditorComboBoxSelectionChanged;
        ExternalEditorComboBox.Items.Clear();

        var manager = Services.ExternalEditorManager.Shared;
        var detected = manager.GetDetectedEditors();
        string currentResolved = manager.ResolveEditorExecutable();
        string activeName = Path.GetFileNameWithoutExtension(currentResolved);

        var autoItem = new ComboBoxItem
        {
            Content = $"Automatique ({activeName})",
            Tag = ""
        };
        ExternalEditorComboBox.Items.Add(autoItem);

        int selectedIndex = 0;
        for (int i = 0; i < detected.Count; i++)
        {
            var ed = detected[i];
            var item = new ComboBoxItem
            {
                Content = ed.Name,
                Tag = ed.Path
            };
            ExternalEditorComboBox.Items.Add(item);

            if (!string.IsNullOrEmpty(manager.SelectedEditorAppPath) &&
                string.Equals(manager.SelectedEditorAppPath, ed.Path, StringComparison.OrdinalIgnoreCase))
            {
                selectedIndex = i + 1;
            }
        }

        ExternalEditorComboBox.SelectedIndex = selectedIndex;
        ExternalEditorActivePathText.Text = currentResolved;
        ExternalEditorComboBox.SelectionChanged += OnExternalEditorComboBoxSelectionChanged;
    }

    private void OnExternalEditorComboBoxSelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (ExternalEditorComboBox.SelectedItem is ComboBoxItem item && item.Tag is string path)
        {
            Services.ExternalEditorManager.Shared.SelectedEditorAppPath = string.IsNullOrEmpty(path) ? null : path;
            ExternalEditorActivePathText.Text = Services.ExternalEditorManager.Shared.ResolveEditorExecutable();
        }
    }

    private async void OnCheckUpdatesClicked(object sender, RoutedEventArgs e)
    {
        CheckUpdatesBtn.IsEnabled = false;
        UpToDateText.Text = _loc.GetString("update_checking");
        try
        {
            var hasUpdate = await UpdateViewModel.Shared.CheckForUpdatesAsync(silent: false);
            if (!hasUpdate)
            {
                UpToDateText.Text = _loc.GetString("update_up_to_date");
            }
            else
            {
                UpToDateText.Text = _loc.GetString("update_badge");
            }
        }
        catch (Exception ex)
        {
            UpToDateText.Text = ex.Message;
        }
        finally
        {
            CheckUpdatesBtn.IsEnabled = true;
        }
    }
}
