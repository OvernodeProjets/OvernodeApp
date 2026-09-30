using System;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Reflection;
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
            var assembly = typeof(UpdateService).Assembly;
            var version = assembly.GetName().Version;
            if (version != null && (version.Major > 0 || version.Minor > 0 || version.Build > 0))
            {
                return $"{version.Major}.{version.Minor}.{Math.Max(0, version.Build)}";
            }

            var infoVer = assembly.GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion;
            if (!string.IsNullOrWhiteSpace(infoVer))
            {
                var clean = infoVer.Split('+')[0].Trim().TrimStart('v');
                if (!string.IsNullOrWhiteSpace(clean)) return clean;
            }

            return "1.1.4";
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
        var programFilesDir = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
        var installedExePath = Path.Combine(programFilesDir, "Overnode", "Overnode.App.exe");

        var scriptDir = Path.Combine(Path.GetTempPath(), "Overnode-Updates");
        Directory.CreateDirectory(scriptDir);
        var scriptPath = Path.Combine(scriptDir, $"overnode_updater_{currentPid}.ps1");
        var logPath = Path.Combine(scriptDir, $"install_{currentPid}.log");

        var psScript = $$"""
# Overnode Elevated Updater Script
$ErrorActionPreference = 'SilentlyContinue'
$targetPid = {{currentPid}}
$msi = '{{msiPath.Replace("'", "''")}}'
$installedExe = '{{installedExePath.Replace("'", "''")}}'
$fallbackExe = '{{processPath.Replace("'", "''")}}'
$logPath = '{{logPath.Replace("'", "''")}}'

# 1. Wait for current Overnode process to terminate cleanly
if ($targetPid -gt 0) {
    Wait-Process -Id $targetPid -Timeout 20 -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 600
}

# 2. Run MSI installation passively with no restart
$msiArgs = @('/i', "$msi", '/passive', '/norestart', '/lv*', "$logPath")
$proc = Start-Process -FilePath msiexec.exe -ArgumentList $msiArgs -PassThru -Wait

# 3. Determine executable to launch
$targetExe = if (Test-Path $installedExe) { $installedExe } else { $fallbackExe }

# 4. Relaunch the updated application
if (Test-Path $targetExe) {
    Start-Process -FilePath $targetExe
}

# 5. Clean up temporary updater files
Start-Sleep -Seconds 2
Remove-Item -Path $msi -Force -ErrorAction SilentlyContinue
Remove-Item -Path $MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue
""";

        File.WriteAllText(scriptPath, psScript);

        var startInfo = new ProcessStartInfo
        {
            FileName = "powershell.exe",
            Arguments = $"-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File \"{scriptPath}\"",
            UseShellExecute = true,
            Verb = "runas"
        };

        try
        {
            Process.Start(startInfo);
        }
        catch (Win32Exception winEx) when (winEx.NativeErrorCode == 1223)
        {
            // ERROR_CANCELLED: User clicked 'No' on UAC prompt
            throw new InvalidOperationException("La mise à jour nécessite les droits administrateur pour s'installer dans Program Files. L'opération a été annulée.", winEx);
        }
        catch (Exception)
        {
            // Fallback without runas verb if execution policy or restrictions prevent elevation verb
            startInfo.Verb = "";
            Process.Start(startInfo);
        }

        // Terminate old process cleanly to allow MSI to overwrite files
        Environment.Exit(0);
    }
}
