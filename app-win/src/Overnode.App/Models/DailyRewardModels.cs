using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace Overnode.App.Models;

public class DailyRewardTier
{
    [JsonPropertyName("amount")]
    public int Amount { get; set; }

    [JsonPropertyName("baseAmount")]
    public int BaseAmount { get; set; } = 25;

    [JsonPropertyName("multiplier")]
    public double Multiplier { get; set; } = 1.0;

    [JsonPropertyName("milestoneBonus")]
    public int MilestoneBonus { get; set; }

    [JsonPropertyName("milestoneMessage")]
    public string? MilestoneMessage { get; set; }

    public DailyRewardTier() { }

    public DailyRewardTier(int amount, int baseAmount = 25, double multiplier = 1.0, int milestoneBonus = 0, string? milestoneMessage = null)
    {
        Amount = amount;
        BaseAmount = baseAmount;
        Multiplier = multiplier;
        MilestoneBonus = milestoneBonus;
        MilestoneMessage = milestoneMessage;
    }
}

public class DailyRewardStatus
{
    [JsonPropertyName("userId")]
    public string UserId { get; set; } = string.Empty;

    [JsonPropertyName("canClaim")]
    public bool CanClaim { get; set; }

    [JsonPropertyName("daysSinceLastClaim")]
    public int DaysSinceLastClaim { get; set; }

    [JsonPropertyName("currentStreak")]
    public int CurrentStreak { get; set; }

    [JsonPropertyName("longestStreak")]
    public int LongestStreak { get; set; }

    [JsonPropertyName("lastClaimTimestamp")]
    public long LastClaimTimestamp { get; set; }

    [JsonPropertyName("totalClaimed")]
    public int TotalClaimed { get; set; }

    [JsonPropertyName("totalCoinsEarned")]
    public int TotalCoinsEarned { get; set; }

    [JsonPropertyName("streakProtection")]
    public int StreakProtection { get; set; }

    [JsonPropertyName("projectedStreak")]
    public int ProjectedStreak { get; set; }

    [JsonPropertyName("streakWillMaintain")]
    public bool StreakWillMaintain { get; set; }

    [JsonPropertyName("willUseProtection")]
    public bool WillUseProtection { get; set; }

    [JsonPropertyName("nextReward")]
    public DailyRewardTier? NextReward { get; set; }
}

public class DailyRewardClaimResponse
{
    [JsonPropertyName("success")]
    public bool Success { get; set; }

    [JsonPropertyName("streak")]
    public int Streak { get; set; }

    [JsonPropertyName("reward")]
    public int Reward { get; set; }

    [JsonPropertyName("newBalance")]
    public int NewBalance { get; set; }

    [JsonPropertyName("milestoneMessage")]
    public string? MilestoneMessage { get; set; }
}

public class DailyLeaderboardEntry
{
    [JsonPropertyName("userId")]
    public string UserId { get; set; } = string.Empty;

    [JsonPropertyName("username")]
    public string Username { get; set; } = string.Empty;

    [JsonPropertyName("currentStreak")]
    public int CurrentStreak { get; set; }

    [JsonPropertyName("longestStreak")]
    public int LongestStreak { get; set; }

    [JsonPropertyName("totalClaimed")]
    public int TotalClaimed { get; set; }

    public DailyLeaderboardEntry() { }

    public DailyLeaderboardEntry(string userId, string username, int currentStreak, int longestStreak, int totalClaimed)
    {
        UserId = userId;
        Username = username;
        CurrentStreak = currentStreak;
        LongestStreak = longestStreak;
        TotalClaimed = totalClaimed;
    }
}

public class DailyRewardHistoryItem
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("timestamp")]
    public long Timestamp { get; set; }

    [JsonPropertyName("streak")]
    public int Streak { get; set; }

    [JsonPropertyName("reward")]
    public int Reward { get; set; }

    [JsonPropertyName("streakMaintained")]
    public bool StreakMaintained { get; set; }

    [JsonPropertyName("milestoneMessage")]
    public string? MilestoneMessage { get; set; }
}
