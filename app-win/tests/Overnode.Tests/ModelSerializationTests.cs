using System.Text.Json;
using Overnode.App.Models;

namespace Overnode.Tests;

public class ModelSerializationTests
{
    public void Test_AuthStateResponse_Deserialization_With_2FA_Pending()
    {
        string json = @"
        {
            ""authenticated"": false,
            ""twoFactorPending"": true,
            ""twoFactorEnabled"": true,
            ""site_name"": ""Overnode""
        }";

        var res = JsonSerializer.Deserialize<AuthStateResponse>(json, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        });

        Assert.IsNotNull(res);
        Assert.IsFalse(res.Authenticated);
        Assert.IsTrue(res.TwoFactorPending == true);
        Assert.IsTrue(res.TwoFactorEnabled == true);
        Assert.AreEqual("Overnode", res.SiteName);
    }

    public void Test_AuthStateResponse_Deserialization_Authenticated()
    {
        string json = @"
        {
            ""authenticated"": true,
            ""twoFactorPending"": false,
            ""user"": {
                ""id"": ""12345"",
                ""username"": ""HugoOvernode"",
                ""email"": ""hugo@overnode.fr"",
                ""role"": ""Admin"",
                ""coins"": 1500
            }
        }";

        var res = JsonSerializer.Deserialize<AuthStateResponse>(json, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        });

        Assert.IsNotNull(res);
        Assert.IsTrue(res.Authenticated);
        Assert.IsNotNull(res.User);
        Assert.AreEqual("HugoOvernode", res.User.Username);
        Assert.AreEqual("hugo@overnode.fr", res.User.Email);
        Assert.AreEqual(1500, res.User.Coins);
    }
}
