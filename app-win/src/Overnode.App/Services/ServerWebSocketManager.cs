using System;
using System.Net.WebSockets;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using Overnode.App.Models;

namespace Overnode.App.Services;

public class LivePteroStats
{
    [JsonPropertyName("cpu_absolute")]
    public double? CpuAbsolute { get; set; }

    [JsonPropertyName("disk_bytes")]
    public double? DiskBytes { get; set; }

    [JsonPropertyName("memory_bytes")]
    public double? MemoryBytes { get; set; }

    [JsonPropertyName("memory_limit_bytes")]
    public double? MemoryLimitBytes { get; set; }

    [JsonPropertyName("state")]
    public string? State { get; set; }
}

public sealed class ServerWebSocketManager
{
    private static readonly Lazy<ServerWebSocketManager> _instance = new(() => new ServerWebSocketManager());
    public static ServerWebSocketManager Instance => _instance.Value;
    public static ServerWebSocketManager Shared => _instance.Value;

    private ClientWebSocket? _webSocket;
    private CancellationTokenSource? _cts;
    private string? _currentServerId;
    private bool _isConnected;
    private bool _isAuthenticated;

    public bool IsConnected => _isConnected && _webSocket?.State == WebSocketState.Open;
    public bool IsAuthenticated => _isAuthenticated && IsConnected;

    public event Action<string>? ConsoleOutputReceived;
    public event Action<string>? StatusChanged;
    public event Action<LivePteroStats>? StatsUpdated;

    private readonly Regex _ansiRegex = new(@"\x1B\[[0-9;]*[a-zA-Z]", RegexOptions.Compiled);

    private ServerWebSocketManager() { }

    public class WsCredsResponse
    {
        public class InnerData
        {
            [JsonPropertyName("token")]
            public string Token { get; set; } = string.Empty;

            [JsonPropertyName("socket")]
            public string Socket { get; set; } = string.Empty;
        }

        [JsonPropertyName("data")]
        public InnerData? Data { get; set; }
    }

    public static async Task<(string state, double cpu, double memBytes, double diskBytes)?> FetchSingleServerLiveStatsAsync(string serverId)
    {
        if (string.IsNullOrWhiteSpace(serverId)) return null;

        try
        {
            var creds = await APIClient.Shared.GetAsync<WsCredsResponse>($"/api/server/{serverId}/websocket");
            if (creds?.Data == null || string.IsNullOrWhiteSpace(creds.Data.Socket) || string.IsNullOrWhiteSpace(creds.Data.Token))
            {
                return null;
            }

            if (!Uri.TryCreate(creds.Data.Socket, UriKind.Absolute, out var socketUri))
            {
                return null;
            }

            using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(3.5));
            using var ws = new ClientWebSocket();

            try
            {
                string origin = APIClient.Shared.BaseUri.ToString().TrimEnd('/');
                ws.Options.SetRequestHeader("Origin", origin);
            }
            catch { }

            ws.Options.RemoteCertificateValidationCallback = (sender, cert, chain, sslPolicyErrors) => true;
            ws.Options.KeepAliveInterval = TimeSpan.FromSeconds(10);

            await ws.ConnectAsync(socketUri, cts.Token);

            var authPayload = JsonSerializer.Serialize(new
            {
                @event = "auth",
                args = new[] { creds.Data.Token }
            });
            await ws.SendAsync(new ArraySegment<byte>(Encoding.UTF8.GetBytes(authPayload)), WebSocketMessageType.Text, true, cts.Token);

            string recordedState = "offline";
            bool receivedStatus = false;
            var buffer = new byte[16 * 1024];
            var messageBuffer = new StringBuilder();

            while (!cts.IsCancellationRequested && ws.State == WebSocketState.Open)
            {
                var result = await ws.ReceiveAsync(new ArraySegment<byte>(buffer), cts.Token);
                if (result.MessageType == WebSocketMessageType.Close)
                {
                    break;
                }

                messageBuffer.Append(Encoding.UTF8.GetString(buffer, 0, result.Count));
                if (result.EndOfMessage)
                {
                    string fullMessage = messageBuffer.ToString();
                    messageBuffer.Clear();

                    try
                    {
                        using var doc = JsonDocument.Parse(fullMessage);
                        var root = doc.RootElement;
                        if (root.TryGetProperty("event", out var eventProp))
                        {
                            string? evt = eventProp.GetString();
                            if (evt == "auth success")
                            {
                                var statsReq = JsonSerializer.Serialize(new
                                {
                                    @event = "send stats",
                                    args = new object?[] { null }
                                });
                                await ws.SendAsync(new ArraySegment<byte>(Encoding.UTF8.GetBytes(statsReq)), WebSocketMessageType.Text, true, cts.Token);
                            }
                            else if (evt == "status")
                            {
                                if (root.TryGetProperty("args", out var argsProp) && argsProp.ValueKind == JsonValueKind.Array)
                                {
                                    var enumerator = argsProp.EnumerateArray();
                                    if (enumerator.MoveNext() && enumerator.Current.ValueKind == JsonValueKind.String)
                                    {
                                        recordedState = enumerator.Current.GetString() ?? "offline";
                                        receivedStatus = true;
                                    }
                                }
                            }
                            else if (evt == "stats")
                            {
                                if (root.TryGetProperty("args", out var argsProp) && argsProp.ValueKind == JsonValueKind.Array)
                                {
                                    var enumerator = argsProp.EnumerateArray();
                                    if (enumerator.MoveNext())
                                    {
                                        var arg = enumerator.Current;
                                        LivePteroStats? stats = null;
                                        if (arg.ValueKind == JsonValueKind.String)
                                        {
                                            stats = JsonSerializer.Deserialize<LivePteroStats>(arg.GetString() ?? "{}");
                                        }
                                        else if (arg.ValueKind == JsonValueKind.Object)
                                        {
                                            stats = JsonSerializer.Deserialize<LivePteroStats>(arg.GetRawText());
                                        }

                                        if (stats != null)
                                        {
                                            string finalState = !string.IsNullOrEmpty(stats.State) ? stats.State : recordedState;
                                            double cpu = stats.CpuAbsolute ?? 0;
                                            double mem = stats.MemoryBytes ?? 0;
                                            double disk = stats.DiskBytes ?? 0;

                                            try
                                            {
                                                await ws.CloseAsync(WebSocketCloseStatus.NormalClosure, "Done", CancellationToken.None);
                                            }
                                            catch { }

                                            return (finalState, cpu, mem, disk);
                                        }
                                    }
                                }
                            }
                        }
                    }
                    catch { }
                }
            }

            if (receivedStatus)
            {
                return (recordedState, 0, 0, 0);
            }
        }
        catch
        {
            // Timeout or network error
        }

        return null;
    }

    public void Connect(string serverId)
    {
        if (string.IsNullOrWhiteSpace(serverId)) return;

        Disconnect();
        _currentServerId = serverId;
        _cts = new CancellationTokenSource();

        _ = Task.Run(() => ConnectAndListenAsync(serverId, _cts.Token));
    }

    private async Task ConnectAndListenAsync(string serverId, CancellationToken ct)
    {
        try
        {
            var creds = await APIClient.Shared.GetAsync<WsCredsResponse>($"/api/server/{serverId}/websocket");
            if (creds?.Data == null || string.IsNullOrWhiteSpace(creds.Data.Socket) || string.IsNullOrWhiteSpace(creds.Data.Token))
            {
                return;
            }

            if (!Uri.TryCreate(creds.Data.Socket, UriKind.Absolute, out var socketUri))
            {
                return;
            }

            _webSocket = new ClientWebSocket();
            
            // Set Origin matching the API base
            try
            {
                string origin = APIClient.Shared.BaseUri.ToString().TrimEnd('/');
                _webSocket.Options.SetRequestHeader("Origin", origin);
            }
            catch { }

            // Support daemons with custom or self-signed certs
            _webSocket.Options.RemoteCertificateValidationCallback = (sender, cert, chain, sslPolicyErrors) => true;
            _webSocket.Options.KeepAliveInterval = TimeSpan.FromSeconds(20);

            // Connect
            await _webSocket.ConnectAsync(socketUri, ct);
            _isConnected = true;

            // Send auth event
            await SendJsonAsync(new
            {
                @event = "auth",
                args = new[] { creds.Data.Token }
            }, ct);

            // Receive loop
            var buffer = new byte[16 * 1024];
            var messageBuffer = new StringBuilder();

            while (!ct.IsCancellationRequested && _webSocket.State == WebSocketState.Open)
            {
                var result = await _webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), ct);
                if (result.MessageType == WebSocketMessageType.Close)
                {
                    break;
                }

                string chunk = Encoding.UTF8.GetString(buffer, 0, result.Count);
                messageBuffer.Append(chunk);

                if (result.EndOfMessage)
                {
                    string fullMessage = messageBuffer.ToString();
                    messageBuffer.Clear();
                    HandleIncomingMessage(fullMessage, ct);
                }
            }
        }
        catch (OperationCanceledException)
        {
            // Normal shutdown
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[ServerWebSocketManager] Connection error: {ex.Message}");
        }
        finally
        {
            _isConnected = false;
        }
    }

    private void HandleIncomingMessage(string text, CancellationToken ct)
    {
        try
        {
            using var doc = JsonDocument.Parse(text);
            var root = doc.RootElement;
            if (!root.TryGetProperty("event", out var eventProp)) return;

            string? evt = eventProp.GetString();
            if (string.IsNullOrEmpty(evt)) return;

            JsonElement.ArrayEnumerator argsEnum = default;
            if (root.TryGetProperty("args", out var argsProp) && argsProp.ValueKind == JsonValueKind.Array)
            {
                argsEnum = argsProp.EnumerateArray();
            }

            switch (evt)
            {
                case "auth success":
                    _isAuthenticated = true;
                    // Ask Wings for buffered logs & initial stats
                    _ = SendJsonAsync(new { @event = "send logs", args = new object?[] { null } }, ct);
                    _ = SendJsonAsync(new { @event = "send stats", args = new object?[] { null } }, ct);
                    break;

                case "token expiring":
                    _ = RefreshTokenAsync(ct);
                    break;

                case "jwt error":
                    _isAuthenticated = false;
                    _ = RefreshTokenAsync(ct);
                    break;

                case "console output":
                    if (argsEnum.MoveNext() && argsEnum.Current.ValueKind == JsonValueKind.String)
                    {
                        string line = argsEnum.Current.GetString() ?? string.Empty;
                        string clean = _ansiRegex.Replace(line, string.Empty);
                        try { ConsoleOutputReceived?.Invoke(clean); } catch { }
                    }
                    break;

                case "status":
                    if (argsEnum.MoveNext() && argsEnum.Current.ValueKind == JsonValueKind.String)
                    {
                        string st = argsEnum.Current.GetString() ?? string.Empty;
                        try { StatusChanged?.Invoke(st); } catch { }
                    }
                    break;

                case "stats":
                    if (argsEnum.MoveNext())
                    {
                        var argElem = argsEnum.Current;
                        LivePteroStats? stats = null;

                        if (argElem.ValueKind == JsonValueKind.String)
                        {
                            string jsonStr = argElem.GetString() ?? "{}";
                            stats = JsonSerializer.Deserialize<LivePteroStats>(jsonStr);
                        }
                        else if (argElem.ValueKind == JsonValueKind.Object)
                        {
                            stats = JsonSerializer.Deserialize<LivePteroStats>(argElem.GetRawText());
                        }

                        if (stats != null)
                        {
                            try { StatsUpdated?.Invoke(stats); } catch { }
                        }
                    }
                    break;
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[ServerWebSocketManager] Parse error: {ex.Message}");
        }
    }

    private async Task RefreshTokenAsync(CancellationToken ct)
    {
        if (string.IsNullOrEmpty(_currentServerId)) return;
        try
        {
            var creds = await APIClient.Shared.GetAsync<WsCredsResponse>($"/api/server/{_currentServerId}/websocket");
            if (creds?.Data != null && !string.IsNullOrWhiteSpace(creds.Data.Token))
            {
                await SendJsonAsync(new
                {
                    @event = "auth",
                    args = new[] { creds.Data.Token }
                }, ct);
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[ServerWebSocketManager] Token refresh error: {ex.Message}");
        }
    }

    public void SendCommand(string command)
    {
        if (string.IsNullOrWhiteSpace(command)) return;

        if (!IsConnected && !string.IsNullOrWhiteSpace(_currentServerId))
        {
            Connect(_currentServerId);
        }

        _ = SendJsonAsync(new
        {
            @event = "send command",
            args = new[] { command }
        }, CancellationToken.None);
    }

    public void SendPowerSignal(ServerPowerSignal signal)
    {
        if (!IsConnected && !string.IsNullOrWhiteSpace(_currentServerId))
        {
            Connect(_currentServerId);
        }

        _ = SendJsonAsync(new
        {
            @event = "set state",
            args = new[] { signal.ToSignalString() }
        }, CancellationToken.None);
    }

    private async Task SendJsonAsync(object payload, CancellationToken ct)
    {
        if (_webSocket == null || _webSocket.State != WebSocketState.Open) return;

        try
        {
            string json = JsonSerializer.Serialize(payload);
            byte[] bytes = Encoding.UTF8.GetBytes(json);
            await _webSocket.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, ct);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[ServerWebSocketManager] Send error: {ex.Message}");
        }
    }

    public void Disconnect()
    {
        try
        {
            _cts?.Cancel();
            _cts?.Dispose();
            _cts = null;

            if (_webSocket != null)
            {
                if (_webSocket.State == WebSocketState.Open)
                {
                    _webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closing", CancellationToken.None).GetAwaiter().GetResult();
                }
                _webSocket.Dispose();
                _webSocket = null;
            }
        }
        catch
        {
        }
        finally
        {
            _isConnected = false;
            _isAuthenticated = false;
            _currentServerId = null;
        }
    }
}
