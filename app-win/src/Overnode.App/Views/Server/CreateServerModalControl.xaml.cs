using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.ViewModels;

namespace Overnode.App.Views.Server;

public sealed partial class CreateServerModalControl : UserControl
{
    private readonly LocalizationManager _loc = LocalizationManager.Instance;
    private bool _isUpdatingSliders;

    public CreateServerViewModel ViewModel { get; } = new();

    public event Action? Dismissed;
    public event Action<ServerInstance>? ServerCreated;

    public CreateServerModalControl()
    {
        InitializeComponent();
        ViewModel.PropertyChanged += (_, _) => UpdateUI();
    }

    public async Task InitializeAsync()
    {
        UpdateLocalizedStrings();
        await ViewModel.LoadOptionsAsync();

        var testName = Environment.GetEnvironmentVariable("OVERNODE_TEST_CREATE_NAME");
        if (!string.IsNullOrEmpty(testName))
        {
            ServerNameInput.Text = testName;
            ViewModel.ServerName = testName;
        }

        UpdateUI();

        if (Environment.GetEnvironmentVariable("OVERNODE_TEST_CREATE_SCROLL") == "1")
        {
            _ = Task.Run(async () =>
            {
                await Task.Delay(400);
                DispatcherQueue.TryEnqueue(() =>
                {
                    ModalScrollViewer.ChangeView(null, 600, null, true);
                });
            });
        }
    }

    private void UpdateLocalizedStrings()
    {
        ModalTitleText.Text = _loc.GetString("create_server_title");
        ModalSubtitleText.Text = _loc.GetString("create_server_subtitle");
        LoadingText.Text = _loc.GetString("create_server_loading");
        QuotaExceededTitleText.Text = _loc.GetString("create_server_quota_exceeded");
        QuotaExceededDescText.Text = _loc.GetString("create_server_quota_exceeded_desc");
        ServerNameLabel.Text = _loc.GetString("create_server_name_label");
        ServerNameInput.PlaceholderText = _loc.GetString("create_server_name_placeholder");
        LocationLabel.Text = _loc.GetString("create_server_location_label");
        LocationSubtitle.Text = _loc.GetString("create_server_location_subtitle");
        NodeSelectionLabel.Text = _loc.GetString("create_server_node_selection_title");
        SoftwareLabel.Text = _loc.GetString("create_server_software_label");
        SoftwareSubtitle.Text = _loc.GetString("create_server_software_subtitle");
        ResourcesLabel.Text = _loc.GetString("create_server_resources_title");
        ResourcesSubtitle.Text = _loc.GetString("create_server_resources_subtitle");
        RamLabel.Text = _loc.GetString("resource_ram");
        CpuLabel.Text = _loc.GetString("resource_cpu");
        DiskLabel.Text = _loc.GetString("resource_disk");
        CancelButton.Content = _loc.GetString("btn_cancel");
        DeployButtonText.Text = _loc.GetString("create_server_action_deploy");
    }

    private void UpdateUI()
    {
        LoadingPanel.Visibility = ViewModel.IsLoading ? Visibility.Visible : Visibility.Collapsed;
        ContentPanel.Visibility = ViewModel.IsLoading ? Visibility.Collapsed : Visibility.Visible;

        if (ViewModel.IsLoading) return;

        UpdateQuotaBanner();
        UpdateNameValidation();
        UpdateLocations();
        UpdateNodes();
        UpdateCategories();
        UpdateEggs();
        UpdateSliders();
        UpdateSummaryAndActions();
    }

    private void UpdateQuotaBanner()
    {
        int remServers = ViewModel.Options?.Resources.Remaining.Servers ?? 1;
        QuotaAlertBanner.Visibility = remServers <= 0 ? Visibility.Visible : Visibility.Collapsed;
    }

    private void UpdateNameValidation()
    {
        string trimmed = ViewModel.ServerName.Trim();
        if (string.IsNullOrEmpty(trimmed))
        {
            NameStatusPanel.Visibility = Visibility.Collapsed;
        }
        else if (ViewModel.IsNameValid)
        {
            NameStatusPanel.Visibility = Visibility.Visible;
            NameStatusIcon.Glyph = "\uE73E"; // Checkmark
            NameStatusIcon.Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeAccentSuccessBrush"];
            NameStatusText.Text = _loc.GetString("create_server_name_valid");
            NameStatusText.Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeAccentSuccessBrush"];
        }
        else
        {
            NameStatusPanel.Visibility = Visibility.Visible;
            NameStatusIcon.Glyph = "\uE7BA"; // Warning
            NameStatusIcon.Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeAccentDangerBrush"];
            NameStatusText.Text = _loc.GetString("create_server_name_invalid_chars");
            NameStatusText.Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeAccentDangerBrush"];
        }
    }

    private void UpdateLocations()
    {
        if (ViewModel.Options == null) return;

        var locs = ViewModel.Options.Locations;
        LocationsList.ItemsSource = locs.Select(loc => CreateLocationCard(loc)).ToList();
    }

    private FrameworkElement CreateLocationCard(ServerLocation loc)
    {
        bool isSelected = ViewModel.SelectedLocation?.Id == loc.Id;
        var info = LocationHelper.Format(loc);

        var border = new Border
        {
            Background = isSelected ? new SolidColorBrush(ColorHelper.FromArgb(30, 245, 158, 11)) : (SolidColorBrush)Application.Current.Resources["OvernodeSecondaryCardBrush"],
            BorderBrush = isSelected ? (SolidColorBrush)Application.Current.Resources["OvernodeAccentGoldBrush"] : (SolidColorBrush)Application.Current.Resources["OvernodeBorderSubtleBrush"],
            BorderThickness = new Thickness(isSelected ? 1.5 : 1),
            CornerRadius = new CornerRadius(10),
            Padding = new Thickness(12),
            Margin = new Thickness(4),
            Opacity = loc.Full ? 0.5 : 1.0
        };

        var grid = new Grid { ColumnSpacing = 10 };
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        var flagText = new TextBlock { Text = info.Flag, FontSize = 22, VerticalAlignment = VerticalAlignment.Center };
        Grid.SetColumn(flagText, 0);
        grid.Children.Add(flagText);

        var infoStack = new StackPanel { Spacing = 2, VerticalAlignment = VerticalAlignment.Center };
        var titleRow = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6 };
        titleRow.Children.Add(new TextBlock { Text = info.CountryName, FontWeight = Microsoft.UI.Text.FontWeights.SemiBold, FontSize = 13, Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"] });

        if (loc.Full)
        {
            titleRow.Children.Add(new TextBlock { Text = _loc.GetString("create_server_location_status_full"), FontSize = 9, FontWeight = Microsoft.UI.Text.FontWeights.Bold, Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeAccentDangerBrush"] });
        }
        else
        {
            titleRow.Children.Add(new TextBlock { Text = info.PingText, FontSize = 10, FontFamily = new FontFamily("Consolas"), Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeAccentSuccessBrush"] });
        }
        infoStack.Children.Add(titleRow);
        infoStack.Children.Add(new TextBlock { Text = info.RegionName, FontSize = 10.5, Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"], TextTrimming = TextTrimming.CharacterEllipsis });
        Grid.SetColumn(infoStack, 1);
        grid.Children.Add(infoStack);

        if (isSelected)
        {
            var checkBadge = new Border
            {
                Width = 18, Height = 18, CornerRadius = new CornerRadius(9),
                Background = (SolidColorBrush)Application.Current.Resources["OvernodeAccentGoldBrush"],
                Child = new FontIcon { Glyph = "\uE73E", FontSize = 10, Foreground = new SolidColorBrush(Colors.Black), FontWeight = Microsoft.UI.Text.FontWeights.Bold }
            };
            Grid.SetColumn(checkBadge, 2);
            grid.Children.Add(checkBadge);
        }

        var btn = new Button
        {
            Content = grid,
            Background = new SolidColorBrush(Colors.Transparent),
            BorderThickness = new Thickness(0),
            Padding = new Thickness(0),
            HorizontalAlignment = HorizontalAlignment.Stretch,
            HorizontalContentAlignment = HorizontalAlignment.Stretch,
            IsEnabled = !loc.Full
        };
        btn.Click += (_, _) => ViewModel.SelectLocation(loc);
        border.Child = btn;
        return border;
    }

    private void UpdateNodes()
    {
        NodesChipsPanel.Children.Clear();
        var nodes = ViewModel.AvailableNodes;
        if (nodes.Count == 0)
        {
            NodesSection.Visibility = Visibility.Collapsed;
            return;
        }

        NodesSection.Visibility = Visibility.Visible;
        foreach (var node in nodes)
        {
            bool isSelected = ViewModel.EffectiveNode?.Id == node.Id;
            var nodeInfo = LocationHelper.Format(node);

            var chip = new Button
            {
                Padding = new Thickness(10, 5, 10, 5),
                CornerRadius = new CornerRadius(6),
                Background = isSelected ? new SolidColorBrush(ColorHelper.FromArgb(40, 245, 158, 11)) : new SolidColorBrush(ColorHelper.FromArgb(16, 255, 255, 255)),
                BorderBrush = isSelected ? (SolidColorBrush)Application.Current.Resources["OvernodeAccentGoldBrush"] : (SolidColorBrush)Application.Current.Resources["OvernodeBorderSubtleBrush"],
                BorderThickness = new Thickness(1)
            };

            var stack = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6 };
            stack.Children.Add(new FontIcon { Glyph = "\uE945", FontSize = 11, Foreground = isSelected ? (SolidColorBrush)Application.Current.Resources["OvernodeAccentGoldBrush"] : (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"] });
            stack.Children.Add(new TextBlock { Text = nodeInfo.DisplayName, FontSize = 11, FontFamily = new FontFamily("Consolas"), FontWeight = isSelected ? Microsoft.UI.Text.FontWeights.SemiBold : Microsoft.UI.Text.FontWeights.Normal, Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextPrimaryBrush"] });
            stack.Children.Add(new TextBlock { Text = $"({nodeInfo.City})", FontSize = 10, Foreground = (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"] });

            chip.Content = stack;
            chip.Click += (_, _) => ViewModel.SelectedNode = node;
            NodesChipsPanel.Children.Add(chip);
        }
    }

    private void UpdateCategories()
    {
        CategoriesPanel.Children.Clear();
        if (ViewModel.Options == null) return;

        foreach (var cat in ViewModel.Options.Categories)
        {
            bool isSelected = string.Equals(ViewModel.SelectedCategory, cat.Id, StringComparison.OrdinalIgnoreCase);

            var btn = new Button
            {
                Padding = new Thickness(12, 6, 12, 6),
                CornerRadius = new CornerRadius(8),
                Background = isSelected ? new SolidColorBrush(ColorHelper.FromArgb(40, 245, 158, 11)) : (SolidColorBrush)Application.Current.Resources["OvernodeSecondaryCardBrush"],
                BorderBrush = isSelected ? (SolidColorBrush)Application.Current.Resources["OvernodeAccentGoldBrush"] : (SolidColorBrush)Application.Current.Resources["OvernodeBorderSubtleBrush"],
                BorderThickness = new Thickness(1)
            };

            var stack = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6 };
            stack.Children.Add(new FontIcon { Glyph = cat.IconGlyph, FontSize = 11, Foreground = isSelected ? (SolidColorBrush)Application.Current.Resources["OvernodeAccentGoldBrush"] : (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"] });
            stack.Children.Add(new TextBlock { Text = cat.Name, FontSize = 11.5, FontWeight = isSelected ? Microsoft.UI.Text.FontWeights.SemiBold : Microsoft.UI.Text.FontWeights.Normal, Foreground = isSelected ? (SolidColorBrush)Application.Current.Resources["OvernodeAccentGoldBrush"] : (SolidColorBrush)Application.Current.Resources["OvernodeTextSecondaryBrush"] });

            btn.Content = stack;
            btn.Click += (_, _) => ViewModel.SelectedCategory = cat.Id;
            CategoriesPanel.Children.Add(btn);
        }
    }

    private void UpdateEggs()
    {
        var eggs = ViewModel.FilteredEggs;
        EggsList.ItemsSource = eggs.Select(egg =>
        {
            var card = new CreateServerEggCardControl
            {
                Egg = egg,
                IsSelected = ViewModel.SelectedEgg?.Id == egg.Id,
                Margin = new Thickness(4)
            };
            card.EggSelected += selected => ViewModel.SelectEgg(selected);
            return card;
        }).ToList();
    }

    private void UpdateSliders()
    {
        if (ViewModel.Options == null) return;
        _isUpdatingSliders = true;

        var rem = ViewModel.Options.Resources.Remaining;
        double minRam = Math.Max(128.0, ViewModel.SelectedEgg?.Minimum.Ram ?? 128.0);
        double minCpu = Math.Max(10.0, ViewModel.SelectedEgg?.Minimum.Cpu ?? 10.0);
        double minDisk = Math.Max(256.0, ViewModel.SelectedEgg?.Minimum.Disk ?? 256.0);

        // RAM
        RamSlider.Minimum = minRam;
        RamSlider.Maximum = Math.Max(minRam + 256, rem.Ram);
        RamSlider.Value = ViewModel.RamMB;
        RamValueText.Text = $"{ViewModel.RamMB:F0} MB";
        RamRemainingText.Text = $"({_loc.GetString("create_server_remaining")}: {rem.Ram:F0} MB)";
        SetupPresets(RamPresetsPanel, new() { (_loc.GetString("create_server_preset_min"), minRam), ("1 GB", 1024), ("2 GB", 2048), ("4 GB", 4096), (_loc.GetString("create_server_preset_max"), rem.Ram) }, minRam, rem.Ram, ViewModel.RamMB, val => ViewModel.RamMB = val);

        // CPU
        CpuSlider.Minimum = minCpu;
        CpuSlider.Maximum = Math.Max(minCpu + 25, rem.Cpu);
        CpuSlider.Value = ViewModel.CpuPercent;
        CpuValueText.Text = $"{ViewModel.CpuPercent:F0}%";
        CpuRemainingText.Text = $"({_loc.GetString("create_server_remaining")}: {rem.Cpu:F0}%)";
        SetupPresets(CpuPresetsPanel, new() { (_loc.GetString("create_server_preset_min"), minCpu), ("50%", 50), ("100%", 100), ("200%", 200), (_loc.GetString("create_server_preset_max"), rem.Cpu) }, minCpu, rem.Cpu, ViewModel.CpuPercent, val => ViewModel.CpuPercent = val);

        // Disk
        DiskSlider.Minimum = minDisk;
        DiskSlider.Maximum = Math.Max(minDisk + 512, rem.Disk);
        DiskSlider.Value = ViewModel.DiskMB;
        DiskValueText.Text = $"{ViewModel.DiskMB:F0} MB";
        DiskRemainingText.Text = $"({_loc.GetString("create_server_remaining")}: {rem.Disk:F0} MB)";
        SetupPresets(DiskPresetsPanel, new() { (_loc.GetString("create_server_preset_min"), minDisk), ("2 GB", 2048), ("5 GB", 5120), ("10 GB", 10240), (_loc.GetString("create_server_preset_max"), rem.Disk) }, minDisk, rem.Disk, ViewModel.DiskMB, val => ViewModel.DiskMB = val);

        _isUpdatingSliders = false;
    }

    private void SetupPresets(StackPanel panel, System.Collections.Generic.List<(string label, double value)> presets, double min, double max, double current, Action<double> onSelect)
    {
        panel.Children.Clear();
        foreach (var (label, val) in presets)
        {
            bool isAvailable = val >= min && val <= max;
            bool isCurrent = Math.Abs(current - val) < 5;

            var btn = new Button
            {
                Content = new TextBlock { Text = label, FontSize = 10, FontFamily = new FontFamily("Consolas"), FontWeight = isCurrent ? Microsoft.UI.Text.FontWeights.Bold : Microsoft.UI.Text.FontWeights.Normal },
                Padding = new Thickness(8, 2, 8, 2),
                CornerRadius = new CornerRadius(4),
                Background = isCurrent ? new SolidColorBrush(ColorHelper.FromArgb(40, 245, 158, 11)) : new SolidColorBrush(ColorHelper.FromArgb(10, 255, 255, 255)),
                BorderBrush = isCurrent ? (SolidColorBrush)Application.Current.Resources["OvernodeAccentGoldBrush"] : new SolidColorBrush(Colors.Transparent),
                BorderThickness = new Thickness(1),
                IsEnabled = isAvailable
            };
            btn.Click += (_, _) => onSelect(val);
            panel.Children.Add(btn);
        }
    }

    private void UpdateSummaryAndActions()
    {
        if (ViewModel.SelectedLocation != null)
        {
            var info = LocationHelper.Format(ViewModel.SelectedLocation);
            SummaryLocationText.Text = $"{info.Flag} {info.CountryName}";
        }

        if (ViewModel.SelectedEgg != null)
        {
            SummaryEggText.Text = ViewModel.SelectedEgg.Name;
        }

        int remServers = ViewModel.Options?.Resources.Remaining.Servers ?? 0;
        SummaryServersText.Text = $"{_loc.GetString("create_server_servers_remaining")} : {remServers}";

        DeployButton.IsEnabled = ViewModel.CanDeploy && !ViewModel.IsDeploying;
        DeploySpinner.Visibility = ViewModel.IsDeploying ? Visibility.Visible : Visibility.Collapsed;
        DeployIcon.Visibility = ViewModel.IsDeploying ? Visibility.Collapsed : Visibility.Visible;

        if (!string.IsNullOrEmpty(ViewModel.ErrorMessage))
        {
            ErrorBanner.Visibility = Visibility.Visible;
            ErrorBannerText.Text = ViewModel.ErrorMessage;
        }
        else
        {
            ErrorBanner.Visibility = Visibility.Collapsed;
        }
    }

    private void OnServerNameChanged(object sender, TextChangedEventArgs e)
    {
        ViewModel.ServerName = ServerNameInput.Text;
    }

    private void OnRamSliderChanged(object sender, Microsoft.UI.Xaml.Controls.Primitives.RangeBaseValueChangedEventArgs e)
    {
        if (!_isUpdatingSliders) ViewModel.RamMB = e.NewValue;
    }

    private void OnCpuSliderChanged(object sender, Microsoft.UI.Xaml.Controls.Primitives.RangeBaseValueChangedEventArgs e)
    {
        if (!_isUpdatingSliders) ViewModel.CpuPercent = e.NewValue;
    }

    private void OnDiskSliderChanged(object sender, Microsoft.UI.Xaml.Controls.Primitives.RangeBaseValueChangedEventArgs e)
    {
        if (!_isUpdatingSliders) ViewModel.DiskMB = e.NewValue;
    }

    private void OnCloseClicked(object sender, RoutedEventArgs e)
    {
        Dismissed?.Invoke();
    }

    private async void OnDeployClicked(object sender, RoutedEventArgs e)
    {
        var server = await ViewModel.DeployServerAsync();
        if (server != null)
        {
            ServerCreated?.Invoke(server);
        }
    }
}
