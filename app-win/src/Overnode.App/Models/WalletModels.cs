using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace Overnode.App.Models;

public class BillingBalances
{
    [JsonPropertyName("credit_eur")]
    public double CreditEur { get; set; }

    [JsonPropertyName("coins")]
    public int Coins { get; set; }

    public BillingBalances() { }

    public BillingBalances(double creditEur, int coins)
    {
        CreditEur = creditEur;
        Coins = coins;
    }
}

public class CoinPackage
{
    [JsonPropertyName("amount")]
    public int Amount { get; set; }

    [JsonPropertyName("price_eur")]
    public double PriceEur { get; set; }

    public CoinPackage() { }

    public CoinPackage(int amount, double priceEur)
    {
        Amount = amount;
        PriceEur = priceEur;
    }
}

public class BillingInfo
{
    [JsonPropertyName("balances")]
    public BillingBalances? Balances { get; set; }

    [JsonPropertyName("currency")]
    public string? Currency { get; set; }

    [JsonPropertyName("coin_packages")]
    public List<CoinPackage>? CoinPackages { get; set; }
}

public class LeaderboardUserEntry
{
    [JsonPropertyName("rank")]
    public int Rank { get; set; }

    [JsonPropertyName("username")]
    public string Username { get; set; } = string.Empty;

    [JsonPropertyName("coins")]
    public int Coins { get; set; }

    public LeaderboardUserEntry() { }

    public LeaderboardUserEntry(int rank, string username, int coins)
    {
        Rank = rank;
        Username = username;
        Coins = coins;
    }
}

public class LeaderboardUserRank
{
    [JsonPropertyName("rank")]
    public int Rank { get; set; }

    [JsonPropertyName("username")]
    public string Username { get; set; } = string.Empty;

    [JsonPropertyName("coins")]
    public int Coins { get; set; }

    [JsonPropertyName("inTop")]
    public bool? InTop { get; set; }

    public LeaderboardUserRank() { }

    public LeaderboardUserRank(int rank, string username, int coins, bool? inTop = null)
    {
        Rank = rank;
        Username = username;
        Coins = coins;
        InTop = inTop;
    }
}

public class LeaderboardResponse
{
    [JsonPropertyName("leaderboard")]
    public List<LeaderboardUserEntry> Leaderboard { get; set; } = new();

    [JsonPropertyName("userRank")]
    public LeaderboardUserRank? UserRank { get; set; }
}

public class BillingTransaction
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("type")]
    public string Type { get; set; } = string.Empty;

    [JsonPropertyName("amount")]
    public double Amount { get; set; }

    [JsonPropertyName("timestamp")]
    public string? Timestamp { get; set; }

    public BillingTransaction() { }

    public BillingTransaction(string id, string type, double amount, string? timestamp = null)
    {
        Id = id;
        Type = type;
        Amount = amount;
        Timestamp = timestamp;
    }
}

public class TransactionsResponse
{
    [JsonPropertyName("transactions")]
    public List<BillingTransaction> Transactions { get; set; } = new();
}
