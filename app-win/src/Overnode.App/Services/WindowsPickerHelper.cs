using System;
using System.IO;
using System.Threading.Tasks;
using Windows.Storage.Pickers;

namespace Overnode.App.Services;

/// <summary>
/// Utilitaire d'affichage des sélecteurs natifs Windows (choix d'exécutable pour éditeur et choix de dossier pour synchronisation).
/// </summary>
public static class WindowsPickerHelper
{
    /// <summary>
    /// Fournisseur de handle de fenêtre active pour l'initialisation des pickers WinUI / WinRT.
    /// </summary>
    public static Func<IntPtr>? ActiveWindowHandleProvider { get; set; }

    public static async Task<IReadOnlyList<string>?> PickMultipleFilesAsync(IntPtr hwnd = default)
    {
        try
        {
            var picker = new FileOpenPicker();
            picker.SuggestedStartLocation = PickerLocationId.ComputerFolder;
            picker.FileTypeFilter.Add("*");

            IntPtr handle = hwnd != IntPtr.Zero ? hwnd : (ActiveWindowHandleProvider?.Invoke() ?? IntPtr.Zero);
            if (handle != IntPtr.Zero)
            {
                WinRT.Interop.InitializeWithWindow.Initialize(picker, handle);
            }

            var files = await picker.PickMultipleFilesAsync();
            if (files != null && files.Count > 0)
            {
                var list = new System.Collections.Generic.List<string>(files.Count);
                foreach (var file in files)
                {
                    if (!string.IsNullOrEmpty(file.Path))
                    {
                        list.Add(file.Path);
                    }
                }
                return list;
            }
            return null;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[WindowsPickerHelper] PickMultipleFilesAsync error: {ex.Message}");
            return null;
        }
    }

    public static async Task<string?> PickExeFileAsync(IntPtr hwnd = default)
    {
        try
        {
            var picker = new FileOpenPicker();
            picker.SuggestedStartLocation = PickerLocationId.ComputerFolder;
            picker.FileTypeFilter.Add(".exe");

            IntPtr handle = hwnd != IntPtr.Zero ? hwnd : (ActiveWindowHandleProvider?.Invoke() ?? IntPtr.Zero);
            if (handle != IntPtr.Zero)
            {
                WinRT.Interop.InitializeWithWindow.Initialize(picker, handle);
            }

            var file = await picker.PickSingleFileAsync();
            return file?.Path;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[WindowsPickerHelper] PickExeFileAsync error: {ex.Message}");
            return null;
        }
    }

    public static async Task<string?> PickFolderAsync(IntPtr hwnd = default)
    {
        try
        {
            var picker = new FolderPicker();
            picker.SuggestedStartLocation = PickerLocationId.Desktop;
            picker.FileTypeFilter.Add("*");

            IntPtr handle = hwnd != IntPtr.Zero ? hwnd : (ActiveWindowHandleProvider?.Invoke() ?? IntPtr.Zero);
            if (handle != IntPtr.Zero)
            {
                WinRT.Interop.InitializeWithWindow.Initialize(picker, handle);
            }

            var folder = await picker.PickSingleFolderAsync();
            return folder?.Path;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[WindowsPickerHelper] PickFolderAsync error: {ex.Message}");
            return null;
        }
    }

    public static async Task<string?> PickImageFileAsync(IntPtr hwnd = default)
    {
        try
        {
            var picker = new FileOpenPicker();
            picker.SuggestedStartLocation = PickerLocationId.PicturesLibrary;
            picker.FileTypeFilter.Add(".png");
            picker.FileTypeFilter.Add(".jpg");
            picker.FileTypeFilter.Add(".jpeg");
            picker.FileTypeFilter.Add(".webp");
            picker.FileTypeFilter.Add(".bmp");

            IntPtr handle = hwnd != IntPtr.Zero ? hwnd : (ActiveWindowHandleProvider?.Invoke() ?? IntPtr.Zero);
            if (handle != IntPtr.Zero)
            {
                WinRT.Interop.InitializeWithWindow.Initialize(picker, handle);
            }

            var file = await picker.PickSingleFileAsync();
            return file?.Path;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[WindowsPickerHelper] PickImageFileAsync error: {ex.Message}");
            return null;
        }
    }

    public static async Task<string?> PickSaveConfigFileAsync(string defaultFileName = "config.overnode.app", IntPtr hwnd = default)
    {
        try
        {
            var picker = new FileSavePicker();
            picker.SuggestedStartLocation = PickerLocationId.Desktop;
            picker.SuggestedFileName = defaultFileName;
            picker.FileTypeChoices.Add("Overnode App Configuration", new System.Collections.Generic.List<string> { ".app", ".json" });
            picker.DefaultFileExtension = ".app";

            IntPtr handle = hwnd != IntPtr.Zero ? hwnd : (ActiveWindowHandleProvider?.Invoke() ?? IntPtr.Zero);
            if (handle != IntPtr.Zero)
            {
                WinRT.Interop.InitializeWithWindow.Initialize(picker, handle);
            }

            var file = await picker.PickSaveFileAsync();
            return file?.Path;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[WindowsPickerHelper] PickSaveConfigFileAsync error: {ex.Message}");
            return null;
        }
    }

    public static async Task<string?> PickConfigFileAsync(IntPtr hwnd = default)
    {
        try
        {
            var picker = new FileOpenPicker();
            picker.SuggestedStartLocation = PickerLocationId.Desktop;
            picker.FileTypeFilter.Add(".app");
            picker.FileTypeFilter.Add(".json");
            picker.FileTypeFilter.Add("*");

            IntPtr handle = hwnd != IntPtr.Zero ? hwnd : (ActiveWindowHandleProvider?.Invoke() ?? IntPtr.Zero);
            if (handle != IntPtr.Zero)
            {
                WinRT.Interop.InitializeWithWindow.Initialize(picker, handle);
            }

            var file = await picker.PickSingleFileAsync();
            return file?.Path;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[WindowsPickerHelper] PickConfigFileAsync error: {ex.Message}");
            return null;
        }
    }
}
