using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;

namespace Overnode.App;

public partial class App : Application
{
    private Window? _window;
    private static readonly string LogPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.Desktop),
        "overnode_crash.log");

    public App()
    {
        InitializeComponent();
        UnhandledException += (s, e) =>
        {
            File.AppendAllText(LogPath,
                $"[{DateTime.Now}] UNHANDLED (WinUI): {e.Exception}\n");
            e.Handled = true;
        };
        AppDomain.CurrentDomain.UnhandledException += (s, e) =>
        {
            File.AppendAllText(LogPath,
                $"[{DateTime.Now}] UNHANDLED (AppDomain): {e.ExceptionObject}\n");
        };
        TaskScheduler.UnobservedTaskException += (s, e) =>
        {
            File.AppendAllText(LogPath,
                $"[{DateTime.Now}] UNOBSERVED TASK: {e.Exception}\n");
        };
    }

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        try
        {
            File.AppendAllText(LogPath, $"[{DateTime.Now}] OnLaunched start\n");
            _window = new MainWindow();
            File.AppendAllText(LogPath, $"[{DateTime.Now}] MainWindow created\n");
            _window.Activate();
            File.AppendAllText(LogPath, $"[{DateTime.Now}] Window activated OK\n");
        }
        catch (Exception ex)
        {
            File.AppendAllText(LogPath,
                $"[{DateTime.Now}] CRASH in OnLaunched: {ex}\n");
        }
    }
}
