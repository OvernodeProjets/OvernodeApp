using System;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Overnode.App.Localization;
using Overnode.App.Models;
using Overnode.App.Services;
using Overnode.App.ViewModels;

namespace Overnode.App.Views.Server;

public sealed partial class ServerFilesTabControl : UserControl
{
    public ServerDetailViewModel? ViewModel => DataContext as ServerDetailViewModel;

    private DateTime _lastClickTime = DateTime.MinValue;
    private string? _lastClickedPath;

    public ServerFilesTabControl()
    {
        this.InitializeComponent();
        LocalizationManager.Instance.LanguageChanged += (s, e) => UpdateLocalization();
        ExternalEditorManager.Shared.FileSynced += OnExternalFileSynced;

        Unloaded += (s, e) =>
        {
            ExternalEditorManager.Shared.FileSynced -= OnExternalFileSynced;
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
                        pe.PropertyName == nameof(ServerDetailViewModel.SelectedFile))
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

    private async void OnParentDirClicked(object sender, RoutedEventArgs e)
    {
        if (ViewModel == null) return;
        var dir = ViewModel.CurrentDirectory;
        if (dir == "/") return;

        var lastSlash = dir.LastIndexOf('/');
        string parent = lastSlash <= 0 ? "/" : dir.Substring(0, lastSlash);
        await ViewModel.LoadFilesAsync(parent);
    }

    private async void OnRefreshFilesClicked(object sender, RoutedEventArgs e)
    {
        if (ViewModel != null)
        {
            await ViewModel.LoadFilesAsync(force: true);
        }
    }

    private void OnExternalFileSynced(string serverId, string fileName)
    {
        if (ViewModel != null && ViewModel.Server.Identifier == serverId)
        {
            DispatcherQueue?.TryEnqueue(() =>
            {
                FileSuccessText.Text = $"Fichier synchronisé : {fileName}";
                FileSuccessBanner.Visibility = Visibility.Visible;

                _ = Task.Run(async () =>
                {
                    await Task.Delay(3000);
                    DispatcherQueue?.TryEnqueue(() =>
                    {
                        if (FileSuccessText.Text.Contains(fileName))
                        {
                            FileSuccessBanner.Visibility = Visibility.Collapsed;
                        }
                    });
                });
            });
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
                return;
            }

            var now = DateTime.UtcNow;
            string fullPath = ViewModel.CurrentDirectory == "/" ? $"/{item.Name}" : $"{ViewModel.CurrentDirectory}/{item.Name}";
            bool isDoubleClick = (now - _lastClickTime < TimeSpan.FromMilliseconds(500)) && _lastClickedPath == fullPath;
            _lastClickTime = now;
            _lastClickedPath = fullPath;

            if (isDoubleClick || ExternalEditorManager.Shared.AlwaysOpenInExternalEditor)
            {
                await OpenFileInExternalEditorAsync(item, fullPath);
            }
            else
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
            if (item.IsFile)
            {
                string fullPath = ViewModel.CurrentDirectory == "/" ? $"/{item.Name}" : $"{ViewModel.CurrentDirectory}/{item.Name}";
                await OpenFileInExternalEditorAsync(item, fullPath);
            }
            else
            {
                await ViewModel.OpenFileAsync(item);
                UpdateUI();
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
            string fullPath = ViewModel.CurrentDirectory == "/" ? $"/{item.Name}" : $"{ViewModel.CurrentDirectory}/{item.Name}";
            await OpenFileInExternalEditorAsync(item, fullPath);
        }
    }

    private async Task OpenFileInExternalEditorAsync(ServerFileItem item, string fullPath)
    {
        if (ViewModel == null) return;

        try
        {
            FileSuccessText.Text = $"Ouverture de {item.Name} dans l'éditeur externe...";
            FileSuccessBanner.Visibility = Visibility.Visible;
            FileErrorBanner.Visibility = Visibility.Collapsed;

            string content = await ServerFilesService.Shared.ReadFileAsync(ViewModel.Server.Identifier, fullPath);
            await ExternalEditorManager.Shared.OpenAndWatchFileAsync(
                ViewModel.Server.Identifier,
                fullPath,
                item.Name,
                content,
                async (newContent) =>
                {
                    try
                    {
                        await ServerFilesService.Shared.WriteFileAsync(ViewModel.Server.Identifier, fullPath, newContent);
                        DispatcherQueue?.TryEnqueue(() =>
                        {
                            if (ViewModel.SelectedFile?.Name == item.Name)
                            {
                                ViewModel.FileEditorContent = newContent;
                            }
                        });
                    }
                    catch (Exception ex)
                    {
                        DispatcherQueue?.TryEnqueue(() =>
                        {
                            FileErrorText.Text = $"Échec de synchronisation de {item.Name} : {ex.Message}";
                            FileErrorBanner.Visibility = Visibility.Visible;
                        });
                        throw;
                    }
                }
            );

            _ = Task.Run(async () =>
            {
                await Task.Delay(2500);
                DispatcherQueue?.TryEnqueue(() =>
                {
                    if (FileSuccessText.Text.StartsWith("Ouverture"))
                    {
                        FileSuccessBanner.Visibility = Visibility.Collapsed;
                    }
                });
            });
        }
        catch (Exception ex)
        {
            FileErrorText.Text = $"Erreur éditeur externe : {ex.Message}";
            FileErrorBanner.Visibility = Visibility.Visible;
            FileSuccessBanner.Visibility = Visibility.Collapsed;
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
            EditorSaveStatusText.Text = "Fichier enregistré !";
        }
    }
}
