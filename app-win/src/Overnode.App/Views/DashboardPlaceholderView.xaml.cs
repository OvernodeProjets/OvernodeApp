using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Overnode.App.ViewModels;

namespace Overnode.App.Views;

public sealed partial class DashboardPlaceholderView : UserControl
{
    public AuthViewModel? ViewModel { get; private set; }

    public DashboardPlaceholderView()
    {
        InitializeComponent();
    }

    public void Initialize(AuthViewModel viewModel)
    {
        ViewModel = viewModel;
        UpdateData();
    }

    public void UpdateData()
    {
        if (ViewModel?.CurrentUser != null)
        {
            var u = ViewModel.CurrentUser;
            UsernameText.Text = u.DisplayName;
            EmailText.Text = u.Email;
            DetailIdText.Text = u.Id;
            DetailRoleText.Text = u.Role ?? "Client";
            DetailCoinsText.Text = $"{u.Coins} coins";
        }
    }

    private void LogoutButton_Click(object sender, RoutedEventArgs e)
    {
        ViewModel?.Logout();
    }
}
