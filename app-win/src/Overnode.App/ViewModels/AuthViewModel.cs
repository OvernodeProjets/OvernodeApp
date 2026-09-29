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

    private User? _pendingTwoFactorUser;

    public TwoFactorViewModel TwoFactorVM { get; }

    public LocalizationManager Loc => _loc;

    public AuthViewModel()
    {
        TwoFactorVM = new TwoFactorViewModel();
        TwoFactorVM.OnVerifySuccessAsync = HandleTwoFactorSuccessAsync;
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
                try
                {
                    CurrentUser.Coins = await _authService.FetchCoinsAsync();
                }
                catch { }
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
                    _pendingTwoFactorUser = state.User;
                    IsTwoFactorPending = true;
                    IsAuthenticated = false;
                    return;
                }

                if (state.Authenticated && state.User != null)
                {
                    CurrentUser = state.User;
                    try
                    {
                        CurrentUser.Coins = await _authService.FetchCoinsAsync();
                    }
                    catch { }
                    IsAuthenticated = true;
                    IsTwoFactorPending = false;
                    _pendingTwoFactorUser = null;
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
                _pendingTwoFactorUser = state.User;
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

    public async Task<bool> HandleTwoFactorSuccessAsync()
    {
        ErrorMessage = null;

        if (Environment.GetEnvironmentVariable("OVERNODE_TEST_2FA") == "1")
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
            IsTwoFactorPending = false;
            _pendingTwoFactorUser = null;
            return true;
        }

        try
        {
            bool ok = await CompleteSessionInitializationAsync(_pendingTwoFactorUser);
            if (ok)
            {
                IsAuthenticated = true;
                IsTwoFactorPending = false;
                _pendingTwoFactorUser = null;
                return true;
            }
            else
            {
                TwoFactorVM.ErrorMessage = _loc["auth_error_generic"];
                return false;
            }
        }
        catch (Exception ex)
        {
            TwoFactorVM.ErrorMessage = ex.Message;
            return false;
        }
    }

    private void OnTwoFactorCancelled()
    {
        _pendingTwoFactorUser = null;
        IsTwoFactorPending = false;
        _authService.Logout();
        IsAuthenticated = false;
        CurrentUser = null;
    }

    private async Task<bool> CompleteSessionInitializationAsync(User? fallbackUser)
    {
        // 1. Primary: fetch /api/v5/init
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
                    CurrentUser.Coins = await _authService.FetchCoinsAsync();
                }
                catch { }

                try
                {
                    InitialResources = await _authService.FetchResourcesAsync();
                }
                catch { }

                IsAuthenticated = true;
                return true;
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[AuthVM] FetchInitAsync failed: {ex.Message}");
        }

        // 2. Secondary fallback: check /api/v5/state (same fallback mechanism as macOS checkSession)
        try
        {
            var state = await _authService.CheckAuthStateAsync();
            if (state.Authenticated && state.User != null)
            {
                CurrentUser = state.User;
                try
                {
                    CurrentUser.Coins = await _authService.FetchCoinsAsync();
                }
                catch { }

                try
                {
                    InitialResources = await _authService.FetchResourcesAsync();
                }
                catch { }

                IsAuthenticated = true;
                return true;
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[AuthVM] CheckAuthStateAsync fallback failed: {ex.Message}");
        }

        // 3. Fallback to passed user object
        if (fallbackUser != null)
        {
            CurrentUser = fallbackUser;
            try
            {
                CurrentUser.Coins = await _authService.FetchCoinsAsync();
            }
            catch { }

            try
            {
                InitialResources = await _authService.FetchResourcesAsync();
            }
            catch { }

            IsAuthenticated = true;
            return true;
        }

        return false;
    }

    [RelayCommand]
    public async Task RefreshCoinsAsync()
    {
        if (CurrentUser == null) return;
        try
        {
            var coins = await _authService.FetchCoinsAsync();
            CurrentUser.Coins = coins;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[AuthVM] RefreshCoinsAsync error: {ex.Message}");
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
        _pendingTwoFactorUser = null;
    }
}
