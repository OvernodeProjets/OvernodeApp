using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
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

    public List<StoreBundle> Bundles { get; } = new()
    {
        new(
            "auto_renew",
            "Auto-Renouvellement",
            "2,99 €",
            "/ mois",
            "Renouvelez automatiquement vos serveurs actifs sans interruption de service.",
            new() { "Renouvellement automatique 24/7", "Zéro suspension inattendue", "Rappels par email", "Annulable à tout moment" },
            "\uE72C", // Refresh
            "#22C55E" // Green
        ),
        new(
            "starter_cloud",
            "Pack Starter Cloud",
            "4,99 €",
            "/ mois",
            "Idéal pour héberger vos premiers serveurs de jeu ou bots Discord.",
            new() { "+2 Go RAM supplémentaires", "+10 Go Disque NVMe", "+100% CPU", "+1 slot de serveur" },
            "\uE753", // Cloud
            "#3B82F6" // Blue
        ),
        new(
            "pro_performance",
            "Pack Pro Performance",
            "9,99 €",
            "/ mois",
            "Pour les communautés actives et serveurs de jeu haute fréquence.",
            new() { "+6 Go RAM supplémentaires", "+30 Go Disque NVMe", "+300% CPU", "+3 slots de serveurs", "Priorité Anti-DDoS Game" },
            "\uE735", // Star
            "#F59E0B" // Gold
        )
    };

    public StoreViewModel() { }

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
                SuccessMessage = $"Achat de {resourceType.ToUpperInvariant()} effectué avec succès !";
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
