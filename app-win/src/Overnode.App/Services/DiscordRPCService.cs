using System;
using System.Diagnostics;
using System.IO;
using System.IO.Pipes;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Overnode.App.Localization;

namespace Overnode.App.Services;

public sealed class DiscordRPCService : IDisposable
{
    private static readonly Lazy<DiscordRPCService> _instance = new(() => new DiscordRPCService());
    public static DiscordRPCService Instance => _instance.Value;
    public static DiscordRPCService Shared => _instance.Value;

    public const string DefaultClientId = "972921155205877860";
    public const string DefaultLargeImage = "https://cdn.discordapp.com/app-icons/972921155205877860/256fde33d60f15e1d524a187b359e9b9.png";
    public const string DefaultWebsiteUrl = "https://overnode.fr";

    private NamedPipeClientStream? _pipeStream;
    private CancellationTokenSource? _cts;
    private readonly long _startTime = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
    private bool _isRunning;
    private bool _isConnected;

    public bool IsConnected => _isConnected;

    private DiscordRPCService()
    {
        LocalizationManager.Instance.LanguageChanged += (_, _) =>
        {
            if (_isConnected)
            {
                _ = SendDefaultActivityAsync();
            }
        };
    }

    public void Start()
    {
        if (_isRunning) return;
        _isRunning = true;
        _cts = new CancellationTokenSource();
        Task.Run(() => ConnectionLoopAsync(_cts.Token));
    }

    public void Stop()
    {
        _isRunning = false;
        _cts?.Cancel();
        Disconnect();
    }

    private async Task ConnectionLoopAsync(CancellationToken token)
    {
        while (_isRunning && !token.IsCancellationRequested)
        {
            if (!_isConnected)
            {
                for (int i = 0; i < 10; i++)
                {
                    if (token.IsCancellationRequested) break;
                    string pipeName = $"discord-ipc-{i}";

                    try
                    {
                        var pipe = new NamedPipeClientStream(".", pipeName, PipeDirection.InOut, PipeOptions.Asynchronous);
                        using var timeoutCts = new CancellationTokenSource(TimeSpan.FromSeconds(2));
                        using var linkedCts = CancellationTokenSource.CreateLinkedTokenSource(token, timeoutCts.Token);

                        await pipe.ConnectAsync(linkedCts.Token);
                        if (pipe.IsConnected)
                        {
                            _pipeStream = pipe;
                            if (await SendHandshakeAsync(token))
                            {
                                _isConnected = true;
                                await SendDefaultActivityAsync(token);
                                _ = Task.Run(() => ReadLoopAsync(token), token);
                                break;
                            }
                            else
                            {
                                Disconnect();
                            }
                        }
                    }
                    catch
                    {
                        // Discord not running on this pipe or timeout
                        Disconnect();
                    }
                }
            }

            try
            {
                await Task.Delay(15000, token);
            }
            catch (OperationCanceledException)
            {
                break;
            }
        }
    }

    private async Task<bool> SendHandshakeAsync(CancellationToken token)
    {
        if (_pipeStream == null || !_pipeStream.IsConnected) return false;

        try
        {
            var payload = new
            {
                v = 1,
                client_id = DefaultClientId
            };

            await SendFrameAsync(0, payload, token);
            var (op, responseJson) = await ReadFrameAsync(token);
            return op == 1; // 1 = Frame acknowledged
        }
        catch
        {
            return false;
        }
    }

    public async Task SendDefaultActivityAsync(CancellationToken token = default)
    {
        if (_pipeStream == null || !_pipeStream.IsConnected) return;

        try
        {
            int pid = Environment.ProcessId;
            var payload = new
            {
                cmd = "SET_ACTIVITY",
                args = new
                {
                    pid,
                    activity = new
                    {
                        details = LocalizationManager.Instance.GetString("discord_rpc_details"),
                        state = LocalizationManager.Instance.GetString("discord_rpc_state"),
                        timestamps = new
                        {
                            start = _startTime
                        },
                        assets = new
                        {
                            large_image = DefaultLargeImage,
                            large_text = "Overnode App"
                        },
                        buttons = new[]
                        {
                            new { label = LocalizationManager.Instance.GetString("discord_rpc_site"), url = DefaultWebsiteUrl }
                        }
                    }
                },
                nonce = Guid.NewGuid().ToString()
            };

            await SendFrameAsync(1, payload, token);
        }
        catch
        {
            Disconnect();
        }
    }

    private async Task SendFrameAsync(int opcode, object payload, CancellationToken token)
    {
        if (_pipeStream == null || !_pipeStream.IsConnected) return;

        string json = JsonSerializer.Serialize(payload);
        byte[] jsonBytes = Encoding.UTF8.GetBytes(json);

        byte[] header = new byte[8];
        BitConverter.TryWriteBytes(header.AsSpan(0, 4), opcode);
        BitConverter.TryWriteBytes(header.AsSpan(4, 4), jsonBytes.Length);

        await _pipeStream.WriteAsync(header, 0, 8, token);
        await _pipeStream.WriteAsync(jsonBytes, 0, jsonBytes.Length, token);
        await _pipeStream.FlushAsync(token);
    }

    private async Task<(int opcode, string json)> ReadFrameAsync(CancellationToken token)
    {
        if (_pipeStream == null || !_pipeStream.IsConnected) return (-1, string.Empty);

        byte[] header = new byte[8];
        int bytesRead = await _pipeStream.ReadAsync(header, 0, 8, token);
        if (bytesRead < 8) return (-1, string.Empty);

        int opcode = BitConverter.ToInt32(header, 0);
        int length = BitConverter.ToInt32(header, 4);

        if (length <= 0 || length > 65536) return (opcode, string.Empty);

        byte[] buffer = new byte[length];
        int totalRead = 0;
        while (totalRead < length)
        {
            int r = await _pipeStream.ReadAsync(buffer, totalRead, length - totalRead, token);
            if (r == 0) break;
            totalRead += r;
        }

        string json = Encoding.UTF8.GetString(buffer, 0, totalRead);
        return (opcode, json);
    }

    private async Task ReadLoopAsync(CancellationToken token)
    {
        while (_isConnected && _pipeStream != null && _pipeStream.IsConnected && !token.IsCancellationRequested)
        {
            try
            {
                var (op, _) = await ReadFrameAsync(token);
                if (op == 2) // Close frame
                {
                    Disconnect();
                    break;
                }
            }
            catch
            {
                Disconnect();
                break;
            }
        }
    }

    private void Disconnect()
    {
        _isConnected = false;
        try
        {
            _pipeStream?.Dispose();
        }
        catch
        {
        }
        _pipeStream = null;
    }

    public void Dispose()
    {
        Stop();
    }
}
