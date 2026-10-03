using System;
using System.Threading.Tasks;

namespace Overnode.App.Services;

/// <summary>
/// Stub / Mock de WindowsPickerHelper pour les tests unitaires CLI (évite les dépendances WinUI/WinRT et l'ouverture de dialogues modaux).
/// </summary>
public static class WindowsPickerHelper
{
    public static Func<IntPtr>? ActiveWindowHandleProvider { get; set; }

    public static string? MockPickedExePath { get; set; }
    public static string? MockPickedFolderPath { get; set; }

    public static Task<string?> PickExeFileAsync(IntPtr hwnd = default)
    {
        return Task.FromResult(MockPickedExePath);
    }

    public static Task<string?> PickFolderAsync(IntPtr hwnd = default)
    {
        return Task.FromResult(MockPickedFolderPath);
    }

    public static void Reset()
    {
        ActiveWindowHandleProvider = null;
        MockPickedExePath = null;
        MockPickedFolderPath = null;
    }
}
