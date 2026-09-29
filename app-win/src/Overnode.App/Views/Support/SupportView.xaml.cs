using System;
using System.Threading.Tasks;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.ViewModels;

namespace Overnode.App.Views.Support;

public sealed partial class SupportView : UserControl
{
    private readonly LocalizationManager _loc = LocalizationManager.Instance;
    public SupportViewModel ViewModel { get; } = new();

    public SupportView()
    {
        InitializeComponent();
        ViewModel.PropertyChanged += (_, _) => UpdateUI();
        _loc.LanguageChanged += (_, _) => UpdateLocalization();
        UpdateLocalization();
    }

    public async Task InitializeAsync()
    {
        await ViewModel.LoadTicketsAsync();
        UpdateUI();
    }

    private void UpdateLocalization()
    {
        TitleText.Text = _loc.GetString("support_title");
        SubtitleText.Text = _loc.GetString("support_subtitle");
        NewTicketBtnText.Text = _loc.GetString("support_new_ticket");
    }

    private void UpdateUI()
    {
        UpdateTicketsList();
        UpdateDetailView();
    }

    private void UpdateTicketsList()
    {
        TicketsListPanel.Children.Clear();
        foreach (var ticket in ViewModel.Tickets)
        {
            bool isSelected = ViewModel.SelectedTicket?.Id == ticket.Id;
            var border = new Border
            {
                Background = isSelected ? new SolidColorBrush(ColorHelper.FromArgb(30, 245, 158, 11)) : (SolidColorBrush)Application.Current.Resources["OvernodeSecondaryCardBrush"],
                BorderBrush = isSelected ? (SolidColorBrush)Application.Current.Resources["OvernodeAccentGoldBrush"] : (SolidColorBrush)Application.Current.Resources["OvernodeBorderSubtleBrush"],
                BorderThickness = new Thickness(isSelected ? 1.5 : 1),
                CornerRadius = new CornerRadius(8),
                Padding = new Thickness(12, 10, 12, 10)
            };

            var stack = new StackPanel { Spacing = 4 };
            var topRow = new Grid();
            topRow.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            topRow.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

            var subjText = new TextBlock { Text = ticket.Subject, FontSize = 12.5, FontWeight = Microsoft.UI.Text.FontWeights.SemiBold, Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"], TextTrimming = TextTrimming.CharacterEllipsis };
            Grid.SetColumn(subjText, 0);
            topRow.Children.Add(subjText);

            bool isOpen = ticket.Status.Equals("open", StringComparison.OrdinalIgnoreCase);
            var statusBadge = new Border
            {
                Background = isOpen ? new SolidColorBrush(ColorHelper.FromArgb(30, 34, 197, 94)) : new SolidColorBrush(ColorHelper.FromArgb(20, 255, 255, 255)),
                CornerRadius = new CornerRadius(4),
                Padding = new Thickness(6, 2, 6, 2),
                Child = new TextBlock { Text = isOpen ? "OUVERT" : "FERMÉ", FontSize = 9, FontWeight = Microsoft.UI.Text.FontWeights.Bold, Foreground = isOpen ? (SolidColorBrush)Application.Current.Resources["OvernodeAccentSuccessBrush"] : (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"] }
            };
            Grid.SetColumn(statusBadge, 1);
            topRow.Children.Add(statusBadge);
            stack.Children.Add(topRow);

            var metaRow = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6 };
            metaRow.Children.Add(new TextBlock { Text = ticket.Category, FontSize = 10.5, Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"] });
            metaRow.Children.Add(new TextBlock { Text = "•", Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextMutedBrush"] });
            metaRow.Children.Add(new TextBlock { Text = ticket.CreatedAt, FontSize = 10, FontFamily = new FontFamily("Consolas"), Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"] });
            stack.Children.Add(metaRow);

            var btn = new Button
            {
                Content = stack,
                Background = new SolidColorBrush(Colors.Transparent),
                BorderThickness = new Thickness(0),
                Padding = new Thickness(0),
                HorizontalAlignment = HorizontalAlignment.Stretch,
                HorizontalContentAlignment = HorizontalAlignment.Stretch
            };
            btn.Click += (_, _) =>
            {
                ViewModel.SelectedTicket = ticket;
                UpdateUI();
            };
            border.Child = btn;
            TicketsListPanel.Children.Add(border);
        }
    }

    private void UpdateDetailView()
    {
        var ticket = ViewModel.SelectedTicket;
        if (ticket == null)
        {
            TicketDetailGrid.Visibility = Visibility.Collapsed;
            return;
        }

        TicketDetailGrid.Visibility = Visibility.Visible;
        DetailSubjectText.Text = ticket.Subject;
        DetailCategoryText.Text = ticket.Category;
        DetailDateText.Text = ticket.CreatedAt;

        bool isOpen = ticket.Status.Equals("open", StringComparison.OrdinalIgnoreCase);
        DetailStatusBadge.Background = isOpen ? new SolidColorBrush(ColorHelper.FromArgb(30, 34, 197, 94)) : new SolidColorBrush(ColorHelper.FromArgb(20, 255, 255, 255));
        DetailStatusText.Text = isOpen ? "OUVERT" : "FERMÉ";
        DetailStatusText.Foreground = isOpen ? (SolidColorBrush)Application.Current.Resources["OvernodeAccentSuccessBrush"] : (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"];

        MessagesPanel.Children.Clear();
        foreach (var msg in ticket.Messages)
        {
            var msgBorder = new Border
            {
                Background = msg.IsStaff ? new SolidColorBrush(ColorHelper.FromArgb(25, 245, 158, 11)) : (SolidColorBrush)Application.Current.Resources["OvernodeSecondaryCardBrush"],
                BorderBrush = msg.IsStaff ? new SolidColorBrush(ColorHelper.FromArgb(60, 245, 158, 11)) : (SolidColorBrush)Application.Current.Resources["OvernodeBorderSubtleBrush"],
                BorderThickness = new Thickness(1),
                CornerRadius = new CornerRadius(8),
                Padding = new Thickness(12, 10, 12, 10),
                MaxWidth = 550,
                HorizontalAlignment = msg.IsStaff ? HorizontalAlignment.Left : HorizontalAlignment.Right
            };

            var msgStack = new StackPanel { Spacing = 4 };
            var authorRow = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6 };
            authorRow.Children.Add(new TextBlock { Text = msg.Sender, FontSize = 11.5, FontWeight = Microsoft.UI.Text.FontWeights.SemiBold, Foreground = msg.IsStaff ? (SolidColorBrush)Application.Current.Resources["OvernodeAccentGoldBrush"] : (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"] });

            if (msg.IsStaff)
            {
                authorRow.Children.Add(new Border
                {
                    Background = (SolidColorBrush)Application.Current.Resources["OvernodeAccentGoldBrush"],
                    CornerRadius = new CornerRadius(3),
                    Padding = new Thickness(5, 1, 5, 1),
                    Child = new TextBlock { Text = "STAFF", FontSize = 8.5, FontWeight = Microsoft.UI.Text.FontWeights.Bold, Foreground = new SolidColorBrush(Colors.Black) }
                });
            }

            authorRow.Children.Add(new TextBlock { Text = msg.CreatedAt, FontSize = 10, FontFamily = new FontFamily("Consolas"), Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextMutedBrush"], VerticalAlignment = VerticalAlignment.Center });
            msgStack.Children.Add(authorRow);

            msgStack.Children.Add(new TextBlock { Text = msg.Content, FontSize = 12.5, Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"], TextWrapping = TextWrapping.Wrap });
            msgBorder.Child = msgStack;
            MessagesPanel.Children.Add(msgBorder);
        }
    }

    private async void OnSubmitNewTicketClicked(object sender, RoutedEventArgs e)
    {
        ViewModel.NewTicketSubject = NewTicketSubjectBox.Text;
        ViewModel.NewTicketCategory = (NewTicketCategoryCombo.SelectedItem as ComboBoxItem)?.Content?.ToString() ?? "Serveurs";
        ViewModel.NewTicketDescription = NewTicketDescBox.Text;

        if (await ViewModel.CreateTicketAsync())
        {
            CreateTicketFlyout.Hide();
            NewTicketSubjectBox.Text = string.Empty;
            NewTicketDescBox.Text = string.Empty;
            UpdateUI();
        }
    }

    private async void OnSendReplyClicked(object sender, RoutedEventArgs e)
    {
        await SendReplyAsync();
    }

    private async void OnReplyKeyDown(object sender, KeyRoutedEventArgs e)
    {
        if (e.Key == Windows.System.VirtualKey.Enter)
        {
            await SendReplyAsync();
        }
    }

    private async Task SendReplyAsync()
    {
        if (string.IsNullOrWhiteSpace(ReplyInput.Text)) return;
        ViewModel.ReplyMessage = ReplyInput.Text;
        if (await ViewModel.SendReplyAsync())
        {
            ReplyInput.Text = string.Empty;
            UpdateDetailView();
        }
    }

    private async void OnRefreshClicked(object sender, RoutedEventArgs e) => await ViewModel.LoadTicketsAsync();
}
