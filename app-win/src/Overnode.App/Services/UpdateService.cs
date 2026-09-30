using System;
using System.Diagnostics;
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Overnode.App.Models;

namespace Overnode.App.Services;

public sealed class UpdateService
{
    private static readonly Lazy<UpdateService> _instance = new(() => new UpdateService());
    public static UpdateService Shared => _instance.Value;

    public const string DefaultUpdaterUrlString = "https://zBvoGzjDABxGuLuKux59LtECbKIpNPcp.overnode.fr";

    public const string Platform = "win-x64";

    private readonly HttpClient _httpClient;

    public UpdateService(HttpClient? httpClient = null)
    {
        _httpClient = httpClient ?? new HttpClient { Timeout = TimeSpan.FromSeconds(60) };
    }

    public string CurrentAppVersion
    {
        get
        {
            var version = typeof(UpdateService).Assembly.GetName().Version;
            if (version != null)
            {
                return $"{version.Major}.{version.Minor}.{Math.Max(0, version.Build)}";
            }
            return "1.0.0";
        }
    }

    public Uri UpdaterBaseUrl
    {
        get
        {
            var envUrl = Environment.GetEnvironmentVariable("OVERNODE_UPDATER_URL");
            if (!string.IsNullOrWhiteSpace(envUrl) && Uri.TryCreate(envUrl, UriKind.Absolute, out var uri))
            {
                return uri;
            }
            return new Uri(DefaultUpdaterUrlString);
        }
    }

    public async Task<UpdateCheckResponse> CheckForUpdatesAsync(string? version = null, CancellationToken ct = default)
    {
        var ver = version ?? CurrentAppVersion;

        var requestUri = new Uri(UpdaterBaseUrl, $"api/v1/update/check?version={Uri.EscapeDataString(ver)}&platform={Uri.EscapeDataString(Platform)}");

        using var request = new HttpRequestMessage(HttpMethod.Get, requestUri);
        request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        request.Headers.UserAgent.ParseAdd($"Overnode-Updater-Client/{ver}");

        try
        {
            using var response = await _httpClient.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, ct).ConfigureAwait(false);
            response.EnsureSuccessStatusCode();

            var json = await response.Content.ReadAsStringAsync(ct).ConfigureAwait(false);
            var result = JsonSerializer.Deserialize<UpdateCheckResponse>(json);
            if (result == null)
            {
                throw new InvalidOperationException("Échec de désérialisation de la réponse du serveur de mise à jour.");
            }
            return result;
        }
        catch (Exception)
        {
            // Demo fallback if OVERNODE_DEMO environment variable is defined
            if (Environment.GetEnvironmentVariable("OVERNODE_DEMO") != null)
            {
                return new UpdateCheckResponse
                {
                    UpdateAvailable = true,
                    ClientVersion = ver,
                    LatestVersion = "1.1.0",
                    DownloadUrl = "https://github.com/OvernodeProjets/OvernodeApp/releases/download/v1.1.0/Overnode-v1.1.0-Windows-x64.msi",
                    RawDownloadUrl = "https://github.com/OvernodeProjets/OvernodeApp/releases/download/v1.1.0/Overnode-v1.1.0-Windows-x64.msi",
                    ReleaseNotes = "• Système de mise à jour automatique en temps réel Windows\n• Package MSI natif avec prise en charge des raccourcis et icône d'application\n• Améliorations de performance et corrections de stabilité",
                    Mandatory = false,
                    Platform = Platform
                };
            }
            throw;
        }
    }

    public async Task<string> DownloadUpdateAsync(
        string urlString,
        string? expectedSha256 = null,
        IProgress<double>? progress = null,
        CancellationToken ct = default)
    {
        if (!Uri.TryCreate(urlString, UriKind.Absolute, out var targetUri))
        {
            throw new ArgumentException("URL de téléchargement invalide.", nameof(urlString));
        }

        var tempDir = Path.Combine(Path.GetTempPath(), "Overnode-Updates");
        Directory.CreateDirectory(tempDir);

        var destinationFile = Path.Combine(tempDir, $"Overnode-Update-{Guid.NewGuid():N}.msi");

        using var request = new HttpRequestMessage(HttpMethod.Get, targetUri);
        request.Headers.UserAgent.ParseAdd($"Overnode-Updater-Client/{CurrentAppVersion}");

        using var response = await _httpClient.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, ct).ConfigureAwait(false);
        response.EnsureSuccessStatusCode();

        var totalBytes = response.Content.Headers.ContentLength ?? -1L;

        await using var contentStream = await response.Content.ReadAsStreamAsync(ct).ConfigureAwait(false);
        await using var fileStream = new FileStream(destinationFile, FileMode.Create, FileAccess.Write, FileShare.None, 81920, true);

        using var sha256 = SHA256.Create();
        var buffer = new byte[81920];
        long totalRead = 0;
        int bytesRead;

        while ((bytesRead = await contentStream.ReadAsync(buffer.AsMemory(0, buffer.Length), ct).ConfigureAwait(false)) > 0)
        {
            await fileStream.WriteAsync(buffer.AsMemory(0, bytesRead), ct).ConfigureAwait(false);
            sha256.TransformBlock(buffer, 0, bytesRead, null, 0);

            totalRead += bytesRead;
            if (totalBytes > 0 && progress != null)
            {
                progress.Report(Math.Min(1.0, (double)totalRead / totalBytes));
            }
        }

        sha256.TransformFinalBlock(Array.Empty<byte>(), 0, 0);
        progress?.Report(1.0);

        if (totalRead < 50_000)
        {
            try { File.Delete(destinationFile); } catch { }
            throw new InvalidDataException($"Fichier de mise à jour incomplet ou corrompu (taille: {totalRead} octets).");
        }

        if (!string.IsNullOrWhiteSpace(expectedSha256) && sha256.Hash != null)
        {
            var computedHashHex = Convert.ToHexString(sha256.Hash).ToLowerInvariant();
            var normalizedExpected = expectedSha256.Trim().ToLowerInvariant();

            if (!string.Equals(computedHashHex, normalizedExpected, StringComparison.OrdinalIgnoreCase))
            {
                try { File.Delete(destinationFile); } catch { }
                throw new InvalidDataException(
                    $"Vérification d'intégrité échouée. Le hash SHA-256 ne correspond pas (attendu: {normalizedExpected[..Math.Min(16, normalizedExpected.Length)]}..., obtenu: {computedHashHex[..Math.Min(16, computedHashHex.Length)]}...).");
            }
        }

        return destinationFile;
    }

    public void LaunchInstallerAndRestart(string msiPath)
    {
        if (!File.Exists(msiPath))
        {
            throw new FileNotFoundException("Le fichier d'installation MSI est introuvable.", msiPath);
        }

        var currentProcess = Process.GetCurrentProcess();
        var currentPid = currentProcess.Id;
        var processPath = Environment.ProcessPath ?? Path.Combine(AppContext.BaseDirectory, "Overnode.App.exe");

        var scriptDir = Path.Combine(Path.GetTempPath(), "Overnode-Updates");
        Directory.CreateDirectory(scriptDir);
        var scriptPath = Path.Combine(scriptDir, $"overnode_restart_{currentPid}.cmd");

        var scriptContent = $@"@echo off
chcp 65001 >nul
:WAIT_PROCESS
tasklist /fi ""PID eq {currentPid}"" | find ""{currentPid}"" >nul
if %ERRORLEVEL%==0 (
    timeout /t 1 /nobreak >nul
    goto WAIT_PROCESS
)

echo Installation de la mise à jour Overnode...
start /wait msiexec.exe /i ""{msiPath}"" /passive

echo Redémarrage d'Overnode...
start """" ""{processPath}""

del ""%~f0""
";

        File.WriteAllText(scriptPath, scriptContent);

        var startInfo = new ProcessStartInfo
        {
            FileName = "cmd.exe",
            Arguments = $"/c \"{scriptPath}\"",
            UseShellExecute = false,
            CreateNoWindow = true
        };

        Process.Start(startInfo);

        // Terminate old process cleanly
        Environment.Exit(0);
    }
}
