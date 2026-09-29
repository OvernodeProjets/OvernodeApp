using System;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.ViewModels;
using Windows.ApplicationModel.DataTransfer;

namespace Overnode.App.Views.Server;

public sealed partial class ServerSubdomainsTabControl : UserControl
{
    public ServerDetailViewModel? ViewModel => DataContext as ServerDetailViewModel;

    public ServerSubdomainsTabControl()
    {
        this.InitializeComponent();
        LocalizationManager.Instance.LanguageChanged += (s, e) => UpdateLocalization();
        DataContextChanged += (s, e) => UpdateUI();
        Loaded += async (s, e) =>
        {
            if (ViewModel != null && ViewModel.Subdomains.Count == 0)
            {
                await ViewModel.LoadSubdomainsAsync();
            }
            UpdateUI();
        };
        UpdateLocalization();
    }

    private void UpdateLocalization()
    {
        var loc = LocalizationManager.Instance;
        SubdomainsTitle.Text = loc.GetString("subdomains_title");
        SubdomainsSubtitle.Text = loc.GetString("subdomains_subtitle");
        CreateSubdomainBtnText.Text = loc.GetString("subdomains_create_button");
        DialogTitle.Text = loc.GetString("subdomains_create_button");
        CreateBtnText.Text = loc.GetString("generic_create");
        EmptyText.Text = loc.GetString("subdomains_empty");
    }

    public void UpdateUI()
    {
        if (ViewModel == null) return;

        SubdomainsItemsControl.ItemsSource = ViewModel.Subdomains;
        DomainsComboBox.ItemsSource = ViewModel.AvailableDomains;
        if (DomainsComboBox.SelectedIndex < 0 && ViewModel.AvailableDomains.Count > 0)
        {
            DomainsComboBox.SelectedIndex = 0;
        }

        EmptyContainer.Visibility = ViewModel.Subdomains.Count == 0 ? Visibility.Visible : Visibility.Collapsed;
        SubdomainsItemsControl.Visibility = ViewModel.Subdomains.Count > 0 ? Visibility.Visible : Visibility.Collapsed;
    }

    private async void OnCreateSubdomainConfirmed(object sender, RoutedEventArgs e)
    {
        string prefix = SubdomainPrefixBox.Text.Trim();
        string? domain = DomainsComboBox.SelectedItem as string ?? "overnode.fr";

        if (string.IsNullOrEmpty(prefix) || ViewModel == null) return;

        SubdomainPrefixBox.Text = string.Empty;
        CreateSubdomainFlyout.Hide();

        await ViewModel.CreateSubdomainAsync(prefix, domain);
        UpdateUI();
    }

    private void OnCopySubdomainClicked(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement fe && fe.DataContext is ServerSubdomain sub)
        {
            var package = new DataPackage();
            package.SetText(sub.Fqdn);
            Clipboard.SetContent(package);
        }
    }

    private async void OnDeleteSubdomainClicked(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement fe && fe.DataContext is ServerSubdomain sub && ViewModel != null)
        {
            await ViewModel.DeleteSubdomainAsync(sub.Id);
            UpdateUI();
        }
    }
}
