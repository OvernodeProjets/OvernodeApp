using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;

namespace Overnode.App;

public partial class App : Application
{
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    private static extern IntPtr FindWindowW(string? lpClassName, string lpWindowName);

    [DllImport("user32.dll")]
    private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    private static extern bool SetForegroundWindow(IntPtr hWnd);

    private const int SW_RESTORE = 9;
    private const int SW_SHOW = 5;

    private static Mutex? _singleInstanceMutex;
    private Window? _window;

    public App()
    {
        bool isNewInstance;
        try
        {
            _singleInstanceMutex = new Mutex(true, @"Local\OvernodeApp_SingleInstance_Mutex", out isNewInstance);
        }
        catch
        {
            isNewInstance = true;
        }

        if (!isNewInstance)
        {
            // Another instance is already running!
            // Restore existing window to foreground and exit immediately to prevent duplicate tray icons
            try
            {
                IntPtr existingHwnd = FindWindowW(null, "Overnode");
                if (existingHwnd != IntPtr.Zero)
                {
                    ShowWindow(existingHwnd, SW_RESTORE);
                    ShowWindow(existingHwnd, SW_SHOW);
                    SetForegroundWindow(existingHwnd);
                }
            }
            catch { }

            Environment.Exit(0);
            return;
        }

        InitializeComponent();
        UnhandledException += (s, e) =>
        {
            Debug.WriteLine($"[{DateTime.Now}] UNHANDLED (WinUI): {e.Exception}");
            e.Handled = true;
        };
        AppDomain.CurrentDomain.UnhandledException += (s, e) =>
        {
            Debug.WriteLine($"[{DateTime.Now}] UNHANDLED (AppDomain): {e.ExceptionObject}");
        };
        TaskScheduler.UnobservedTaskException += (s, e) =>
        {
            Debug.WriteLine($"[{DateTime.Now}] UNOBSERVED TASK: {e.Exception}");
        };
        AppDomain.CurrentDomain.ProcessExit += (s, e) =>
        {
            try
            {
                Services.TrayIconManager.Shared.Dispose();
            }
            catch { }
            try
            {
                _singleInstanceMutex?.ReleaseMutex();
                _singleInstanceMutex?.Dispose();
                _singleInstanceMutex = null;
            }
            catch { }
            Debug.WriteLine($"[{DateTime.Now}] PROCESS EXIT! StackTrace:\n{Environment.StackTrace}");
        };
    }

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        try
        {
            _window = new MainWindow();
            _window.Activate();

            // Start Discord Rich Presence in background
            try
            {
                Services.DiscordRPCService.Shared.Start();
            }
            catch
            {
            }
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"[{DateTime.Now}] CRASH in OnLaunched: {ex}");
        }
    }
}
