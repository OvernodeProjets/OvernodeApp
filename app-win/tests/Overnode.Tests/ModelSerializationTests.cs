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

    public void Test_User_Coins_PropertyChanged_Event()
    {
        var user = new User
        {
            Id = "100",
            Username = "PlayerOne",
            Coins = 100
        };

        string? changedProp = null;
        user.PropertyChanged += (s, e) =>
        {
            changedProp = e.PropertyName;
        };

        user.Coins = 850;

        Assert.AreEqual("Coins", changedProp);
        Assert.AreEqual(850, user.Coins);
    }

    public void Test_CoinsResponse_AllowReadingFromString()
    {
        var options = new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true,
            NumberHandling = System.Text.Json.Serialization.JsonNumberHandling.AllowReadingFromString
        };

        string jsonStringCoin = "{\"coins\": \"1250\"}";
        var res = JsonSerializer.Deserialize<CoinsResponse>(jsonStringCoin, options);
        Assert.IsNotNull(res);
        Assert.AreEqual(1250, res.Coins);

        string jsonIntCoin = "{\"coins\": 4200}";
        var resInt = JsonSerializer.Deserialize<CoinsResponse>(jsonIntCoin, options);
        Assert.IsNotNull(resInt);
        Assert.AreEqual(4200, resInt.Coins);
    }

    public void Test_ServerNode_Deserialization_Flexible_Types()
    {
        string json = @"[
            {""id"": ""1"", ""name"": ""Node GRA-01"", ""locationId"": ""1"", ""fqdn"": ""gra01.overnode.fr""},
            {""id"": 2, ""name"": ""Node MRS-01"", ""location_id"": 1, ""fqdn"": ""mrs01.overnode.fr""}
        ]";

        var nodes = JsonSerializer.Deserialize<System.Collections.Generic.List<ServerNode>>(json, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        });

        Assert.IsNotNull(nodes);
        Assert.AreEqual(2, nodes.Count);

        Assert.AreEqual(1, nodes[0].Id);
        Assert.AreEqual("Node GRA-01", nodes[0].Name);
        Assert.AreEqual("1", nodes[0].LocationId);
        Assert.AreEqual("gra01.overnode.fr", nodes[0].Fqdn);

        Assert.AreEqual(2, nodes[1].Id);
        Assert.AreEqual("Node MRS-01", nodes[1].Name);
        Assert.AreEqual("1", nodes[1].LocationId);
        Assert.AreEqual("mrs01.overnode.fr", nodes[1].Fqdn);
    }

    public void Test_ServerLocation_Deserialization_Flexible_Types()
    {
        string json = @"[
            {""id"": ""1"", ""name"": ""France"", ""flags"": [""FR""], ""full"": false},
            {""id"": 2, ""name"": ""Germany"", ""flags"": null, ""full"": true}
        ]";

        var locs = JsonSerializer.Deserialize<System.Collections.Generic.List<ServerLocation>>(json, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        });

        Assert.IsNotNull(locs);
        Assert.AreEqual(2, locs.Count);

        Assert.AreEqual("1", locs[0].Id);
        Assert.AreEqual("France", locs[0].Name);
        Assert.IsFalse(locs[0].Full);
        Assert.AreEqual(1, locs[0].Flags.Count);
        Assert.AreEqual("FR", locs[0].Flags[0]);

        Assert.AreEqual("2", locs[1].Id);
        Assert.AreEqual("Germany", locs[1].Name);
        Assert.IsTrue(locs[1].Full);
        Assert.IsNotNull(locs[1].Flags);
    }

    public void Test_LocationHelper_IsMatch_Real_Nodes()
    {
        var locFr = new ServerLocation("1", "France (Paris / Marseille)", "", new() { "FR" }, false);
        var locDe = new ServerLocation("2", "Germany (Frankfurt)", "", new() { "DE" }, false);

        var nodeFrById = new ServerNode(10, "Node GRA-01", "1");
        var nodeDeById = new ServerNode(20, "Node FRA-01", "2");
        var nodeFrByFlag = new ServerNode(30, "Node Custom", "fr");
        var nodeFrByHeuristic = new ServerNode(40, "Node MRS-Game", "");

        Assert.IsTrue(LocationHelper.IsMatch(nodeFrById, locFr));
        Assert.IsFalse(LocationHelper.IsMatch(nodeFrById, locDe));

        Assert.IsTrue(LocationHelper.IsMatch(nodeDeById, locDe));
        Assert.IsFalse(LocationHelper.IsMatch(nodeDeById, locFr));

        Assert.IsTrue(LocationHelper.IsMatch(nodeFrByFlag, locFr));
        Assert.IsTrue(LocationHelper.IsMatch(nodeFrByHeuristic, locFr));
    }

    public void Test_CreateServerResult_Deserialization_CaseInsensitive()
    {
        string json = @"{
            ""object"": ""server"",
            ""attributes"": {
                ""id"": 42,
                ""identifier"": ""abcd1234"",
                ""name"": ""Mon Super Serveur"",
                ""node"": 1,
                ""suspended"": false,
                ""limits"": {
                    ""memory"": 1024,
                    ""cpu"": 100,
                    ""disk"": 2048
                }
            }
        }";

        var options = new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true,
            NumberHandling = System.Text.Json.Serialization.JsonNumberHandling.AllowReadingFromString
        };

        var result = JsonSerializer.Deserialize<CreateServerResult>(json, options);
        Assert.IsNotNull(result);
        Assert.AreEqual("server", result.Object);
        Assert.IsNotNull(result.Attributes);
        Assert.AreEqual(42, result.Attributes.Id);
        Assert.AreEqual("abcd1234", result.Attributes.Identifier);
        Assert.AreEqual("Mon Super Serveur", result.Attributes.Name);
        Assert.AreEqual("Node 1", result.Attributes.Node);

        var instance = result.ToServerInstance("Mon Super Serveur", 1024, 2048, 100, "Node 1");
        Assert.IsNotNull(instance);
        Assert.AreEqual(42, instance.Id);
        Assert.AreEqual("abcd1234", instance.Identifier);
        Assert.AreEqual("Mon Super Serveur", instance.Name);
    }
}
