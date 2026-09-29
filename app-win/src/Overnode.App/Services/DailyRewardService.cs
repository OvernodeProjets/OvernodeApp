using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Overnode.App.Models;

namespace Overnode.App.Services;

public sealed class DailyRewardService
{
    private static readonly Lazy<DailyRewardService> _instance = new(() => new DailyRewardService());
    public static DailyRewardService Instance => _instance.Value;
    public static DailyRewardService Shared => _instance.Value;

    private readonly APIClient _client = APIClient.Instance;

    private DailyRewardService() { }

    public async Task<DailyRewardStatus> FetchStatusAsync()
    {
        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1")
        {
            return new DailyRewardStatus
            {
                UserId = "1",
                CanClaim = true,
                DaysSinceLastClaim = 1,
                CurrentStreak = 6,
                LongestStreak = 12,
                TotalClaimed = 24,
                TotalCoinsEarned = 1150,
                StreakProtection = 1,
                ProjectedStreak = 7,
                StreakWillMaintain = true,
                NextReward = new DailyRewardTier(87, 25, 1.5, 50, "Bonus série hebdomadaire ! +50 coins")
            };
        }

        return await _client.GetAsync<DailyRewardStatus>("/api/daily-rewards/status");
    }

    public async Task<DailyRewardClaimResponse> ClaimDailyRewardAsync()
    {
        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1")
        {
            await Task.Delay(400);
            return new DailyRewardClaimResponse
            {
                Success = true,
                Streak = 7,
                Reward = 87,
                NewBalance = 437,
                MilestoneMessage = "Bonus série hebdomadaire ! +50 coins"
            };
        }

        return await _client.PostAsync<DailyRewardClaimResponse>("/api/daily-rewards/claim");
    }

    public async Task<List<DailyLeaderboardEntry>> FetchLeaderboardAsync()
    {
        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1")
        {
            return new List<DailyLeaderboardEntry>
            {
                new("u-101", "OverMaster", 64, 78, 95),
                new("u-102", "CloudArchitect", 45, 45, 60),
                new("u-103", "SwiftTitan", 32, 35, 48),
                new("u-104", "VoxelHero", 28, 28, 33),
                new("1", "OvernodeUser", 6, 12, 24),
                new("u-106", "ByteCrafter", 5, 19, 22)
            };
        }

        return await _client.GetAsync<List<DailyLeaderboardEntry>>("/api/daily-rewards/leaderboard");
    }

    public async Task<List<DailyRewardHistoryItem>> FetchHistoryAsync()
    {
        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1")
        {
            var now = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
            long dayMs = 86400 * 1000;
            return new List<DailyRewardHistoryItem>
            {
                new() { Id = "hist-1", Timestamp = now - dayMs, Streak = 6, Reward = 30, StreakMaintained = true },
                new() { Id = "hist-2", Timestamp = now - dayMs * 2, Streak = 5, Reward = 30, StreakMaintained = true },
                new() { Id = "hist-3", Timestamp = now - dayMs * 3, Streak = 4, Reward = 25, StreakMaintained = true },
                new() { Id = "hist-4", Timestamp = now - dayMs * 4, Streak = 3, Reward = 25, StreakMaintained = true }
            };
        }

        try
        {
            return await _client.GetAsync<List<DailyRewardHistoryItem>>("/api/daily-rewards/history");
        }
        catch
        {
            return new List<DailyRewardHistoryItem>();
        }
    }
}
