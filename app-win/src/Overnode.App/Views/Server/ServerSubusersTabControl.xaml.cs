using System;
using System.Collections.Generic;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.ViewModels;

namespace Overnode.App.Views.Server;

public sealed partial class ServerSubusersTabControl : UserControl
{
    public ServerDetailViewModel? ViewModel => DataContext as ServerDetailViewModel;

    public ServerSubusersTabControl()
    {
        this.InitializeComponent();
        LocalizationManager.Instance.LanguageChanged += (s, e) => UpdateLocalization();
        DataContextChanged += (s, e) => UpdateUI();
        Loaded += async (s, e) =>
        {
            if (ViewModel != null && ViewModel.Subusers.Count == 0)
            {
                await ViewModel.LoadSubusersAsync();
            }
            UpdateUI();
        };
        UpdateLocalization();
    }

    private void UpdateLocalization()
    {
        var loc = LocalizationManager.Instance;
        SubusersTitle.Text = loc.GetString("subusers_title");
        SubusersSubtitle.Text = loc.GetString("subusers_subtitle");
        InviteSubuserBtnText.Text = loc.GetString("subusers_invite_button");
        InviteDialogTitle.Text = loc.GetString("subusers_invite_button");
        InviteBtnText.Text = loc.GetString("generic_invite");
        EmptyText.Text = loc.GetString("subusers_empty");
    }

    public void UpdateUI()
    {
        if (ViewModel == null) return;

        SubusersItemsControl.ItemsSource = ViewModel.Subusers;
        EmptyContainer.Visibility = ViewModel.Subusers.Count == 0 ? Visibility.Visible : Visibility.Collapsed;
        SubusersItemsControl.Visibility = ViewModel.Subusers.Count > 0 ? Visibility.Visible : Visibility.Collapsed;
    }

    private async void OnInviteSubuserConfirmed(object sender, RoutedEventArgs e)
    {
        string email = SubuserEmailBox.Text.Trim();
        if (string.IsNullOrEmpty(email) || ViewModel == null) return;

        SubuserEmailBox.Text = string.Empty;
        InviteSubuserFlyout.Hide();

        await ViewModel.AddSubuserAsync(email, new List<string> { "*" });
        UpdateUI();
    }

    private async void OnDeleteSubuserClicked(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement fe && fe.DataContext is ServerSubuser user && ViewModel != null)
        {
            await ViewModel.DeleteSubuserAsync(user.Id);
            UpdateUI();
        }
    }
}
