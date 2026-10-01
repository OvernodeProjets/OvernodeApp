using System;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Overnode.App.Localization;
using Windows.UI;

namespace Overnode.App.Views.Components;

public sealed partial class HeaderBarControl : UserControl
{
    private static readonly SolidColorBrush ActiveBgBrush = new(Color.FromArgb(38, 255, 255, 255));
    private static readonly SolidColorBrush InactiveBgBrush = new(Colors.Transparent);
    private static readonly SolidColorBrush ActiveFgBrush = new(Colors.White);
    private static readonly SolidColorBrush InactiveFgBrush = new(Color.FromArgb(255, 149, 161, 173));

    public event EventHandler? RefreshRequested;

    public HeaderBarControl()
    {
        this.InitializeComponent();
        LocalizationManager.Instance.LanguageChanged += (s, e) => UpdateLanguageButtons();
        UpdateLanguageButtons();
    }

    private void UpdateLanguageButtons()
    {
        var current = LocalizationManager.Instance.CurrentLanguage;
        if (current == AppLanguage.Fr)
        {
            FrButton.Background = ActiveBgBrush;
            FrButton.Foreground = ActiveFgBrush;
            EnButton.Background = InactiveBgBrush;
            EnButton.Foreground = InactiveFgBrush;
        }
        else
        {
            FrButton.Background = InactiveBgBrush;
            FrButton.Foreground = InactiveFgBrush;
            EnButton.Background = ActiveBgBrush;
            EnButton.Foreground = ActiveFgBrush;
        }

        if (RefreshButton != null)
        {
            ToolTipService.SetToolTip(RefreshButton, LocalizationManager.Instance.GetString("header_refresh_tooltip"));
        }
    }

    private void OnFrClicked(object sender, RoutedEventArgs e)
    {
        LocalizationManager.Instance.SetLanguage(AppLanguage.Fr);
    }

    private void OnEnClicked(object sender, RoutedEventArgs e)
    {
        LocalizationManager.Instance.SetLanguage(AppLanguage.En);
    }

    private void OnRefreshClicked(object sender, RoutedEventArgs e)
    {
        RefreshRequested?.Invoke(this, EventArgs.Empty);
    }
}
