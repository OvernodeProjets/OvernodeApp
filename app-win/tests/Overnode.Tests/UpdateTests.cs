using System;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Overnode.App.Models;
using Overnode.App.Services;
using Overnode.App.ViewModels;

namespace Overnode.Tests;

public static class UpdateTests
{
    public static void RunAll(Action<string, Action> run)
    {
        TestUpdateCheckResponseDeserialization(run);
        TestUpdateServiceUrlAndPlatform(run);
        TestUpdateServiceDemoMode(run);
        TestUpdateViewModelStateTransitions(run);
        TestUpdateIntegrityVerification(run);
    }

    private static void TestUpdateCheckResponseDeserialization(Action<string, Action> run)
    {
        run("UpdateCheckResponse Deserialization & Fields", () =>
        {
            var json = """
            {
                "updateAvailable": true,
                "clientVersion": "1.0.0",
                "latestVersion": "1.1.0",
                "downloadUrl": "https://zBvoGzjDABxGuLuKux59LtECbKIpNPcp.overnode.fr/api/v1/update/download?platform=win-x64&type=msi",
                "rawDownloadUrl": "https://github.com/OvernodeProjets/OvernodeApp/releases/download/v1.1.0/Overnode-v1.1.0-Windows-x64.msi",
                "releaseNotes": "• Nouveautés Windows\n• Améliorations de performance",
                "mandatory": false,
                "sha256": "4a7d1ed414474e4033ac29ccb8653d9b",
                "publishedAt": "2026-09-30T10:00:00.000Z",
                "platform": "win-x64"
            }
            """;

            var response = JsonSerializer.Deserialize<UpdateCheckResponse>(json);
            Assert.IsNotNull(response);
            Assert.IsTrue(response.UpdateAvailable);
            Assert.AreEqual("1.0.0", response.ClientVersion);
            Assert.AreEqual("1.1.0", response.LatestVersion);
            Assert.IsTrue(response.DownloadUrl.Contains("type=msi"));
            Assert.IsTrue(response.RawDownloadUrl.EndsWith(".msi"));
            Assert.AreEqual("win-x64", response.Platform);
            Assert.AreEqual("4a7d1ed414474e4033ac29ccb8653d9b", response.Sha256);
            Assert.IsFalse(response.Mandatory);
        });
    }

    private static void TestUpdateServiceUrlAndPlatform(Action<string, Action> run)
    {
        run("UpdateService Base URL & Default Platform", () =>
        {
            var service = UpdateService.Shared;
            Assert.AreEqual("win-x64", UpdateService.Platform);
            Assert.IsTrue(string.Equals(UpdateService.DefaultUpdaterUrlString, service.UpdaterBaseUrl.ToString().TrimEnd('/'), StringComparison.OrdinalIgnoreCase));
            Assert.IsNotNull(service.CurrentAppVersion);
        });
    }

    private static void TestUpdateServiceDemoMode(Action<string, Action> run)
    {
        run("UpdateService Demo Mode Fallback", () =>
        {
            var originalEnv = Environment.GetEnvironmentVariable("OVERNODE_DEMO");
            try
            {
                Environment.SetEnvironmentVariable("OVERNODE_DEMO", "1");
                // Mock HTTP client that throws network failure to trigger demo fallback
                var failingClient = new HttpClient(new FailingHttpMessageHandler());
                var service = new UpdateService(failingClient);

                var task = service.CheckForUpdatesAsync("1.0.0");
                task.Wait();
                var result = task.Result;

                Assert.IsNotNull(result);
                Assert.IsTrue(result.UpdateAvailable);
                Assert.AreEqual("1.1.0", result.LatestVersion);
                Assert.IsTrue(result.DownloadUrl.EndsWith(".msi"));
                Assert.AreEqual("win-x64", result.Platform);
            }
            finally
            {
                Environment.SetEnvironmentVariable("OVERNODE_DEMO", originalEnv);
            }
        });
    }

    private static void TestUpdateViewModelStateTransitions(Action<string, Action> run)
    {
        run("UpdateViewModel State & Visibility Flow", () =>
        {
            var mockHandler = new MockHttpMessageHandler(new UpdateCheckResponse
            {
                UpdateAvailable = true,
                ClientVersion = "1.0.0",
                LatestVersion = "1.1.44",
                DownloadUrl = "https://example.com/update.msi",
                ReleaseNotes = "Test notes",
                Mandatory = false
            });

            var client = new HttpClient(mockHandler);
            var service = new UpdateService(client);
            var vm = new UpdateViewModel(service);

            Assert.AreEqual(UpdateStatus.Idle, vm.State);
            Assert.IsFalse(vm.ShowModal);
            Assert.IsFalse(vm.HasUpdateAvailable);

            var checkTask = vm.CheckForUpdatesAsync(silent: false);
            checkTask.Wait();
            var hasUpdate = checkTask.Result;

            Assert.IsTrue(hasUpdate);
            Assert.AreEqual(UpdateStatus.Available, vm.State);
            Assert.IsTrue(vm.ShowModal);
            Assert.IsTrue(vm.HasUpdateAvailable);
            Assert.IsNotNull(vm.AvailableUpdate);
            Assert.AreEqual("1.1.44", vm.AvailableUpdate.LatestVersion);

            vm.Dismiss();
            Assert.IsFalse(vm.ShowModal);
        });
    }

    private static void TestUpdateIntegrityVerification(Action<string, Action> run)
    {
        run("Update Integrity SHA256 Verification", () =>
        {
            var content = "OVERNODE_INSTALLER_PAYLOAD_TEST_DATA_" + new string('A', 60000);
            var bytes = Encoding.UTF8.GetBytes(content);
            using var sha256 = SHA256.Create();
            var hash = Convert.ToHexString(sha256.ComputeHash(bytes)).ToLowerInvariant();

            var mockHandler = new MockDownloadHttpMessageHandler(bytes);
            var client = new HttpClient(mockHandler);
            var service = new UpdateService(client);

            // Valid hash should succeed
            var downloadTask = service.DownloadUpdateAsync("https://example.com/test.msi", hash);
            downloadTask.Wait();
            var downloadedFile = downloadTask.Result;

            Assert.IsTrue(File.Exists(downloadedFile));
            File.Delete(downloadedFile);

            // Invalid hash should fail
            bool failed = false;
            try
            {
                var badTask = service.DownloadUpdateAsync("https://example.com/test.msi", "0000000000000000000000000000000000000000000000000000000000000000");
                badTask.Wait();
            }
            catch
            {
                failed = true;
            }
            Assert.IsTrue(failed);
        });
    }

    private sealed class FailingHttpMessageHandler : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            throw new HttpRequestException("Network error simulating offline environment");
        }
    }

    private sealed class MockHttpMessageHandler : HttpMessageHandler
    {
        private readonly UpdateCheckResponse _response;

        public MockHttpMessageHandler(UpdateCheckResponse response)
        {
            _response = response;
        }

        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            var json = JsonSerializer.Serialize(_response);
            var response = new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(json, Encoding.UTF8, "application/json")
            };
            return Task.FromResult(response);
        }
    }

    private sealed class MockDownloadHttpMessageHandler : HttpMessageHandler
    {
        private readonly byte[] _payload;

        public MockDownloadHttpMessageHandler(byte[] payload)
        {
            _payload = payload;
        }

        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            var response = new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new ByteArrayContent(_payload)
            };
            response.Content.Headers.ContentLength = _payload.Length;
            return Task.FromResult(response);
        }
    }
}
