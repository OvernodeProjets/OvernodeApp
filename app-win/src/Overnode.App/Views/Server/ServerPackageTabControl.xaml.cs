using System;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Overnode.App.Localization;
using Overnode.App.ViewModels;

namespace Overnode.App.Views.Server;

public sealed partial class ServerPackageTabControl : UserControl
{
    public ServerDetailViewModel? ViewModel => DataContext as ServerDetailViewModel;

    private ServerDetailViewModel? _boundViewModel;

    public ServerPackageTabControl()
    {
        this.InitializeComponent();
        LocalizationManager.Instance.LanguageChanged += (s, e) => UpdateLocalization();
        DataContextChanged += OnDataContextChanged;
        Loaded += (s, e) => UpdateUI();
        UpdateLocalization();
    }

    private void OnDataContextChanged(FrameworkElement sender, DataContextChangedEventArgs args)
    {
        if (_boundViewModel != null)
        {
            _boundViewModel.PropertyChanged -= OnViewModelPropertyChanged;
        }

        _boundViewModel = DataContext as ServerDetailViewModel;
        if (_boundViewModel != null)
        {
            _boundViewModel.PropertyChanged += OnViewModelPropertyChanged;
        }

        UpdateUI();
    }

    private void OnViewModelPropertyChanged(object? sender, System.ComponentModel.PropertyChangedEventArgs e)
    {
        DispatcherQueue.TryEnqueue(() => UpdateUI());
    }

    private void UpdateLocalization()
    {
        var loc = LocalizationManager.Instance;
        PackageTitleText.Text = loc.GetString("package_title");
        PackageSubtitleText.Text = loc.GetString("package_subtitle");
        SetMaxButtonText.Text = loc.GetString("package_max_allowed");
        RamLabelText.Text = loc.GetString("resource_ram");
        CpuLabelText.Text = loc.GetString("resource_cpu");
        DiskLabelText.Text = loc.GetString("resource_disk");
        SaveButtonText.Text = loc.GetString("package_save_changes");
    }

    public void UpdateUI()
    {
        if (ViewModel == null) return;

        ViewModel.InitPackageResources();

        RamSlider.Maximum = Math.Max(ViewModel.MaxAvailableRamMB, 512);
        RamSlider.Value = ViewModel.PackageRamMB;
        RamValueText.Text = $"{(int)ViewModel.PackageRamMB} MB";

        CpuSlider.Maximum = Math.Max(ViewModel.MaxAvailableCpuPercent, 50);
        CpuSlider.Value = ViewModel.PackageCpuPercent;
        CpuValueText.Text = $"{(int)ViewModel.PackageCpuPercent} %";

        DiskSlider.Maximum = Math.Max(ViewModel.MaxAvailableDiskMB, 1024);
        DiskSlider.Value = ViewModel.PackageDiskMB;
        DiskValueText.Text = $"{(int)ViewModel.PackageDiskMB} MB";

        PackageProgressRing.IsActive = ViewModel.IsSavingPackage;
        PackageProgressRing.Visibility = ViewModel.IsSavingPackage ? Visibility.Visible : Visibility.Collapsed;
        PackageSaveIcon.Visibility = ViewModel.IsSavingPackage ? Visibility.Collapsed : Visibility.Visible;
        SavePackageButton.IsEnabled = !ViewModel.IsSavingPackage;

        if (!string.IsNullOrEmpty(ViewModel.SuccessMessage))
        {
            PackageSuccessText.Text = ViewModel.SuccessMessage;
            PackageSuccessBanner.Visibility = Visibility.Visible;
        }
        else
        {
            PackageSuccessBanner.Visibility = Visibility.Collapsed;
        }

        if (!string.IsNullOrEmpty(ViewModel.ErrorMessage))
        {
            PackageErrorText.Text = ViewModel.ErrorMessage;
            PackageErrorBanner.Visibility = Visibility.Visible;
        }
        else
        {
            PackageErrorBanner.Visibility = Visibility.Collapsed;
        }
    }

    private void OnRamSliderChanged(object sender, Microsoft.UI.Xaml.Controls.Primitives.RangeBaseValueChangedEventArgs e)
    {
        if (ViewModel != null)
        {
            ViewModel.PackageRamMB = e.NewValue;
            RamValueText.Text = $"{(int)e.NewValue} MB";
        }
    }

    private void OnCpuSliderChanged(object sender, Microsoft.UI.Xaml.Controls.Primitives.RangeBaseValueChangedEventArgs e)
    {
        if (ViewModel != null)
        {
            ViewModel.PackageCpuPercent = e.NewValue;
            CpuValueText.Text = $"{(int)e.NewValue} %";
        }
    }

    private void OnDiskSliderChanged(object sender, Microsoft.UI.Xaml.Controls.Primitives.RangeBaseValueChangedEventArgs e)
    {
        if (ViewModel != null)
        {
            ViewModel.PackageDiskMB = e.NewValue;
            DiskValueText.Text = $"{(int)e.NewValue} MB";
        }
    }

    private void OnSetMaxClicked(object sender, RoutedEventArgs e)
    {
        if (ViewModel != null)
        {
            ViewModel.SetMaxPackageResources();
            RamSlider.Value = ViewModel.PackageRamMB;
            CpuSlider.Value = ViewModel.PackageCpuPercent;
            DiskSlider.Value = ViewModel.PackageDiskMB;
            RamValueText.Text = $"{(int)ViewModel.PackageRamMB} MB";
            CpuValueText.Text = $"{(int)ViewModel.PackageCpuPercent} %";
            DiskValueText.Text = $"{(int)ViewModel.PackageDiskMB} MB";
        }
    }

    private async void OnSavePackageClicked(object sender, RoutedEventArgs e)
    {
        if (ViewModel != null)
        {
            await ViewModel.SavePackageChangesAsync();
            UpdateUI();
        }
    }
}
