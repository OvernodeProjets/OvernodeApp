using System;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.ViewModels;

namespace Overnode.App.Views.Server;

public sealed partial class ServerSettingsTabControl : UserControl
{
    public ServerDetailViewModel? ViewModel => DataContext as ServerDetailViewModel;

    public event EventHandler? ServerDeleted;

    public ServerSettingsTabControl()
    {
        this.InitializeComponent();
        LocalizationManager.Instance.LanguageChanged += (s, e) => UpdateLocalization();
        DataContextChanged += (s, e) => UpdateUI();
        Loaded += async (s, e) =>
        {
            if (ViewModel != null && ViewModel.StartupVariables.Count == 0)
            {
                await ViewModel.LoadSettingsAsync();
            }
            UpdateUI();
        };
        UpdateLocalization();
    }

    private void UpdateLocalization()
    {
        var loc = LocalizationManager.Instance;
        RenameTitleText.Text = loc.GetString("settings_rename_title");
        ServerNameTextBox.PlaceholderText = loc.GetString("settings_name_placeholder");
        RenameBtnText.Text = loc.GetString("settings_rename_button");
        VariablesTitleText.Text = loc.GetString("settings_variables_title");
        DangerZoneTitleText.Text = loc.GetString("settings_danger_zone");
        ReinstallTitleText.Text = loc.GetString("settings_reinstall_title");
        ReinstallDescText.Text = loc.GetString("settings_reinstall_desc");
        ReinstallBtnText.Text = loc.GetString("settings_reinstall_button");
        DeleteTitleText.Text = loc.GetString("settings_delete_title");
        DeleteDescText.Text = loc.GetString("settings_delete_desc");
        DeleteBtnText.Text = loc.GetString("settings_delete_confirm_btn");
        DeleteLockedText.Text = loc.GetString("server_delete_owner_only");
    }

    public void UpdateUI()
    {
        if (ViewModel == null) return;

        ServerNameTextBox.Text = ViewModel.Server.Name;
        VariablesItemsControl.ItemsSource = ViewModel.StartupVariables;
        VariablesSection.Visibility = ViewModel.StartupVariables.Count > 0 ? Visibility.Visible : Visibility.Collapsed;

        bool isOwner = ViewModel.Server.IsOwner;
        DeleteServerGrid.Visibility = isOwner ? Visibility.Visible : Visibility.Collapsed;
        DeleteLockedPanel.Visibility = !isOwner ? Visibility.Visible : Visibility.Collapsed;
    }

    private async void OnRenameClicked(object sender, RoutedEventArgs e)
    {
        string newName = ServerNameTextBox.Text.Trim();
        if (string.IsNullOrEmpty(newName) || ViewModel == null) return;

        await ViewModel.RenameServerAsync(newName);
        RenameSuccessBanner.Visibility = Visibility.Visible;
    }

    private async void OnUpdateVariableClicked(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement fe && fe.DataContext is ServerStartupVariable variable && ViewModel != null)
        {
            await ViewModel.UpdateStartupVariableAsync(variable.EnvVariable, variable.ServerValue);
        }
    }

    private async void OnReinstallClicked(object sender, RoutedEventArgs e)
    {
        if (ViewModel == null || XamlRoot == null) return;

        var loc = LocalizationManager.Instance;
        var dialog = new ContentDialog
        {
            XamlRoot = this.XamlRoot,
            Title = loc.GetString("settings_reinstall_confirm_title"),
            Content = loc.GetString("settings_reinstall_confirm_msg"),
            PrimaryButtonText = loc.GetString("settings_reinstall_confirm_btn"),
            CloseButtonText = loc.GetString("generic_cancel"),
            DefaultButton = ContentDialogButton.Close
        };

        var result = await dialog.ShowAsync();
        if (result == ContentDialogResult.Primary)
        {
            await ViewModel.ReinstallServerAsync();
        }
    }

    private async void OnDeleteClicked(object sender, RoutedEventArgs e)
    {
        if (ViewModel == null || XamlRoot == null) return;

        var loc = LocalizationManager.Instance;
        var dialog = new ContentDialog
        {
            XamlRoot = this.XamlRoot,
            Title = loc.GetString("settings_delete_confirm_title"),
            Content = loc.GetString("settings_delete_confirm_msg"),
            PrimaryButtonText = loc.GetString("settings_delete_confirm_btn"),
            CloseButtonText = loc.GetString("generic_cancel"),
            DefaultButton = ContentDialogButton.Close
        };

        var result = await dialog.ShowAsync();
        if (result == ContentDialogResult.Primary)
        {
            bool deleted = await ViewModel.DeleteServerAsync();
            if (deleted)
            {
                ServerDeleted?.Invoke(this, EventArgs.Empty);
            }
        }
    }
}
