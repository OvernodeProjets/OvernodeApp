using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using Overnode.App.Models;
using Overnode.App.Services;

namespace Overnode.App.ViewModels;

public enum WalletTab
{
    Overview,
    Leaderboard,
    Activity
}

public partial class WalletViewModel : ObservableObject
{
    private readonly BillingService _service = BillingService.Instance;

    [ObservableProperty]
    private BillingInfo? _billingInfo;

    [ObservableProperty]
    private LeaderboardResponse? _leaderboard;

    [ObservableProperty]
    private List<BillingTransaction> _transactions = new();

    [ObservableProperty]
    private WalletTab _selectedTab = WalletTab.Overview;

    [ObservableProperty]
    private bool _isLoading;

    [ObservableProperty]
    private string? _errorMessage;

    public WalletViewModel() { }

    public async Task LoadDataAsync()
    {
        IsLoading = true;
        ErrorMessage = null;

        try
        {
            var billingTask = _service.FetchBillingInfoAsync();
            var leaderboardTask = _service.FetchLeaderboardAsync();
            var txTask = _service.FetchTransactionsAsync();

            await Task.WhenAll(billingTask, leaderboardTask, txTask);

            BillingInfo = await billingTask;
            Leaderboard = await leaderboardTask;
            Transactions = await txTask;
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

    public void OpenAddFunds()
    {
        _service.OpenAddFundsWeb();
    }

    public void PurchaseCoinsPackage(int amount)
    {
        _service.OpenPurchaseCoinsWeb();
    }
}
