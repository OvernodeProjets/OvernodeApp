using System;
using System.Threading;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using Overnode.App.Models;
using Overnode.App.Services;

namespace Overnode.App.ViewModels;

public sealed partial class UpdateViewModel : ObservableObject
{
    private static readonly Lazy<UpdateViewModel> _instance = new(() => new UpdateViewModel());
    public static UpdateViewModel Shared => _instance.Value;

    private readonly UpdateService _service;
    private CancellationTokenSource? _downloadCts;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(HasUpdateAvailable))]
    [NotifyPropertyChangedFor(nameof(IsDownloading))]
    private UpdateStatus _state = UpdateStatus.Idle;

    [ObservableProperty]
    private bool _showModal;

    [ObservableProperty]
    private double _downloadProgress;

    [ObservableProperty]
    private string? _errorMessage;

    [ObservableProperty]
    private UpdateCheckResponse? _availableUpdate;

    public UpdateViewModel(UpdateService? service = null)
    {
        _service = service ?? UpdateService.Shared;
    }

    public string CurrentVersion => _service.CurrentAppVersion;

    public bool HasUpdateAvailable => State is UpdateStatus.Available or UpdateStatus.Downloading or UpdateStatus.ReadyToRestart;

    public bool IsDownloading => State == UpdateStatus.Downloading;

    public async Task<bool> CheckForUpdatesAsync(bool silent = false)
    {
        if (!silent)
        {
            State = UpdateStatus.Checking;
            ErrorMessage = null;
        }

        try
        {
            var res = await _service.CheckForUpdatesAsync().ConfigureAwait(false);
            AvailableUpdate = res;

            if (res.UpdateAvailable)
            {
                State = UpdateStatus.Available;
                ShowModal = true;
                return true;
            }
            else
            {
                State = UpdateStatus.UpToDate;
                if (!silent)
                {
                    ShowModal = false;
                }
                return false;
            }
        }
        catch (Exception ex)
        {
            if (!silent)
            {
                State = UpdateStatus.Failed;
                ErrorMessage = ex.Message;
            }
            return false;
        }
    }

    public async Task StartDownloadAndInstallAsync()
    {
        if (AvailableUpdate == null) return;

        State = UpdateStatus.Downloading;
        DownloadProgress = 0.0;
        ErrorMessage = null;

        _downloadCts?.Cancel();
        _downloadCts = new CancellationTokenSource();

        try
        {
            var progress = new Progress<double>(p =>
            {
                DownloadProgress = p;
            });

            var downloadedMsiPath = await _service.DownloadUpdateAsync(
                AvailableUpdate.DownloadUrl,
                AvailableUpdate.Sha256,
                progress,
                _downloadCts.Token).ConfigureAwait(false);

            State = UpdateStatus.ReadyToRestart;

            // Short pause to show 100% and ready state
            await Task.Delay(400).ConfigureAwait(false);

            _service.LaunchInstallerAndRestart(downloadedMsiPath);
        }
        catch (OperationCanceledException)
        {
            State = UpdateStatus.Available;
        }
        catch (Exception ex)
        {
            State = UpdateStatus.Failed;
            ErrorMessage = ex.Message;
        }
    }

    public void Dismiss()
    {
        if (State == UpdateStatus.Downloading)
        {
            _downloadCts?.Cancel();
        }
        ShowModal = false;
    }
}
