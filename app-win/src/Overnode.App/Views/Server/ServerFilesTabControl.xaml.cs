using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Data;
using Windows.ApplicationModel.DataTransfer;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.Services;
using Overnode.App.ViewModels;

namespace Overnode.App.Views.Server;

public class BoolToVisibilityConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, string language)
    {
        return value is true ? Visibility.Visible : Visibility.Collapsed;
    }

    public object ConvertBack(object value, Type targetType, object parameter, string language)
    {
        return value is Visibility v && v == Visibility.Visible;
    }
}

public sealed partial class ServerFilesTabControl : UserControl
{
    public ServerDetailViewModel? ViewModel => DataContext as ServerDetailViewModel;

    public ServerFilesTabControl()
    {
        this.InitializeComponent();
        LocalizationManager.Instance.LanguageChanged += (s, e) => UpdateLocalization();
        ExternalEditorManager.Shared.FileSynced += OnExternalFileSynced;
        FolderSyncManager.Shared.FolderSynced += OnFolderSynced;

        Unloaded += (s, e) =>
        {
            ExternalEditorManager.Shared.FileSynced -= OnExternalFileSynced;
            FolderSyncManager.Shared.FolderSynced -= OnFolderSynced;
        };

        DataContextChanged += (s, e) =>
        {
            if (ViewModel != null)
            {
                ViewModel.PropertyChanged += (ps, pe) =>
                {
                    if (pe.PropertyName == nameof(ServerDetailViewModel.Files) ||
                        pe.PropertyName == nameof(ServerDetailViewModel.IsFileLoading) ||
                        pe.PropertyName == nameof(ServerDetailViewModel.CurrentDirectory) ||
                        pe.PropertyName == nameof(ServerDetailViewModel.SelectedFile) ||
                        pe.PropertyName == nameof(ServerDetailViewModel.FileSuccessMessage) ||
                        pe.PropertyName == nameof(ServerDetailViewModel.FileErrorMessage) ||
                        pe.PropertyName == nameof(ServerDetailViewModel.IsUploadingFiles) ||
                        pe.PropertyName == nameof(ServerDetailViewModel.UploadProgress) ||
                        pe.PropertyName == nameof(ServerDetailViewModel.UploadProgressText))
                    {
                        UpdateUI();
                    }
                };
            }
            UpdateUI();
        };

        Loaded += async (s, e) =>
        {
            if (ViewModel != null && ViewModel.Files.Count == 0)
            {
                await ViewModel.LoadFilesAsync();
            }
            UpdateUI();
        };

        UpdateLocalization();
    }

    private void UpdateLocalization()
    {
        var loc = LocalizationManager.Instance;
        ParentDirText.Text = loc.GetString("files_parent_dir");
        NewFolderText.Text = loc.GetString("files_new_folder");
        NewFolderDialogTitle.Text = loc.GetString("files_new_folder");
        CreateFolderBtnText.Text = loc.GetString("generic_create");
        FilesLoadingText.Text = loc.GetString("files_loading");
        FilesEmptyText.Text = loc.GetString("files_empty_directory");
        CancelEditText.Text = loc.GetString("generic_close");
        SaveFileText.Text = loc.GetString("generic_save");
        NewFolderNameBox.PlaceholderText = loc.GetString("files_folder_placeholder");
        DropOverlayTitleText.Text = loc.GetString("files_drop_zone_title");
        DropOverlaySubtitleText.Text = loc.GetString("files_drop_zone_subtitle");
    }

    public void UpdateUI()
    {
        if (ViewModel == null) return;

        CurrentDirText.Text = ViewModel.CurrentDirectory;
        ParentDirBtn.Visibility = ViewModel.CurrentDirectory != "/" ? Visibility.Visible : Visibility.Collapsed;

        // Feedback banners
        if (!string.IsNullOrEmpty(ViewModel.FileSuccessMessage))
        {
            FileSuccessText.Text = ViewModel.FileSuccessMessage;
            FileSuccessBanner.Visibility = Visibility.Visible;
        }
        else
        {
            FileSuccessBanner.Visibility = Visibility.Collapsed;
        }

        if (!string.IsNullOrEmpty(ViewModel.FileErrorMessage))
        {
            FileErrorText.Text = ViewModel.FileErrorMessage;
            FileErrorBanner.Visibility = Visibility.Visible;
        }
        else
        {
            FileErrorBanner.Visibility = Visibility.Collapsed;
        }

        // Upload progress
        if (ViewModel.IsUploadingFiles)
        {
            UploadProgressText.Text = ViewModel.UploadProgressText;
            UploadProgressBar.Value = Math.Clamp(ViewModel.UploadProgress * 100.0, 0, 100);
            UploadProgressPercentText.Text = $"{(int)(ViewModel.UploadProgress * 100.0)}%";
            UploadProgressCard.Visibility = Visibility.Visible;
        }
        else
        {
            UploadProgressCard.Visibility = Visibility.Collapsed;
        }

        // Editor mode vs Browser mode
        if (ViewModel.SelectedFile != null)
        {
            FileBrowserContainer.Visibility = Visibility.Collapsed;
            FileEditorContainer.Visibility = Visibility.Visible;
            EditingFileNameText.Text = ViewModel.SelectedFile.Name;
            FileEditorTextBox.Text = ViewModel.FileEditorContent;
            return;
        }

        FileBrowserContainer.Visibility = Visibility.Visible;
        FileEditorContainer.Visibility = Visibility.Collapsed;

        // Loading or Empty or List
        if (ViewModel.IsFileLoading && ViewModel.Files.Count == 0)
        {
            FilesLoadingContainer.Visibility = Visibility.Visible;
            FilesEmptyContainer.Visibility = Visibility.Collapsed;
            FilesListContainer.Visibility = Visibility.Collapsed;
        }
        else if (ViewModel.Files.Count == 0)
        {
            FilesLoadingContainer.Visibility = Visibility.Collapsed;
            FilesEmptyContainer.Visibility = Visibility.Visible;
            FilesListContainer.Visibility = Visibility.Collapsed;
        }
        else
        {
            FilesLoadingContainer.Visibility = Visibility.Collapsed;
            FilesEmptyContainer.Visibility = Visibility.Collapsed;
            FilesListContainer.Visibility = Visibility.Visible;
            FilesItemsControl.ItemsSource = ViewModel.Files;
        }
    }

    private void OnExternalFileSynced(string serverId, string fileName)
    {
        if (ViewModel != null && ViewModel.Server.Identifier == serverId)
        {
            DispatcherQueue?.TryEnqueue(() =>
            {
                string msg = LocalizationManager.Instance.Format("files_synced_success", fileName);
                ViewModel.FileSuccessMessage = msg;
                _ = Task.Delay(4000).ContinueWith(_ =>
                {
                    DispatcherQueue?.TryEnqueue(() =>
                    {
                        if (ViewModel.FileSuccessMessage == msg)
                        {
                            ViewModel.FileSuccessMessage = null;
                        }
                    });
                });
            });
        }
    }

    private void OnFolderSynced(string serverId, string folderName, int count)
    {
        if (ViewModel != null && ViewModel.Server.Identifier == serverId)
        {
            DispatcherQueue?.TryEnqueue(async () =>
            {
                string msg = LocalizationManager.Instance.Format("files_sync_success_notification", folderName, count);
                ViewModel.FileSuccessMessage = msg;
                await ViewModel.LoadFilesAsync(ViewModel.CurrentDirectory, true);

                _ = Task.Delay(4000).ContinueWith(_ =>
                {
                    DispatcherQueue?.TryEnqueue(() =>
                    {
                        if (ViewModel.FileSuccessMessage == msg)
                        {
                            ViewModel.FileSuccessMessage = null;
                        }
                    });
                });
            });
        }
    }

    // Drag & Drop
    private void OnFileBrowserDragOver(object sender, DragEventArgs e)
    {
        if (e.DataView.Contains(StandardDataFormats.StorageItems))
        {
            e.AcceptedOperation = DataPackageOperation.Copy;
            e.DragUIOverride.Caption = LocalizationManager.Instance.GetString("files_drop_zone_title");
            e.DragUIOverride.IsCaptionVisible = true;
            e.DragUIOverride.IsContentVisible = true;
            FileDropOverlay.Visibility = Visibility.Visible;
        }
        else
        {
            e.AcceptedOperation = DataPackageOperation.None;
        }
    }

    private void OnFileBrowserDragLeave(object sender, DragEventArgs e)
    {
        FileDropOverlay.Visibility = Visibility.Collapsed;
    }

    private async void OnFileBrowserDrop(object sender, DragEventArgs e)
    {
        FileDropOverlay.Visibility = Visibility.Collapsed;

        if (e.DataView.Contains(StandardDataFormats.StorageItems) && ViewModel != null)
        {
            try
            {
                var items = await e.DataView.GetStorageItemsAsync();
                var paths = items.Select(i => i.Path).Where(p => !string.IsNullOrEmpty(p)).ToList();
                if (paths.Count > 0)
                {
                    await ViewModel.UploadDroppedPathsAsync(paths);
                }
            }
            catch (Exception ex)
            {
                ViewModel.FileErrorMessage = ex.Message;
            }
        }
    }

    private async void OnParentDirClicked(object sender, RoutedEventArgs e)
    {
        if (ViewModel == null) return;
        var dir = ViewModel.CurrentDirectory;
        if (dir == "/") return;

        var lastSlash = dir.LastIndexOf('/');
        string parent = lastSlash <= 0 ? "/" : dir[..lastSlash];
        await ViewModel.LoadFilesAsync(parent);
    }

    private async void OnRefreshFilesClicked(object sender, RoutedEventArgs e)
    {
        if (ViewModel != null)
        {
            await ViewModel.LoadFilesAsync(force: true);
        }
    }

    private async void OnFileRowClicked(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement fe && fe.DataContext is ServerFileItem item && ViewModel != null)
        {
            if (!item.IsFile)
            {
                await ViewModel.OpenFileAsync(item);
                UpdateUI();
            }
        }
    }

    private async void OnFileRowDoubleTapped(object sender, Microsoft.UI.Xaml.Input.DoubleTappedRoutedEventArgs e)
    {
        if (sender is FrameworkElement fe && fe.DataContext is ServerFileItem item && ViewModel != null)
        {
            e.Handled = true;
            await ViewModel.OpenFileAsync(item);
            UpdateUI();
        }
    }

    private void OnFileRowContextMenuOpening(object? sender, object e)
    {
        if (sender is MenuFlyout flyout && flyout.Target is FrameworkElement fe && fe.DataContext is ServerFileItem item)
        {
            bool isFile = item.IsFile;
            bool isSynced = item.IsSynced;

            foreach (var element in flyout.Items)
            {
                if (element is MenuFlyoutItem mfi && mfi.Tag is string tag)
                {
                    mfi.Visibility = tag switch
                    {
                        "file_only" => isFile ? Visibility.Visible : Visibility.Collapsed,
                        "folder_only" => !isFile ? Visibility.Visible : Visibility.Collapsed,
                        "sync_only" => (!isFile && isSynced) ? Visibility.Visible : Visibility.Collapsed,
                        "nosync_only" => (!isFile && !isSynced) ? Visibility.Visible : Visibility.Collapsed,
                        _ => Visibility.Visible
                    };
                }
            }
        }
    }

    private async void OnContextMenuOpenClicked(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement fe && fe.DataContext is ServerFileItem item && ViewModel != null)
        {
            await ViewModel.OpenFileAsync(item);
            UpdateUI();
        }
    }

    private async void OnContextMenuOpenExternalClicked(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement fe && fe.DataContext is ServerFileItem item && ViewModel != null && item.IsFile)
        {
            await ViewModel.OpenFileInExternalEditorAsync(item, forceChooseEditor: false);
        }
    }

    private async void OnContextMenuChooseEditorClicked(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement fe && fe.DataContext is ServerFileItem item && ViewModel != null && item.IsFile)
        {
            await ViewModel.OpenFileInExternalEditorAsync(item, forceChooseEditor: true);
        }
    }

    private async void OnContextMenuOpenInternalClicked(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement fe && fe.DataContext is ServerFileItem item && ViewModel != null && item.IsFile)
        {
            await ViewModel.OpenFileInternallyAsync(item);
            UpdateUI();
        }
    }

    private async void OnContextMenuOpenFolderClicked(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement fe && fe.DataContext is ServerFileItem item && ViewModel != null && !item.IsFile)
        {
            await ViewModel.OpenFileAsync(item);
            UpdateUI();
        }
    }

    private async void OnContextMenuSyncEnableClicked(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement fe && fe.DataContext is ServerFileItem item && ViewModel != null && !item.IsFile)
        {
            string? localFolder = await WindowsPickerHelper.PickFolderAsync();
            if (!string.IsNullOrEmpty(localFolder))
            {
                await ViewModel.PromptSyncFolderAsync(item, localFolder);
            }
        }
    }

    private void OnContextMenuSyncOpenExplorerClicked(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement fe && fe.DataContext is ServerFileItem item && ViewModel != null && !item.IsFile)
        {
            ViewModel.OpenSyncedFolderInExplorer(item);
        }
    }

    private async void OnContextMenuSyncForceClicked(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement fe && fe.DataContext is ServerFileItem item && ViewModel != null && !item.IsFile)
        {
            await ViewModel.ForceSyncFolderAsync(item);
        }
    }

    private void OnContextMenuSyncStopClicked(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement fe && fe.DataContext is ServerFileItem item && ViewModel != null && !item.IsFile)
        {
            ViewModel.StopSyncFolder(item);
        }
    }

    private async void OnContextMenuDeleteClicked(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement fe && fe.DataContext is ServerFileItem item && ViewModel != null)
        {
            await ViewModel.DeleteFileAsync(item);
        }
    }

    private async void OnCreateFolderConfirmed(object sender, RoutedEventArgs e)
    {
        string name = NewFolderNameBox.Text.Trim();
        if (string.IsNullOrEmpty(name)) return;
        NewFolderNameBox.Text = string.Empty;
        NewFolderFlyout.Hide();

        if (ViewModel != null)
        {
            await ViewModel.CreateFolderAsync(name);
        }
    }

    private void OnCancelEditClicked(object sender, RoutedEventArgs e)
    {
        if (ViewModel != null)
        {
            ViewModel.SelectedFile = null;
            UpdateUI();
        }
    }

    private async void OnSaveFileClicked(object sender, RoutedEventArgs e)
    {
        if (ViewModel != null)
        {
            ViewModel.FileEditorContent = FileEditorTextBox.Text;
            await ViewModel.SaveCurrentFileAsync();
            EditorSaveStatusText.Text = LocalizationManager.Instance.GetString("files_saved_success");
        }
    }
}
