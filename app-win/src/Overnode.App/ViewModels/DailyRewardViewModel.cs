using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using Overnode.App.Models;
using Overnode.App.Services;

namespace Overnode.App.ViewModels;

public enum DailyRewardTab
{
    Claim,
    History,
    Leaderboard
}

public partial class DailyRewardViewModel : ObservableObject
{
    private readonly DailyRewardService _service = DailyRewardService.Instance;

    [ObservableProperty]
    private DailyRewardStatus? _status;

    [ObservableProperty]
    private List<DailyLeaderboardEntry> _leaderboard = new();

    [ObservableProperty]
    private List<DailyRewardHistoryItem> _history = new();

    [ObservableProperty]
    private DailyRewardTab _selectedTab = DailyRewardTab.Claim;

    [ObservableProperty]
    private bool _isLoading;

    [ObservableProperty]
    private bool _isClaiming;

    [ObservableProperty]
    private string? _errorMessage;

    [ObservableProperty]
    private string? _successMessage;

    public DailyRewardViewModel() { }

    public async Task LoadDataAsync()
    {
        IsLoading = true;
        ErrorMessage = null;

        try
        {
            var statusTask = _service.FetchStatusAsync();
            var lboardTask = _service.FetchLeaderboardAsync();
            var histTask = _service.FetchHistoryAsync();

            await Task.WhenAll(statusTask, lboardTask, histTask);

            Status = await statusTask;
            Leaderboard = await lboardTask;
            History = await histTask;
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

    public async Task<bool> ClaimRewardAsync()
    {
        if (Status == null || !Status.CanClaim || IsClaiming) return false;

        IsClaiming = true;
        ErrorMessage = null;
        SuccessMessage = null;

        try
        {
            var res = await _service.ClaimDailyRewardAsync();
            if (res.Success)
            {
                SuccessMessage = $"+{res.Reward} coins réclamés avec succès !";
                if (Status != null)
                {
                    Status.CanClaim = false;
                    Status.CurrentStreak = res.Streak;
                    Status.TotalClaimed += 1;
                    Status.TotalCoinsEarned += res.Reward;
                }
                OnPropertyChanged(nameof(Status));
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
            IsClaiming = false;
        }
    }
}
