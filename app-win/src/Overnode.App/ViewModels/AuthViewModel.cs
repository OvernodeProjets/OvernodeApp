using System;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.Services;

namespace Overnode.App.ViewModels;

public partial class AuthViewModel : ObservableObject
{
    private readonly AuthService _authService = AuthService.Instance;
    private readonly LocalizationManager _loc = LocalizationManager.Instance;

    [ObservableProperty]
    private bool _isLoading;

    [ObservableProperty]
    private bool _isAuthenticated;

    [ObservableProperty]
    private bool _isTwoFactorPending;

    [ObservableProperty]
    private User? _currentUser;

    [ObservableProperty]
    private ResourcesResponse? _initialResources;

    [ObservableProperty]
    private string? _errorMessage;

    public TwoFactorViewModel TwoFactorVM { get; }

    public LocalizationManager Loc => _loc;

    public AuthViewModel()
    {
        TwoFactorVM = new TwoFactorViewModel();
        TwoFactorVM.VerificationSucceeded += OnTwoFactorSucceeded;
        TwoFactorVM.VerificationCancelled += OnTwoFactorCancelled;

        // Check demo mode environment flag
        if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") == "1")
        {
            CurrentUser = new User
            {
                Id = "1",
                Username = "OvernodeUser",
                Email = "user@overnode.fr",
                GlobalName = "Overnode User",
                Role = "Client",
                Coins = 350
            };
            IsAuthenticated = true;
            return;
        }

        if (Environment.GetEnvironmentVariable("OVERNODE_TEST_2FA") == "1")
        {
            IsTwoFactorPending = true;
            return;
        }

        _ = SafeCheckSessionAsync();
    }

    private async Task SafeCheckSessionAsync()
    {
        try
        {
            await CheckSessionAsync();
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[AuthVM] Session check failed: {ex.Message}");
            ErrorMessage = null; // Silently fail - user will see login screen
        }
    }

    [RelayCommand]
    public async Task CheckSessionAsync()
    {
        IsLoading = true;
        ErrorMessage = null;

        try
        {
            var initData = await _authService.FetchInitAsync();
            if (initData?.User != null)
            {
                string uEmail = !string.IsNullOrEmpty(initData.User.Email)
                    ? initData.User.Email
                    : (initData.User.PterodactylEmail ?? string.Empty);

                CurrentUser = new User
                {
                    Id = initData.User.Id,
                    Username = initData.User.Username,
                    Email = uEmail,
                    GlobalName = initData.User.GlobalName,
                    Role = initData.Roles?.Count > 0 ? initData.Roles[0].Name : null,
                    Coins = initData.Coins ?? 0
                };
                IsAuthenticated = true;
                IsTwoFactorPending = false;
                return;
            }
        }
        catch
        {
            // If /api/v5/init fails, check /api/v5/state
            try
            {
                var state = await _authService.CheckAuthStateAsync();
                if (state.TwoFactorPending == true)
                {
                    IsTwoFactorPending = true;
                    IsAuthenticated = false;
                    return;
                }

                if (state.Authenticated && state.User != null)
                {
                    CurrentUser = state.User;
                    IsAuthenticated = true;
                    IsTwoFactorPending = false;
                    return;
                }
            }
            catch
            {
                // Not logged in or network error
            }
        }
        finally
        {
            IsLoading = false;
        }

        IsAuthenticated = false;
        CurrentUser = null;
    }

    [RelayCommand]
    public async Task LoginWithDiscordAsync()
    {
        IsLoading = true;
        ErrorMessage = null;

        try
        {
            var state = await DiscordAuthCoordinator.Instance.StartDiscordAuthAsync();
            if (state == null)
            {
                // Cancelled
                ErrorMessage = _loc["auth_error_cancelled"];
                return;
            }

            if (state.TwoFactorPending == true)
            {
                IsTwoFactorPending = true;
                return;
            }

            if (state.Authenticated)
            {
                await CompleteSessionInitializationAsync(state.User);
            }
        }
        catch (Exception ex)
        {
            ErrorMessage = $"{_loc["auth_error_generic"]} ({ex.Message})";
        }
        finally
        {
            IsLoading = false;
        }
    }

    [RelayCommand]
    public void LoginWithPasskey()
    {
        ErrorMessage = _loc["auth_passkey_notice"];
    }

    private async void OnTwoFactorSucceeded()
    {
        IsTwoFactorPending = false;
        IsLoading = true;
        ErrorMessage = null;

        try
        {
            await CompleteSessionInitializationAsync(null);
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

    private void OnTwoFactorCancelled()
    {
        IsTwoFactorPending = false;
        _authService.Logout();
        IsAuthenticated = false;
        CurrentUser = null;
    }

    private async Task CompleteSessionInitializationAsync(User? fallbackUser)
    {
        try
        {
            var initData = await _authService.FetchInitAsync();
            if (initData?.User != null)
            {
                string email = !string.IsNullOrEmpty(initData.User.Email)
                    ? initData.User.Email
                    : (initData.User.PterodactylEmail ?? string.Empty);

                CurrentUser = new User
                {
                    Id = initData.User.Id,
                    Username = initData.User.Username,
                    Email = email,
                    GlobalName = initData.User.GlobalName,
                    Role = initData.Roles?.Count > 0 ? initData.Roles[0].Name : null,
                    Coins = initData.Coins ?? 0
                };

                try
                {
                    InitialResources = await _authService.FetchResourcesAsync();
                }
                catch { }

                IsAuthenticated = true;
                return;
            }
        }
        catch { }

        if (fallbackUser != null)
        {
            CurrentUser = fallbackUser;
            IsAuthenticated = true;
        }
    }

    [RelayCommand]
    public void Logout()
    {
        _authService.Logout();
        IsAuthenticated = false;
        CurrentUser = null;
        InitialResources = null;
        IsTwoFactorPending = false;
    }
}
