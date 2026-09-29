using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading.Tasks;
using Overnode.App.Models;

namespace Overnode.App.Services;

public sealed class StoreService
{
    private static readonly Lazy<StoreService> _instance = new(() => new StoreService());
    public static StoreService Instance => _instance.Value;
    public static StoreService Shared => _instance.Value;

    private readonly APIClient _client = APIClient.Instance;

    private StoreService() { }

    public async Task<StoreConfigResponse> FetchStoreConfigAsync()
    {
        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1")
        {
            return new StoreConfigResponse
            {
                Prices = new StorePrices
                {
                    Resources = new()
                    {
                        { "ram", 600 },
                        { "disk", 400 },
                        { "cpu", 500 },
                        { "servers", 200 }
                    }
                },
                UserBalance = 350,
                CanAfford = new()
                {
                    { "ram", false },
                    { "disk", false },
                    { "cpu", false },
                    { "servers", true }
                }
            };
        }

        return await _client.GetAsync<StoreConfigResponse>("/api/store/config");
    }

    public async Task<StoreBuyResponse> BuyResourceAsync(string resourceType, int amount)
    {
        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1")
        {
            await Task.Delay(400);
            return new StoreBuyResponse
            {
                Success = true,
                RemainingCoins = 150
            };
        }

        var payload = new StoreBuyPayload(resourceType, amount);
        return await _client.PostAsync<StoreBuyResponse>("/api/store/buy", payload);
    }

    public void OpenSubscribeWeb()
    {
        try
        {
            Process.Start(new ProcessStartInfo
            {
                FileName = "https://console.overnode.fr/coin/store",
                UseShellExecute = true
            });
        }
        catch { }
    }
}
