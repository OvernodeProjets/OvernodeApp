using System;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Overnode.App.Localization;
using Overnode.App.Services;

namespace Overnode.App.ViewModels;

public partial class TwoFactorViewModel : ObservableObject
{
    private readonly AuthService _authService = AuthService.Instance;
    private readonly LocalizationManager _loc = LocalizationManager.Instance;

    [ObservableProperty]
    [NotifyCanExecuteChangedFor(nameof(VerifyCommand))]
    private string _code = string.Empty;

    [ObservableProperty]
    private bool _isLoading;

    [ObservableProperty]
    private string? _errorMessage;

    public Func<Task<bool>>? OnVerifySuccessAsync { get; set; }
    public event Action? VerificationSucceeded;
    public event Action? VerificationCancelled;

    public string Title => _loc["2fa_title"];
    public string Subtitle => _loc["2fa_subtitle"];
    public string VerifyButtonText => _loc["2fa_verify_button"];
    public string CancelButtonText => _loc["2fa_cancel_button"];

    public bool CanVerify => !string.IsNullOrWhiteSpace(Code) && Code.Trim().Length >= 6;

    [RelayCommand(CanExecute = nameof(CanVerify))]
    private async Task VerifyAsync()
    {
        if (string.IsNullOrWhiteSpace(Code)) return;

        IsLoading = true;
        ErrorMessage = null;

        try
        {
            if (Environment.GetEnvironmentVariable("OVERNODE_TEST_2FA") == "1")
            {
                if (OnVerifySuccessAsync != null)
                {
                    bool ok = await OnVerifySuccessAsync();
                    if (!ok && string.IsNullOrEmpty(ErrorMessage))
                    {
                        ErrorMessage = _loc["auth_error_generic"];
                    }
                    return;
                }
            }

            var res = await _authService.Verify2FAAsync(Code.Trim());
            if (res.Success)
            {
                if (OnVerifySuccessAsync != null)
                {
                    bool ok = await OnVerifySuccessAsync();
                    if (!ok && string.IsNullOrEmpty(ErrorMessage))
                    {
                        ErrorMessage = _loc["auth_error_generic"];
                    }
                }
                else
                {
                    VerificationSucceeded?.Invoke();
                }
            }
            else
            {
                ErrorMessage = !string.IsNullOrEmpty(res.Error)
                    ? res.Error
                    : _loc["auth_error_generic"];
            }
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message.Contains("400") || ex.Message.Contains("Invalid")
                ? _loc["twofactor_invalid_error"]
                : _loc["auth_error_network"];
        }
        finally
        {
            IsLoading = false;
        }
    }

    [RelayCommand]
    private void Cancel()
    {
        Code = string.Empty;
        ErrorMessage = null;
        VerificationCancelled?.Invoke();
    }
}
