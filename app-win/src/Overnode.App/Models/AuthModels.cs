using System.Text.Json.Serialization;

namespace Overnode.App.Models;

public class TwoFactorVerifyRequest
{
    [JsonPropertyName("code")]
    public string Code { get; set; } = string.Empty;
}

public class TwoFactorVerifyResponse
{
    [JsonPropertyName("success")]
    public bool Success { get; set; }

    [JsonPropertyName("error")]
    public string? Error { get; set; }
}

public class PasskeyOptionsResponse
{
    [JsonPropertyName("challenge")]
    public string Challenge { get; set; } = string.Empty;

    [JsonPropertyName("rpId")]
    public string? RpId { get; set; }

    [JsonPropertyName("timeout")]
    public int? Timeout { get; set; }

    [JsonPropertyName("userVerification")]
    public string? UserVerification { get; set; }
}

public class PasskeyVerifyPayload
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("rawId")]
    public string RawId { get; set; } = string.Empty;

    [JsonPropertyName("type")]
    public string Type { get; set; } = "public-key";

    [JsonPropertyName("response")]
    public PasskeyResponseInner Response { get; set; } = new();

    public class PasskeyResponseInner
    {
        [JsonPropertyName("clientDataJSON")]
        public string ClientDataJSON { get; set; } = string.Empty;

        [JsonPropertyName("authenticatorData")]
        public string AuthenticatorData { get; set; } = string.Empty;

        [JsonPropertyName("signature")]
        public string Signature { get; set; } = string.Empty;

        [JsonPropertyName("userHandle")]
        public string? UserHandle { get; set; }
    }
}

public class CoinsResponse
{
    [JsonPropertyName("coins")]
    public int Coins { get; set; }
}

public class StoreBalanceResponse
{
    [JsonPropertyName("userBalance")]
    public int? UserBalance { get; set; }
}
