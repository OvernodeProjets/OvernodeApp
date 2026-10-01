using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.Services;

namespace Overnode.App.ViewModels;

public enum StoreTab
{
    Resources,
    Bundles
}

public partial class StoreViewModel : ObservableObject
{
    private readonly StoreService _service = StoreService.Instance;

    [ObservableProperty]
    private StoreConfigResponse? _storeConfig;

    [ObservableProperty]
    private int _userCoins = 350;

    [ObservableProperty]
    private StoreTab _selectedTab = StoreTab.Resources;

    [ObservableProperty]
    private bool _isLoading;

    [ObservableProperty]
    private bool _isPurchasing;

    [ObservableProperty]
    private string? _errorMessage;

    [ObservableProperty]
    private string? _successMessage;

    public List<StoreBundle> Bundles { get; } = new();

    public StoreViewModel()
    {
        RefreshBundles();
    }

    public void RefreshBundles()
    {
        var loc = LocalizationManager.Instance;
        Bundles.Clear();

        string monthSuffix = loc.GetString("store_bundle_monthly");
        bool isEn = loc.CurrentLanguage == AppLanguage.En;

        Bundles.Add(new(
            "auto_renew",
            loc.GetString("store_bundle_auto_renew"),
            "2,99 €",
            monthSuffix,
            loc.GetString("bundle_auto_renew_desc"),
            new() { loc.GetString("bundle_auto_renew_f1"), loc.GetString("bundle_auto_renew_f2"), loc.GetString("bundle_auto_renew_f3") },
            "\uE72C", // Refresh
            "#22C55E" // Green
        ));

        Bundles.Add(new(
            "starter_cloud",
            isEn ? "Starter Cloud Pack" : "Pack Starter Cloud",
            "4,99 €",
            monthSuffix,
            loc.GetString("bundle_upgraded_desc"),
            new() { loc.GetString("bundle_upgraded_f1"), loc.GetString("bundle_upgraded_f2"), loc.GetString("bundle_upgraded_f3") },
            "\uE753", // Cloud
            "#3B82F6" // Blue
        ));

        Bundles.Add(new(
            "pro_performance",
            isEn ? "Pro Performance Pack" : "Pack Pro Performance",
            "9,99 €",
            monthSuffix,
            loc.GetString("bundle_god_desc"),
            new() { loc.GetString("bundle_god_f1"), loc.GetString("bundle_god_f2"), loc.GetString("bundle_god_f3") },
            "\uE735", // Star
            "#F59E0B" // Gold
        ));
    }

    public async Task LoadDataAsync()
    {
        IsLoading = true;
        ErrorMessage = null;
        try
        {
            var config = await _service.FetchStoreConfigAsync();
            StoreConfig = config;
            if (config.UserBalance.HasValue)
            {
                UserCoins = config.UserBalance.Value;
            }
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
        finally
        {
            IsLoading = false;
        }
    }

    public async Task<bool> BuyResourceAsync(string resourceType, int amount)
    {
        IsPurchasing = true;
        ErrorMessage = null;
        SuccessMessage = null;

        try
        {
            var res = await _service.BuyResourceAsync(resourceType, amount);
            if (res.Success)
            {
                SuccessMessage = string.Format(LocalizationManager.Instance.GetString("store_purchase_success"), resourceType.ToUpperInvariant());
                if (res.RemainingCoins.HasValue)
                {
                    UserCoins = res.RemainingCoins.Value;
                }
                return true;
            }
            return false;
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
            return false;
        }
        finally
        {
            IsPurchasing = false;
        }
    }

    public void SubscribeBundle(StoreBundle bundle)
    {
        _service.OpenSubscribeWeb();
    }
}
