using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.Services;
using Windows.UI;

namespace Overnode.App.Views.Settings;

public sealed partial class GodPackThemeSettingsControl : UserControl
{
    private readonly LocalizationManager _loc = LocalizationManager.Instance;
    private readonly GodPackService _godPackService = GodPackService.Shared;
    private readonly ThemeManager _themeManager = ThemeManager.Shared;

    public event EventHandler? NavigateToStoreRequested;
    public event EventHandler? OpenDiscordVIPModalRequested;

    private User? _currentUser;
    public User? CurrentUser
    {
        get => _currentUser;
        set
        {
            _currentUser = value;
            _ = CheckGodPackAccessAsync();
        }
    }

    private string _activeSubTab = "presets";

    public GodPackThemeSettingsControl()
    {
        InitializeComponent();

        _loc.LanguageChanged += (_, _) => UpdateLocalization();
        _godPackService.PropertyChanged += (_, e) =>
        {
            if (e.PropertyName == nameof(GodPackService.HasGodPack) ||
                e.PropertyName == nameof(GodPackService.IsChecking))
            {
                DispatcherQueue.TryEnqueue(UpdateAccessUI);
            }
        };

        _themeManager.PropertyChanged += (_, e) =>
        {
            if (e.PropertyName == nameof(ThemeManager.CurrentConfig))
            {
                DispatcherQueue.TryEnqueue(RefreshCustomizerFields);
            }
            else if (e.PropertyName == nameof(ThemeManager.HasActiveCustomBackground) ||
                     e.PropertyName == nameof(ThemeManager.BackgroundBitmap))
            {
                DispatcherQueue.TryEnqueue(UpdateBackgroundPreview);
            }
        };

        PresetsGrid.SizeChanged += OnPresetsGridSizeChanged;
        UpdateLocalization();
        UpdateSubTabsUI();
        PopulateLandingTabsCombo();
        RefreshCustomizerFields();
        UpdateAccessUI();
    }

    private int _lastCols = 3;
    private void OnPresetsGridSizeChanged(object sender, SizeChangedEventArgs e)
    {
        if (e.NewSize.Width <= 0) return;
        int cols = e.NewSize.Width < 740 ? 2 : 3;
        if (cols != _lastCols)
        {
            _lastCols = cols;
            PopulatePresetsUI();
        }
    }

    public async Task CheckGodPackAccessAsync()
    {
        await _godPackService.CheckAccessAsync(_currentUser);
        UpdateAccessUI();
    }

    public void RefreshState()
    {
        UpdateLocalization();
        RefreshCustomizerFields();
        UpdateAccessUI();
    }

    private void UpdateAccessUI()
    {
        bool hasGodPack = _godPackService.HasGodPack;
        LockedBadge.Visibility = hasGodPack ? Visibility.Collapsed : Visibility.Visible;
        LockedPanel.Visibility = hasGodPack ? Visibility.Collapsed : Visibility.Visible;
        UnlockedPanel.Visibility = hasGodPack ? Visibility.Visible : Visibility.Collapsed;

        CheckSubProgress.Visibility = _godPackService.IsChecking ? Visibility.Visible : Visibility.Collapsed;
        CheckSubIcon.Visibility = _godPackService.IsChecking ? Visibility.Collapsed : Visibility.Visible;
        CheckSubBtn.IsEnabled = !_godPackService.IsChecking;

        CardRootBorder.BorderBrush = hasGodPack
            ? new SolidColorBrush(Color.FromArgb(100, 245, 158, 11))
            : (Brush)Application.Current.Resources["OvernodeBorderSubtleBrush"];
    }

    private void UpdateLocalization()
    {
        CardTitleText.Text = _loc.GetString("godpack_title");
        CardSubtitleText.Text = _loc.GetString("godpack_subtitle");
        LockedBadgeText.Text = _loc.GetString("godpack_badge_locked");

        LockedTitleText.Text = _loc.GetString("godpack_locked_title");
        LockedDescText.Text = _loc.GetString("godpack_locked_desc");
        DiscoverStoreBtnText.Text = _loc.GetString("godpack_btn_discover_store");
        CheckSubBtnText.Text = _loc.GetString("godpack_btn_check_sub");

        TabLabelPresets.Text = _loc.GetString("godpack_tab_presets");
        TabLabelColors.Text = _loc.GetString("godpack_tab_colors");
        TabLabelBackground.Text = _loc.GetString("godpack_tab_background");
        TabLabelLayout.Text = _loc.GetString("godpack_tab_layout");
        TabLabelShare.Text = _loc.GetString("godpack_tab_share");

        PresetsDescText.Text = _loc.GetString("godpack_presets_desc");
        ColorsDescText.Text = _loc.GetString("godpack_colors_desc");
        BgDescText.Text = _loc.GetString("godpack_bg_desc");
        BgUrlLabelText.Text = _loc.GetString("godpack_bg_url_label");
        BgApplyBtnText.Text = _loc.GetString("godpack_bg_apply_btn");
        BgClearBtnText.Text = _loc.GetString("godpack_bg_clear_btn");
        BgChooseFileBtnText.Text = _loc.GetString("godpack_bg_choose_file_btn");
        BgActivePreviewLabel.Text = _loc.GetString("godpack_bg_active_preview");
        BgOpacityLabelText.Text = _loc.GetString("godpack_bg_opacity_label");
        BgBlurLabelText.Text = _loc.GetString("godpack_bg_blur_label");
        BgDarknessLabelText.Text = _loc.GetString("godpack_bg_darkness_label");

        LayoutDescText.Text = _loc.GetString("godpack_layout_desc");
        LandingTabLabelText.Text = _loc.GetString("godpack_landing_label");
        SidebarPosLabelText.Text = _loc.GetString("godpack_sidebar_pos_label");
        SidebarLeftText.Text = _loc.GetString("godpack_sidebar_left");
        SidebarRightText.Text = _loc.GetString("godpack_sidebar_right");
        CardRadiusLabelText.Text = _loc.GetString("godpack_card_radius_label");

        ShareDescText.Text = _loc.GetString("godpack_share_desc");
        ExportConfigBtnText.Text = _loc.GetString("godpack_export_btn");
        ImportConfigBtnText.Text = _loc.GetString("godpack_import_btn");
        ResetConfigBtnText.Text = _loc.GetString("godpack_reset_btn");

        PopulatePresetsUI();
        PopulateColorsUI();
        PopulateLandingTabsCombo();
    }

    private void OnDismissAlertClicked(object sender, RoutedEventArgs e)
    {
        SuccessAlertBanner.Visibility = Visibility.Collapsed;
        ErrorAlertBanner.Visibility = Visibility.Collapsed;
    }

    public void ShowSuccess(string message)
    {
        SuccessAlertText.Text = message;
        SuccessAlertBanner.Visibility = Visibility.Visible;
        ErrorAlertBanner.Visibility = Visibility.Collapsed;
    }

    public void ShowError(string message)
    {
        ErrorAlertText.Text = message;
        ErrorAlertBanner.Visibility = Visibility.Visible;
        SuccessAlertBanner.Visibility = Visibility.Collapsed;
    }

    private void OnDiscoverStoreClicked(object sender, RoutedEventArgs e)
    {
        NavigateToStoreRequested?.Invoke(this, EventArgs.Empty);
    }

    private void OnActivateDiscordVIPClicked(object sender, RoutedEventArgs e)
    {
        OpenDiscordVIPModalRequested?.Invoke(this, EventArgs.Empty);
    }

    private async void OnCheckSubscriptionClicked(object sender, RoutedEventArgs e)
    {
        CheckSubProgress.Visibility = Visibility.Visible;
        CheckSubIcon.Visibility = Visibility.Collapsed;
        CheckSubBtn.IsEnabled = false;

        await _godPackService.CheckAccessAsync(_currentUser);

        CheckSubProgress.Visibility = Visibility.Collapsed;
        CheckSubIcon.Visibility = Visibility.Visible;
        CheckSubBtn.IsEnabled = true;

        if (_godPackService.HasGodPack)
        {
            ShowSuccess(_loc.GetString("godpack_alert_success_active"));
        }
        else
        {
            ShowError(_loc.GetString("godpack_alert_no_pack"));
        }
    }

    // MARK: - Subtabs navigation
    private void OnSubTabClicked(object sender, RoutedEventArgs e)
    {
        if (sender is Button btn && btn.Tag is string tab)
        {
            _activeSubTab = tab;
            UpdateSubTabsUI();
        }
    }

    private void UpdateSubTabsUI()
    {
        var goldBrush = (Brush)Application.Current.Resources["OvernodeAccentGoldBrush"];
        var subtleBorderBrush = (Brush)Application.Current.Resources["OvernodeBorderSubtleBrush"];
        var transparentBrush = new SolidColorBrush(Colors.Transparent);
        var activeBgBrush = new SolidColorBrush(Color.FromArgb(46, 245, 158, 11));

        void StyleTab(Button btn, bool active)
        {
            btn.Background = active ? activeBgBrush : transparentBrush;
            btn.BorderBrush = active ? goldBrush : subtleBorderBrush;
            btn.Foreground = active ? goldBrush : (Brush)Application.Current.Resources["OvernodeTextSecondaryBrush"];
        }

        StyleTab(TabBtnPresets, _activeSubTab == "presets");
        StyleTab(TabBtnColors, _activeSubTab == "colors");
        StyleTab(TabBtnBackground, _activeSubTab == "background");
        StyleTab(TabBtnLayout, _activeSubTab == "layout");
        StyleTab(TabBtnShare, _activeSubTab == "share");

        SubTabPresetsContent.Visibility = _activeSubTab == "presets" ? Visibility.Visible : Visibility.Collapsed;
        SubTabColorsContent.Visibility = _activeSubTab == "colors" ? Visibility.Visible : Visibility.Collapsed;
        SubTabBackgroundContent.Visibility = _activeSubTab == "background" ? Visibility.Visible : Visibility.Collapsed;
        SubTabLayoutContent.Visibility = _activeSubTab == "layout" ? Visibility.Visible : Visibility.Collapsed;
        SubTabShareContent.Visibility = _activeSubTab == "share" ? Visibility.Visible : Visibility.Collapsed;
    }

    // MARK: - 1. Presets Section
    private void PopulatePresetsUI()
    {
        if (PresetsGrid == null) return;
        PresetsGrid.Children.Clear();
        PresetsGrid.RowDefinitions.Clear();

        var presets = _themeManager.Presets;
        int cols = PresetsGrid.ActualWidth > 0 && PresetsGrid.ActualWidth < 740 ? 2 : 3;
        _lastCols = cols;

        if (PresetsGrid.ColumnDefinitions.Count != cols)
        {
            PresetsGrid.ColumnDefinitions.Clear();
            for (int c = 0; c < cols; c++)
            {
                PresetsGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            }
        }

        int rows = (int)Math.Ceiling(presets.Count / (double)cols);
        for (int r = 0; r < rows; r++)
        {
            PresetsGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        }

        for (int i = 0; i < presets.Count; i++)
        {
            var preset = presets[i];
            int r = i / cols;
            int c = i % cols;

            var card = CreatePresetThemeCard(preset);
            Grid.SetRow(card, r);
            Grid.SetColumn(card, c);
            PresetsGrid.Children.Add(card);
        }
    }

    private Border CreatePresetThemeCard(AppThemeConfig preset)
    {
        bool isCurrent = string.Equals(_themeManager.CurrentConfig.Name, preset.Name, StringComparison.OrdinalIgnoreCase);

        var card = new Border
        {
            Background = isCurrent
                ? new SolidColorBrush(Color.FromArgb(32, 245, 158, 11))
                : (Brush)Application.Current.Resources["OvernodeSecondaryCardBrush"],
            BorderBrush = isCurrent
                ? (Brush)Application.Current.Resources["OvernodeAccentGoldBrush"]
                : (Brush)Application.Current.Resources["OvernodeBorderSubtleBrush"],
            BorderThickness = new Thickness(isCurrent ? 1.5 : 1.0),
            CornerRadius = new CornerRadius(10),
            Padding = new Thickness(12),
            HorizontalAlignment = HorizontalAlignment.Stretch
        };

        var stack = new StackPanel { Spacing = 10 };

        // 1. Mini Mockup Window Preview Banner
        var mockupBanner = CreateMockupBanner(preset);
        stack.Children.Add(mockupBanner);

        // 2. Continuous 5-Color Palette Strip
        var paletteStrip = CreatePaletteRibbon(preset);
        stack.Children.Add(paletteStrip);

        // 3. Header: Icon, Name, Author, Active Badge
        var headerGrid = new Grid { Margin = new Thickness(0, 2, 0, 0) };
        headerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        headerGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        var titleStack = new StackPanel { Spacing = 2 };
        var nameRow = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6 };

        string iconGlyph = GetPresetEmojiOrGlyph(preset.Name);
        nameRow.Children.Add(new TextBlock
        {
            Text = iconGlyph,
            FontSize = 13,
            VerticalAlignment = VerticalAlignment.Center
        });
        nameRow.Children.Add(new TextBlock
        {
            Text = preset.Name,
            FontSize = 13,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            Foreground = (Brush)Application.Current.Resources["OvernodeTextPrimaryBrush"],
            VerticalAlignment = VerticalAlignment.Center
        });
        titleStack.Children.Add(nameRow);

        titleStack.Children.Add(new TextBlock
        {
            Text = preset.Author,
            FontSize = 10.5,
            Foreground = (Brush)Application.Current.Resources["OvernodeTextMutedBrush"]
        });
        Grid.SetColumn(titleStack, 0);
        headerGrid.Children.Add(titleStack);

        if (isCurrent)
        {
            var activeBadge = new Border
            {
                Background = new SolidColorBrush(Color.FromArgb(40, 245, 158, 11)),
                BorderBrush = (Brush)Application.Current.Resources["OvernodeAccentGoldBrush"],
                BorderThickness = new Thickness(1),
                CornerRadius = new CornerRadius(4),
                Padding = new Thickness(6, 2, 6, 2),
                VerticalAlignment = VerticalAlignment.Center
            };
            var badgeStack = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 4 };
            badgeStack.Children.Add(new FontIcon
            {
                Glyph = "\uE73E",
                FontSize = 10,
                Foreground = (Brush)Application.Current.Resources["OvernodeAccentGoldBrush"]
            });
            badgeStack.Children.Add(new TextBlock
            {
                Text = "ACTIF",
                FontSize = 9.5,
                FontWeight = Microsoft.UI.Text.FontWeights.Bold,
                Foreground = (Brush)Application.Current.Resources["OvernodeAccentGoldBrush"]
            });
            activeBadge.Child = badgeStack;
            Grid.SetColumn(activeBadge, 1);
            headerGrid.Children.Add(activeBadge);
        }

        stack.Children.Add(headerGrid);

        // 4. Color Swatches Circles Row (with Tooltips)
        var swatches = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6, Margin = new Thickness(0, 2, 0, 0) };
        swatches.Children.Add(CreateColorSwatchCircle(preset.Colors.BackgroundHex, "Arrière-plan"));
        swatches.Children.Add(CreateColorSwatchCircle(preset.Colors.CardBackgroundHex, "Cartes & Surfaces"));
        swatches.Children.Add(CreateColorSwatchCircle(preset.Colors.AccentGoldHex, "Accent Principal"));
        swatches.Children.Add(CreateColorSwatchCircle(preset.Colors.AccentCyanHex, "Accent Secondaire"));
        swatches.Children.Add(CreateColorSwatchCircle(preset.Colors.BorderHex, "Bordure"));
        stack.Children.Add(swatches);

        // 5. Apply Button
        var applyBtn = new Button
        {
            Content = isCurrent ? "✓ Thème Actif" : _loc.GetString("godpack_preset_apply"),
            IsEnabled = !isCurrent,
            HorizontalAlignment = HorizontalAlignment.Stretch,
            FontSize = 11.5,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            CornerRadius = new CornerRadius(6),
            Padding = new Thickness(0, 6, 0, 6),
            Background = isCurrent
                ? new SolidColorBrush(Color.FromArgb(40, 245, 158, 11))
                : new SolidColorBrush(Color.FromArgb(24, 255, 255, 255)),
            Foreground = isCurrent
                ? (Brush)Application.Current.Resources["OvernodeAccentGoldBrush"]
                : (Brush)Application.Current.Resources["OvernodeTextPrimaryBrush"],
            BorderBrush = isCurrent
                ? (Brush)Application.Current.Resources["OvernodeAccentGoldBrush"]
                : new SolidColorBrush(Color.FromArgb(40, 255, 255, 255)),
            BorderThickness = new Thickness(1)
        };

        void ApplyAction()
        {
            if (isCurrent) return;
            _themeManager.ApplyPreset(preset);
            PopulatePresetsUI();
            PopulateColorsUI();
            ShowSuccess(_loc.Format("godpack_preset_applied_alert", preset.Name));
        }

        applyBtn.Click += (_, _) => ApplyAction();
        card.Tapped += (_, _) => ApplyAction();

        card.PointerEntered += (_, _) =>
        {
            if (!isCurrent)
            {
                card.BorderBrush = new SolidColorBrush(Color.FromArgb(120, 255, 255, 255));
            }
        };
        card.PointerExited += (_, _) =>
        {
            if (!isCurrent)
            {
                card.BorderBrush = (Brush)Application.Current.Resources["OvernodeBorderSubtleBrush"];
            }
        };

        stack.Children.Add(applyBtn);
        card.Child = stack;

        return card;
    }

    private static Border CreateMockupBanner(AppThemeConfig preset)
    {
        var banner = new Border
        {
            Height = 48,
            CornerRadius = new CornerRadius(6),
            Background = ColorHexHelper.ToBrush(preset.Colors.BackgroundHex),
            BorderBrush = new SolidColorBrush(Color.FromArgb(40, 255, 255, 255)),
            BorderThickness = new Thickness(1)
        };

        var grid = new Grid();
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(20, GridUnitType.Pixel) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        var miniSidebar = new Border
        {
            Background = ColorHexHelper.ToBrush(preset.Colors.SecondaryCardBackgroundHex),
            CornerRadius = new CornerRadius(5, 0, 0, 5),
            BorderBrush = ColorHexHelper.ToBrush(preset.Colors.BorderHex),
            BorderThickness = new Thickness(0, 0, 1, 0)
        };
        var sidebarDot = new Ellipse
        {
            Width = 6,
            Height = 6,
            Fill = ColorHexHelper.ToBrush(preset.Colors.AccentGoldHex),
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Top,
            Margin = new Thickness(0, 6, 0, 0)
        };
        var sidebarGrid = new Grid();
        sidebarGrid.Children.Add(sidebarDot);
        miniSidebar.Child = sidebarGrid;
        Grid.SetColumn(miniSidebar, 0);
        grid.Children.Add(miniSidebar);

        var workspace = new Grid { Padding = new Thickness(6, 4, 6, 4) };
        var miniCard = new Border
        {
            Background = ColorHexHelper.ToBrush(preset.Colors.CardBackgroundHex),
            BorderBrush = ColorHexHelper.ToBrush(preset.Colors.BorderHex),
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(4),
            Padding = new Thickness(6, 4, 6, 4)
        };

        var cardContent = new StackPanel { Spacing = 4, VerticalAlignment = VerticalAlignment.Center };
        var lineRow = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 4 };
        lineRow.Children.Add(new Border
        {
            Width = 28,
            Height = 4,
            CornerRadius = new CornerRadius(2),
            Background = ColorHexHelper.ToBrush(preset.Colors.AccentGoldHex)
        });
        lineRow.Children.Add(new Border
        {
            Width = 8,
            Height = 4,
            CornerRadius = new CornerRadius(2),
            Background = ColorHexHelper.ToBrush(preset.Colors.AccentCyanHex)
        });
        cardContent.Children.Add(lineRow);

        cardContent.Children.Add(new Border
        {
            Width = 42,
            Height = 3,
            CornerRadius = new CornerRadius(1.5),
            Background = new SolidColorBrush(Color.FromArgb(90, 255, 255, 255)),
            HorizontalAlignment = HorizontalAlignment.Left
        });

        miniCard.Child = cardContent;
        workspace.Children.Add(miniCard);
        Grid.SetColumn(workspace, 1);
        grid.Children.Add(workspace);

        banner.Child = grid;
        return banner;
    }

    private static Border CreatePaletteRibbon(AppThemeConfig preset)
    {
        var ribbon = new Border
        {
            Height = 4,
            CornerRadius = new CornerRadius(2),
            Margin = new Thickness(0, -2, 0, 0)
        };

        var grid = new Grid();
        for (int i = 0; i < 5; i++)
        {
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        }

        string[] colors =
        {
            preset.Colors.BackgroundHex,
            preset.Colors.CardBackgroundHex,
            preset.Colors.AccentGoldHex,
            preset.Colors.AccentCyanHex,
            preset.Colors.BorderHex
        };

        for (int i = 0; i < 5; i++)
        {
            var cell = new Border
            {
                Background = ColorHexHelper.ToBrush(colors[i])
            };
            Grid.SetColumn(cell, i);
            grid.Children.Add(cell);
        }

        ribbon.Child = grid;
        return ribbon;
    }

    private static FrameworkElement CreateColorSwatchCircle(string hex, string tooltipText)
    {
        var circle = new Ellipse
        {
            Width = 16,
            Height = 16,
            Fill = ColorHexHelper.ToBrush(hex),
            Stroke = new SolidColorBrush(Color.FromArgb(70, 255, 255, 255)),
            StrokeThickness = 1
        };

        ToolTipService.SetToolTip(circle, $"{tooltipText} : {hex.ToUpperInvariant()}");
        return circle;
    }

    private static string GetPresetEmojiOrGlyph(string name)
    {
        return name switch
        {
            "Overnode Original" => "👑",
            "Cyberpunk Neon" => "⚡",
            "Midnight OLED" => "🌙",
            "Emerald Matrix" => "🌿",
            "Crimson Velvet" => "🍷",
            "Sapphire Abyss" => "💎",
            "Nord Frost" => "❄️",
            "Amethyst Dream" => "🔮",
            "Sunset Horizon" => "🌅",
            _ => "🎨"
        };
    }

    // MARK: - 2. Custom Colors Section
    private void PopulateColorsUI()
    {
        var c = _themeManager.CurrentConfig.Colors;

        SetupColorCard(ColorCardAccentGold, _loc.GetString("godpack_color_accent_gold"), c.AccentGoldHex, hex =>
        {
            _themeManager.UpdateColors(tc => tc.AccentGoldHex = hex);
        });

        SetupColorCard(ColorCardBackground, _loc.GetString("godpack_color_background"), c.BackgroundHex, hex =>
        {
            _themeManager.UpdateColors(tc => tc.BackgroundHex = hex);
        });

        SetupColorCard(ColorCardCardBg, _loc.GetString("godpack_color_card_bg"), c.CardBackgroundHex, hex =>
        {
            _themeManager.UpdateColors(tc => tc.CardBackgroundHex = hex);
        });

        SetupColorCard(ColorCardSecCardBg, _loc.GetString("godpack_color_card_secondary"), c.SecondaryCardBackgroundHex, hex =>
        {
            _themeManager.UpdateColors(tc => tc.SecondaryCardBackgroundHex = hex);
        });

        SetupColorCard(ColorCardTextPrimary, _loc.GetString("godpack_color_text_primary"), c.TextPrimaryHex, hex =>
        {
            _themeManager.UpdateColors(tc => tc.TextPrimaryHex = hex);
        });

        SetupColorCard(ColorCardTextSecondary, _loc.GetString("godpack_color_text_secondary"), c.TextSecondaryHex, hex =>
        {
            _themeManager.UpdateColors(tc => tc.TextSecondaryHex = hex);
        });

        SetupColorCard(ColorCardBorder, _loc.GetString("godpack_color_border"), c.BorderHex, hex =>
        {
            _themeManager.UpdateColors(tc => tc.BorderHex = hex);
        });

        SetupColorCard(ColorCardAccentCyan, _loc.GetString("godpack_color_accent_cyan"), c.AccentCyanHex, hex =>
        {
            _themeManager.UpdateColors(tc => tc.AccentCyanHex = hex);
        });
    }

    private void SetupColorCard(Border card, string label, string hex, Action<string> onColorChanged)
    {
        var grid = new Grid();
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        var textStack = new StackPanel { Spacing = 2, VerticalAlignment = VerticalAlignment.Center };
        textStack.Children.Add(new TextBlock
        {
            Text = label,
            FontSize = 12,
            FontWeight = Microsoft.UI.Text.FontWeights.Medium,
            Foreground = (Brush)Application.Current.Resources["OvernodeTextPrimaryBrush"]
        });
        textStack.Children.Add(new TextBlock
        {
            Text = hex.ToUpperInvariant(),
            FontSize = 10.5,
            FontFamily = new FontFamily("Consolas, Segoe UI"),
            Foreground = (Brush)Application.Current.Resources["OvernodeTextMutedBrush"]
        });
        Grid.SetColumn(textStack, 0);
        grid.Children.Add(textStack);

        // Color preview button with flyout color picker
        var previewBtn = new Button
        {
            Width = 28,
            Height = 28,
            Padding = new Thickness(0),
            CornerRadius = new CornerRadius(14),
            Background = ColorHexHelper.ToBrush(hex),
            BorderBrush = new SolidColorBrush(Color.FromArgb(80, 255, 255, 255)),
            BorderThickness = new Thickness(1),
            VerticalAlignment = VerticalAlignment.Center
        };

        var flyout = new Flyout();
        var picker = new ColorPicker
        {
            Color = ColorHexHelper.FromHex(hex),
            IsAlphaEnabled = false,
            IsMoreButtonVisible = false,
            IsHexInputVisible = true
        };

        picker.ColorChanged += (_, args) =>
        {
            string newHex = ColorHexHelper.ToHex(args.NewColor);
            previewBtn.Background = new SolidColorBrush(args.NewColor);
            onColorChanged(newHex);
            PopulatePresetsUI();
        };

        flyout.Content = picker;
        previewBtn.Flyout = flyout;

        Grid.SetColumn(previewBtn, 1);
        grid.Children.Add(previewBtn);

        card.Child = grid;
    }

    // MARK: - 3. Background Section
    private void RefreshCustomizerFields()
    {
        var cfg = _themeManager.CurrentConfig;

        BgUrlInput.Text = cfg.BackgroundImageUrl ?? string.Empty;
        BgLocalPathPreviewText.Text = !string.IsNullOrEmpty(cfg.BackgroundLocalPath) ? System.IO.Path.GetFileName(cfg.BackgroundLocalPath) : string.Empty;

        BgOpacitySlider.Value = Math.Round(cfg.BackgroundOpacity * 100);
        BgOpacityValueText.Text = $"{(int)BgOpacitySlider.Value}%";

        BgBlurSlider.Value = Math.Round(cfg.BackgroundBlur);
        BgBlurValueText.Text = $"{(int)BgBlurSlider.Value} px";

        BgDarknessSlider.Value = Math.Round(cfg.BackgroundOverlayDarkness * 100);
        BgDarknessValueText.Text = $"{(int)BgDarknessSlider.Value}%";

        CardRadiusSlider.Value = cfg.CardCornerRadius;
        CardRadiusValueText.Text = $"{(int)cfg.CardCornerRadius} px";

        UpdateSidebarButtonsUI();
        UpdateBackgroundPreview();
        SelectLandingTabInCombo(cfg.LandingTab);
    }

    private void UpdateBackgroundPreview()
    {
        if (_themeManager.BackgroundBitmap != null)
        {
            BgThumbnailImage.Source = _themeManager.BackgroundBitmap;
            BgPreviewCard.Visibility = Visibility.Visible;
            BgResolutionText.Text = $"{_themeManager.BackgroundBitmap.PixelWidth} × {_themeManager.BackgroundBitmap.PixelHeight} px";
        }
        else
        {
            BgPreviewCard.Visibility = Visibility.Collapsed;
        }

        BgDownloadRing.Visibility = _themeManager.IsDownloadingBackground ? Visibility.Visible : Visibility.Collapsed;
        BgApplyUrlBtn.IsEnabled = !_themeManager.IsDownloadingBackground;
    }

    private void OnApplyBgUrlClicked(object sender, RoutedEventArgs e)
    {
        string trimmed = BgUrlInput.Text.Trim();
        if (string.IsNullOrEmpty(trimmed))
        {
            ShowError(_loc.GetString("godpack_bg_empty_url_err"));
            return;
        }

        _themeManager.UpdateBackground(trimmed, null);
        ShowSuccess(_loc.GetString("godpack_bg_applied_alert"));
    }

    private void OnClearBgClicked(object sender, RoutedEventArgs e)
    {
        BgUrlInput.Text = string.Empty;
        BgLocalPathPreviewText.Text = string.Empty;
        _themeManager.UpdateBackground(null, null);
        ShowSuccess(_loc.GetString("godpack_bg_cleared_alert"));
    }

    private async void OnChooseLocalBgFileClicked(object sender, RoutedEventArgs e)
    {
        string? path = await WindowsPickerHelper.PickImageFileAsync();
        if (!string.IsNullOrEmpty(path))
        {
            BgUrlInput.Text = string.Empty;
            BgLocalPathPreviewText.Text = System.IO.Path.GetFileName(path);
            _themeManager.UpdateBackground(null, path);
            ShowSuccess(_loc.GetString("godpack_bg_applied_alert"));
        }
    }

    private void OnBgOpacitySliderChanged(object sender, Microsoft.UI.Xaml.Controls.Primitives.RangeBaseValueChangedEventArgs e)
    {
        if (BgOpacityValueText == null) return;
        BgOpacityValueText.Text = $"{(int)e.NewValue}%";
        _themeManager.UpdateBackground(
            _themeManager.CurrentConfig.BackgroundImageUrl,
            _themeManager.CurrentConfig.BackgroundLocalPath,
            opacity: e.NewValue / 100.0);
    }

    private void OnBgBlurSliderChanged(object sender, Microsoft.UI.Xaml.Controls.Primitives.RangeBaseValueChangedEventArgs e)
    {
        if (BgBlurValueText == null) return;
        BgBlurValueText.Text = $"{(int)e.NewValue} px";
        _themeManager.UpdateBackground(
            _themeManager.CurrentConfig.BackgroundImageUrl,
            _themeManager.CurrentConfig.BackgroundLocalPath,
            blur: e.NewValue);
    }

    private void OnBgDarknessSliderChanged(object sender, Microsoft.UI.Xaml.Controls.Primitives.RangeBaseValueChangedEventArgs e)
    {
        if (BgDarknessValueText == null) return;
        BgDarknessValueText.Text = $"{(int)e.NewValue}%";
        _themeManager.UpdateBackground(
            _themeManager.CurrentConfig.BackgroundImageUrl,
            _themeManager.CurrentConfig.BackgroundLocalPath,
            darkness: e.NewValue / 100.0);
    }

    // MARK: - 4. Layout Section
    private void PopulateLandingTabsCombo()
    {
        if (LandingTabComboBox == null) return;

        LandingTabComboBox.SelectionChanged -= OnLandingTabSelectionChanged;
        LandingTabComboBox.Items.Clear();

        LandingTabComboBox.Items.Add(new ComboBoxItem { Content = _loc.GetString("godpack_landing_tab_dashboard"), Tag = "dashboard" });
        LandingTabComboBox.Items.Add(new ComboBoxItem { Content = _loc.GetString("godpack_landing_tab_servers"), Tag = "servers" });
        LandingTabComboBox.Items.Add(new ComboBoxItem { Content = _loc.GetString("godpack_landing_tab_wallet"), Tag = "wallet" });
        LandingTabComboBox.Items.Add(new ComboBoxItem { Content = _loc.GetString("godpack_landing_tab_daily_reward"), Tag = "daily_reward" });
        LandingTabComboBox.Items.Add(new ComboBoxItem { Content = _loc.GetString("godpack_landing_tab_store"), Tag = "store" });
        LandingTabComboBox.Items.Add(new ComboBoxItem { Content = _loc.GetString("godpack_landing_tab_support"), Tag = "support" });
        LandingTabComboBox.Items.Add(new ComboBoxItem { Content = _loc.GetString("godpack_landing_tab_afk"), Tag = "afk" });
        LandingTabComboBox.Items.Add(new ComboBoxItem { Content = _loc.GetString("godpack_landing_tab_settings"), Tag = "settings" });

        SelectLandingTabInCombo(_themeManager.CurrentConfig.LandingTab);
        LandingTabComboBox.SelectionChanged += OnLandingTabSelectionChanged;
    }

    private void SelectLandingTabInCombo(string targetTag)
    {
        if (LandingTabComboBox == null) return;
        foreach (ComboBoxItem item in LandingTabComboBox.Items)
        {
            if (item.Tag is string tag && string.Equals(tag, targetTag, StringComparison.OrdinalIgnoreCase))
            {
                LandingTabComboBox.SelectedItem = item;
                break;
            }
        }
    }

    private void OnLandingTabSelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (LandingTabComboBox.SelectedItem is ComboBoxItem item && item.Tag is string tag)
        {
            _themeManager.UpdateLandingTab(tag);
        }
    }

    private void OnSidebarLeftClicked(object sender, RoutedEventArgs e)
    {
        _themeManager.UpdateSidebarPosition(SidebarPosition.Left);
        UpdateSidebarButtonsUI();
    }

    private void OnSidebarRightClicked(object sender, RoutedEventArgs e)
    {
        _themeManager.UpdateSidebarPosition(SidebarPosition.Right);
        UpdateSidebarButtonsUI();
    }

    private void UpdateSidebarButtonsUI()
    {
        bool isLeft = _themeManager.CurrentConfig.SidebarPosition == SidebarPosition.Left;
        var goldBrush = (Brush)Application.Current.Resources["OvernodeAccentGoldBrush"];
        var subtleBorderBrush = (Brush)Application.Current.Resources["OvernodeBorderSubtleBrush"];
        var activeBgBrush = new SolidColorBrush(Color.FromArgb(46, 245, 158, 11));
        var transparentBrush = new SolidColorBrush(Colors.Transparent);

        SidebarLeftBtn.Background = isLeft ? activeBgBrush : transparentBrush;
        SidebarLeftBtn.BorderBrush = isLeft ? goldBrush : subtleBorderBrush;
        SidebarLeftBtn.Foreground = isLeft ? goldBrush : (Brush)Application.Current.Resources["OvernodeTextPrimaryBrush"];

        SidebarRightBtn.Background = !isLeft ? activeBgBrush : transparentBrush;
        SidebarRightBtn.BorderBrush = !isLeft ? goldBrush : subtleBorderBrush;
        SidebarRightBtn.Foreground = !isLeft ? goldBrush : (Brush)Application.Current.Resources["OvernodeTextPrimaryBrush"];
    }

    private void OnCardRadiusSliderChanged(object sender, Microsoft.UI.Xaml.Controls.Primitives.RangeBaseValueChangedEventArgs e)
    {
        if (CardRadiusValueText == null) return;
        CardRadiusValueText.Text = $"{(int)e.NewValue} px";
        _themeManager.UpdateCornerRadius(e.NewValue);
    }

    // MARK: - 5. Share Section (Export & Import)
    private async void OnExportConfigClicked(object sender, RoutedEventArgs e)
    {
        try
        {
            string? destination = await WindowsPickerHelper.PickSaveConfigFileAsync("config.overnode.app");
            if (!string.IsNullOrEmpty(destination))
            {
                _themeManager.ExportConfiguration(destination);
                ShowSuccess(_loc.GetString("godpack_export_success_alert"));
            }
        }
        catch (Exception ex)
        {
            ShowError(_loc.Format("godpack_export_error_alert", ex.Message));
        }
    }

    private async void OnImportConfigClicked(object sender, RoutedEventArgs e)
    {
        try
        {
            string? source = await WindowsPickerHelper.PickConfigFileAsync();
            if (!string.IsNullOrEmpty(source))
            {
                _themeManager.ImportConfiguration(source);
                RefreshCustomizerFields();
                PopulatePresetsUI();
                PopulateColorsUI();
                ShowSuccess(_loc.GetString("godpack_import_success_alert"));
            }
        }
        catch (Exception ex)
        {
            ShowError(_loc.Format("godpack_import_error_alert", ex.Message));
        }
    }

    private void OnResetConfigClicked(object sender, RoutedEventArgs e)
    {
        _themeManager.ResetToDefault();
        RefreshCustomizerFields();
        PopulatePresetsUI();
        PopulateColorsUI();
        ShowSuccess(_loc.GetString("godpack_reset_success_alert"));
    }
}
