using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace Overnode.App.Models;

public class StorePrices
{
    [JsonPropertyName("resources")]
    public Dictionary<string, int>? Resources { get; set; }
}

public class StoreConfigResponse
{
    [JsonPropertyName("prices")]
    public StorePrices? Prices { get; set; }

    [JsonPropertyName("multipliers")]
    public Dictionary<string, int>? Multipliers { get; set; }

    [JsonPropertyName("limits")]
    public Dictionary<string, int>? Limits { get; set; }

    [JsonPropertyName("userBalance")]
    public int? UserBalance { get; set; }

    [JsonPropertyName("canAfford")]
    public Dictionary<string, bool>? CanAfford { get; set; }
}

public class StoreBuyPayload
{
    [JsonPropertyName("resourceType")]
    public string ResourceType { get; set; } = string.Empty;

    [JsonPropertyName("amount")]
    public int Amount { get; set; }

    public StoreBuyPayload() { }

    public StoreBuyPayload(string resourceType, int amount)
    {
        ResourceType = resourceType;
        Amount = amount;
    }
}

public class StoreBuyResponse
{
    [JsonPropertyName("success")]
    public bool Success { get; set; }

    [JsonPropertyName("remainingCoins")]
    public int? RemainingCoins { get; set; }
}

public class StoreBundle
{
    public string Id { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Price { get; set; } = string.Empty;
    public string Period { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public List<string> Features { get; set; } = new();
    public string IconGlyph { get; set; } = "\uE719";
    public string IconColorHex { get; set; } = "#F59E0B";
    public string ColorHex => IconColorHex;

    public StoreBundle() { }

    public StoreBundle(string id, string title, string price, string period, string description, List<string> features, string iconGlyph, string iconColorHex)
    {
        Id = id;
        Title = title;
        Price = price;
        Period = period;
        Description = description;
        Features = features;
        IconGlyph = iconGlyph;
        IconColorHex = iconColorHex;
    }
}
