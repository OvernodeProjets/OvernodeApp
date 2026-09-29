using System;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Overnode.App.Models;

namespace Overnode.App.Views.Server;

public sealed partial class CreateServerEggCardControl : UserControl
{
    public static readonly DependencyProperty EggProperty =
        DependencyProperty.Register(nameof(Egg), typeof(ServerEgg), typeof(CreateServerEggCardControl), new PropertyMetadata(null, OnEggChanged));

    public static readonly DependencyProperty IsSelectedProperty =
        DependencyProperty.Register(nameof(IsSelected), typeof(bool), typeof(CreateServerEggCardControl), new PropertyMetadata(false, OnIsSelectedChanged));

    public ServerEgg? Egg
    {
        get => (ServerEgg?)GetValue(EggProperty);
        set => SetValue(EggProperty, value);
    }

    public bool IsSelected
    {
        get => (bool)GetValue(IsSelectedProperty);
        set => SetValue(IsSelectedProperty, value);
    }

    public event Action<ServerEgg>? EggSelected;

    public CreateServerEggCardControl()
    {
        InitializeComponent();
    }

    private static void OnEggChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        if (d is CreateServerEggCardControl control)
        {
            control.UpdateEgg();
        }
    }

    private static void OnIsSelectedChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        if (d is CreateServerEggCardControl control)
        {
            control.UpdateSelection();
        }
    }

    private void UpdateEgg()
    {
        if (Egg == null) return;

        EggNameText.Text = Egg.Name;
        EggDescriptionText.Text = Egg.Description;
        EggIcon.Glyph = Egg.IconGlyph;

        RamSpecText.Text = $"{Egg.Minimum.Ram:F0} MB";
        CpuSpecText.Text = $"{Egg.Minimum.Cpu:F0}%";
        DiskSpecText.Text = $"{Egg.Minimum.Disk:F0} MB";

        UpdateSelection();
    }

    private void UpdateSelection()
    {
        if (IsSelected)
        {
            CardBorder.Background = new SolidColorBrush(ColorHelper.FromArgb(30, 245, 158, 11)); // gold tint
            CardBorder.BorderBrush = (SolidColorBrush)Application.Current.Resources["OvernodeAccentGoldBrush"];
            CardBorder.BorderThickness = new Thickness(1.5);
            SelectedCheckBadge.Visibility = Visibility.Visible;
            IconContainer.Background = new SolidColorBrush(ColorHelper.FromArgb(50, 245, 158, 11));
        }
        else
        {
            CardBorder.Background = (SolidColorBrush)Application.Current.Resources["OvernodeSecondaryCardBrush"];
            CardBorder.BorderBrush = (SolidColorBrush)Application.Current.Resources["OvernodeBorderSubtleBrush"];
            CardBorder.BorderThickness = new Thickness(1);
            SelectedCheckBadge.Visibility = Visibility.Collapsed;
            IconContainer.Background = new SolidColorBrush(ColorHelper.FromArgb(16, 255, 255, 255));
        }
    }

    private void OnCardClicked(object sender, RoutedEventArgs e)
    {
        if (Egg != null)
        {
            EggSelected?.Invoke(Egg);
        }
    }
}
