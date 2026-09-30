using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace Overnode.App.Services;

public sealed class APIClient
{
    private static readonly Lazy<APIClient> _instance = new(() => new APIClient());
    public static APIClient Instance => _instance.Value;
    public static APIClient Shared => _instance.Value;

    public Uri BaseUri { get; } = new("https://console.overnode.fr");
    public CookieContainer CookieContainer { get; }
    private readonly HttpClient _httpClient;
    private readonly JsonSerializerOptions _jsonOptions;

    private APIClient()
    {
        CookieContainer = new CookieContainer();

        // Restore cookies from DPAPI
        var savedCookies = SessionPersistence.Instance.LoadCookies();
        foreach (var c in savedCookies)
        {
            try
            {
                CookieContainer.Add(BaseUri, c);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[APIClient] Cookie add error: {ex.Message}");
            }
        }

        var handler = new HttpClientHandler
        {
            CookieContainer = CookieContainer,
            UseCookies = true,
            AutomaticDecompression = DecompressionMethods.GZip | DecompressionMethods.Deflate
        };

        _httpClient = new HttpClient(handler)
        {
            BaseAddress = BaseUri,
            Timeout = TimeSpan.FromSeconds(20)
        };

        _httpClient.DefaultRequestHeaders.Accept.Clear();
        _httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        _httpClient.DefaultRequestHeaders.Add("User-Agent", "Overnode-Windows-Native/1.0");

        _jsonOptions = new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true,
            NumberHandling = JsonNumberHandling.AllowReadingFromString
        };
    }

    public async Task<T> GetAsync<T>(string endpoint)
    {
        using var response = await _httpClient.GetAsync(endpoint);
        PersistCurrentCookies();

        if (!response.IsSuccessStatusCode)
        {
            string errorBody = await response.Content.ReadAsStringAsync();
            throw new HttpRequestException($"HTTP {(int)response.StatusCode}: {errorBody}", null, response.StatusCode);
        }

        string content = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<T>(content, _jsonOptions);
        if (result == null)
        {
            throw new JsonException($"Failed to deserialize response from {endpoint} to {typeof(T).Name}");
        }

        return result;
    }

    public async Task<T> PostAsync<T>(string endpoint, object? body = null)
    {
        HttpContent? content = null;
        if (body != null)
        {
            string json = JsonSerializer.Serialize(body);
            content = new StringContent(json, Encoding.UTF8, "application/json");
        }

        using var response = await _httpClient.PostAsync(endpoint, content);
        PersistCurrentCookies();

        if (!response.IsSuccessStatusCode)
        {
            string errorBody = await response.Content.ReadAsStringAsync();
            throw new HttpRequestException($"HTTP {(int)response.StatusCode}: {errorBody}", null, response.StatusCode);
        }

        string respString = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<T>(respString, _jsonOptions);
        if (result == null)
        {
            throw new JsonException($"Failed to deserialize response from {endpoint} to {typeof(T).Name}");
        }

        return result;
    }

    public async Task<(T? data, string? rawError, int statusCode)> PostWithResponseFallbackAsync<T>(string endpoint, object? body = null)
    {
        HttpContent? content = null;
        if (body != null)
        {
            string json = JsonSerializer.Serialize(body);
            content = new StringContent(json, Encoding.UTF8, "application/json");
        }

        using var response = await _httpClient.PostAsync(endpoint, content);
        PersistCurrentCookies();

        string respString = await response.Content.ReadAsStringAsync();
        int statusCode = (int)response.StatusCode;

        try
        {
            var result = JsonSerializer.Deserialize<T>(respString, _jsonOptions);
            return (result, response.IsSuccessStatusCode ? null : respString, statusCode);
        }
        catch
        {
            return (default, respString, statusCode);
        }
    }

    public async Task PostEmptyAsync(string endpoint, object? body = null)
    {
        HttpContent? content = null;
        if (body != null)
        {
            string json = JsonSerializer.Serialize(body);
            content = new StringContent(json, Encoding.UTF8, "application/json");
        }

        using var response = await _httpClient.PostAsync(endpoint, content);
        PersistCurrentCookies();

        if (!response.IsSuccessStatusCode)
        {
            string errorBody = await response.Content.ReadAsStringAsync();
            throw new HttpRequestException($"HTTP {(int)response.StatusCode}: {errorBody}", null, response.StatusCode);
        }
    }

    public async Task DeleteEmptyAsync(string endpoint)
    {
        using var response = await _httpClient.DeleteAsync(endpoint);
        PersistCurrentCookies();

        if (!response.IsSuccessStatusCode)
        {
            string errorBody = await response.Content.ReadAsStringAsync();
            throw new HttpRequestException($"HTTP {(int)response.StatusCode}: {errorBody}", null, response.StatusCode);
        }
    }

    public async Task DeleteWithBodyAsync(string endpoint, object? body = null)
    {
        using var request = new HttpRequestMessage(HttpMethod.Delete, endpoint);
        if (body != null)
        {
            string json = JsonSerializer.Serialize(body);
            request.Content = new StringContent(json, Encoding.UTF8, "application/json");
        }

        using var response = await _httpClient.SendAsync(request);
        PersistCurrentCookies();

        if (!response.IsSuccessStatusCode)
        {
            string errorBody = await response.Content.ReadAsStringAsync();
            throw new HttpRequestException($"HTTP {(int)response.StatusCode}: {errorBody}", null, response.StatusCode);
        }
    }

    public async Task<string> GetStringAsync(string endpoint)
    {
        using var response = await _httpClient.GetAsync(endpoint);
        PersistCurrentCookies();

        if (!response.IsSuccessStatusCode)
        {
            string errorBody = await response.Content.ReadAsStringAsync();
            throw new HttpRequestException($"HTTP {(int)response.StatusCode}: {errorBody}", null, response.StatusCode);
        }

        return await response.Content.ReadAsStringAsync();
    }

    public async Task PostTextAsync(string endpoint, string text)
    {
        using var content = new StringContent(text, Encoding.UTF8, "text/plain");
        using var response = await _httpClient.PostAsync(endpoint, content);
        PersistCurrentCookies();

        if (!response.IsSuccessStatusCode)
        {
            string errorBody = await response.Content.ReadAsStringAsync();
            throw new HttpRequestException($"HTTP {(int)response.StatusCode}: {errorBody}", null, response.StatusCode);
        }
    }

    public async Task PutEmptyAsync(string endpoint, object? body = null)
    {
        HttpContent? content = null;
        if (body != null)
        {
            string json = JsonSerializer.Serialize(body);
            content = new StringContent(json, Encoding.UTF8, "application/json");
        }

        using var response = await _httpClient.PutAsync(endpoint, content);
        PersistCurrentCookies();

        if (!response.IsSuccessStatusCode)
        {
            string errorBody = await response.Content.ReadAsStringAsync();
            throw new HttpRequestException($"HTTP {(int)response.StatusCode}: {errorBody}", null, response.StatusCode);
        }
    }

    public async Task PatchEmptyAsync(string endpoint, object? body = null)
    {
        HttpContent? content = null;
        if (body != null)
        {
            string json = JsonSerializer.Serialize(body);
            content = new StringContent(json, Encoding.UTF8, "application/json");
        }

        using var response = await _httpClient.PatchAsync(endpoint, content);
        PersistCurrentCookies();

        if (!response.IsSuccessStatusCode)
        {
            string errorBody = await response.Content.ReadAsStringAsync();
            throw new HttpRequestException($"HTTP {(int)response.StatusCode}: {errorBody}", null, response.StatusCode);
        }
    }

    public void PersistCurrentCookies()
    {
        try
        {
            var cookies = CookieContainer.GetCookies(BaseUri);
            var list = new List<Cookie>();
            foreach (Cookie c in cookies)
            {
                list.Add(c);
            }
            SessionPersistence.Instance.SaveCookies(list);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"[APIClient] Persist error: {ex.Message}");
        }
    }

    public void ClearCookies()
    {
        SessionPersistence.Instance.Clear();
        var cookies = CookieContainer.GetCookies(BaseUri);
        foreach (Cookie c in cookies)
        {
            c.Expired = true;
        }
    }
}
