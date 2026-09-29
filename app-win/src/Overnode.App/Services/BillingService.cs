using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading.Tasks;
using Overnode.App.Models;

namespace Overnode.App.Services;

public sealed class BillingService
{
    private static readonly Lazy<BillingService> _instance = new(() => new BillingService());
    public static BillingService Instance => _instance.Value;
    public static BillingService Shared => _instance.Value;

    private readonly APIClient _client = APIClient.Instance;

    private BillingService() { }

    public async Task<BillingInfo> FetchBillingInfoAsync()
    {
        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1")
        {
            return new BillingInfo
            {
                Balances = new BillingBalances(0.00, 350),
                Currency = "EUR",
                CoinPackages = new()
                {
                    new(1000, 1.79),
                    new(2500, 3.99),
                    new(5000, 5.99)
                }
            };
        }

        return await _client.GetAsync<BillingInfo>("/api/v5/billing/info");
    }

    public async Task<LeaderboardResponse> FetchLeaderboardAsync()
    {
        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1")
        {
            return new LeaderboardResponse
            {
                UserRank = new LeaderboardUserRank(42, "OvernodeUser", 350, false),
                Leaderboard = new()
                {
                    new(1, "OverMaster", 12500),
                    new(2, "CloudArchitect", 9820),
                    new(3, "VoxelHero", 7450),
                    new(4, "ByteCrafter", 6100),
                    new(5, "QuantumDev", 4890),
                    new(6, "PixelKnight", 3920),
                    new(7, "AeroNova", 2850),
                    new(8, "ShadowFox", 2100)
                }
            };
        }

        return await _client.GetAsync<LeaderboardResponse>("/api/v5/billing/leaderboard");
    }

    public async Task<List<BillingTransaction>> FetchTransactionsAsync()
    {
        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1")
        {
            return new List<BillingTransaction>
            {
                new("tx_0192a3", "daily_reward", 87, "2026-09-29 14:30"),
                new("tx_01929e", "afk_gain", 12, "2026-09-29 11:15"),
                new("tx_01928b", "server_renew", -25, "2026-09-28 18:00"),
                new("tx_01927a", "daily_reward", 30, "2026-09-28 09:00"),
                new("tx_01926f", "afk_gain", 15, "2026-09-27 22:45")
            };
        }

        try
        {
            var res = await _client.GetAsync<TransactionsResponse>("/api/v5/billing/transactions");
            return res.Transactions;
        }
        catch
        {
            return new List<BillingTransaction>();
        }
    }

    public void OpenAddFundsWeb()
    {
        try
        {
            Process.Start(new ProcessStartInfo
            {
                FileName = "https://console.overnode.fr/wallet",
                UseShellExecute = true
            });
        }
        catch { }
    }

    public void OpenPurchaseCoinsWeb()
    {
        try
        {
            Process.Start(new ProcessStartInfo
            {
                FileName = "https://console.overnode.fr/wallet",
                UseShellExecute = true
            });
        }
        catch { }
    }
}
