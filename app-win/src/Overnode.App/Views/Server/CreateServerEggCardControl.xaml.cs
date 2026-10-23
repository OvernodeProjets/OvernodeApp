using System;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Overnode.App.Localization;
using Overnode.App.Models;

namespace Overnode.App.Views.Server;

public sealed partial class CreateServerEggCardControl : UserControl
{
    public static readonly DependencyProperty EggProperty =
        DependencyProperty.Register(nameof(Egg), typeof(ServerEgg), typeof(CreateServerEggCardControl), new PropertyMetadata(null, OnEggChanged));

    public static readonly DependencyProperty IsSelectedProperty =
        DependencyProperty.Register(nameof(IsSelected), typeof(bool), typeof(CreateServerEggCardControl), new PropertyMetadata(false, OnIsSelectedChanged));

    public static readonly DependencyProperty HasGodPackProperty =
        DependencyProperty.Register(nameof(HasGodPack), typeof(bool), typeof(CreateServerEggCardControl), new PropertyMetadata(false, OnHasGodPackChanged));

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

    public bool HasGodPack
    {
        get => (bool)GetValue(HasGodPackProperty);
        set => SetValue(HasGodPackProperty, value);
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

    private static void OnHasGodPackChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        if (d is CreateServerEggCardControl control)
        {
            control.UpdateEgg();
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

        var loc = LocalizationManager.Instance;
        if (Egg.GoldOnly)
        {
            GodPackBadge.Visibility = Visibility.Visible;
            GodPackBadgeText.Text = loc.GetString("create_server_godpack_badge", "God Pack");
            GodPackLockBadge.Visibility = HasGodPack ? Visibility.Collapsed : Visibility.Visible;

            string tooltipText = HasGodPack
                ? loc.GetString("create_server_godpack_unlocked_tooltip", "Inclus avec votre abonnement God Pack.")
                : loc.GetString("create_server_godpack_locked_tooltip", "Réservé aux membres God Pack. Vous pouvez l'obtenir dans la Boutique (Bundles).");

            ToolTipService.SetToolTip(CardBorder, tooltipText);
            ToolTipService.SetToolTip(CardButton, tooltipText);
        }
        else
        {
            GodPackBadge.Visibility = Visibility.Collapsed;
            GodPackLockBadge.Visibility = Visibility.Collapsed;
            ToolTipService.SetToolTip(CardBorder, Egg.Description);
            ToolTipService.SetToolTip(CardButton, Egg.Description);
        }

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
