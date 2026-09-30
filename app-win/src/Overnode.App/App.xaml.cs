using System;
using System.Diagnostics;
using System.IO;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;

namespace Overnode.App;

public partial class App : Application
{
    private Window? _window;

    public App()
    {
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

