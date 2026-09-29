using System;
using System.Threading.Tasks;
using Overnode.App.Models;
using Overnode.App.Views;

namespace Overnode.App.Services;

public sealed class DiscordAuthCoordinator
{
    private static readonly Lazy<DiscordAuthCoordinator> _instance = new(() => new DiscordAuthCoordinator());
    public static DiscordAuthCoordinator Instance => _instance.Value;

    private DiscordAuthWindow? _activeWindow;

    private DiscordAuthCoordinator() { }

    public async Task<AuthStateResponse?> StartDiscordAuthAsync()
    {
        if (_activeWindow != null)
        {
            _activeWindow.Activate();
            return await _activeWindow.AuthTask;
        }

        _activeWindow = new DiscordAuthWindow();
        _activeWindow.Activate();

        try
        {
            var result = await _activeWindow.AuthTask;
            return result;
        }
        finally
        {
            _activeWindow = null;
        }
    }
}
