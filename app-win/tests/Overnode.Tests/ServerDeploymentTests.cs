using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Overnode.App.Models;
using Overnode.App.ViewModels;

namespace Overnode.Tests;

public class ServerDeploymentTests
{
    public void Test_LocationHelper_FormattingAndMatching()
    {
        var frLoc = new ServerLocation("1", "France (Paris)", "EU West Datacenter", new() { "FR" }, false);
        var frInfo = LocationHelper.Format(frLoc);
        Assert.AreEqual("🇫🇷", frInfo.Flag);
        Assert.AreEqual("France", frInfo.CountryName);

        var deLoc = new ServerLocation("2", "Germany (Frankfurt)", "Central Europe Datacenter", new() { "DE" }, false);
        var deInfo = LocationHelper.Format(deLoc);
        Assert.AreEqual("🇩🇪", deInfo.Flag);

        var mrsNode = new ServerNode(10, "Node FR-MRS-01", "1");
        var mrsInfo = LocationHelper.Format(mrsNode);
        Assert.AreEqual("Marseille", mrsInfo.City);
        Assert.AreEqual("Game Anti-DDoS", mrsInfo.Tag);

        var rouNode = new ServerNode(11, "fr.rou.gold", "1");
        var rouInfo = LocationHelper.Format(rouNode);
        Assert.AreEqual("Roubaix", rouInfo.City);
        Assert.IsTrue(LocationHelper.IsMatch(rouNode, frLoc));

        var hashNode = new ServerNode(12, "Unknown Node", "1") { Fqdn = "pbnuwcmg1qiez0e9dopy19d2zmmn805e1.overnode.fr" };
        var hashInfo = LocationHelper.Format(hashNode);
        Assert.AreEqual("Datacenter", hashInfo.City);

        Assert.IsTrue(LocationHelper.IsMatch(mrsNode, frLoc));
        Assert.IsFalse(LocationHelper.IsMatch(mrsNode, deLoc));
    }

    public void Test_CreateServerViewModel_Validation()
    {
        var vm = new CreateServerViewModel();

        vm.ServerName = "";
        Assert.IsFalse(vm.IsNameValid);

        vm.ServerName = "   ";
        Assert.IsFalse(vm.IsNameValid);

        vm.ServerName = "Server <script>alert(1)</script>";
        Assert.IsFalse(vm.IsNameValid);

        vm.ServerName = "Valid-Server_Name 123";
        Assert.IsTrue(vm.IsNameValid);
    }

    public async Task Test_CreateServerViewModel_DeployFlowAsync()
    {
        Environment.SetEnvironmentVariable("OVERNODE_DEMO", "1");
        var vm = new CreateServerViewModel();
        await vm.LoadOptionsAsync();

        Assert.IsNotNull(vm.Options);
        Assert.IsTrue(vm.Options.Eggs.Count > 0);
        Assert.IsTrue(vm.Options.Locations.Count > 0);

        // Category filtering
        vm.SelectedCategory = "minecraft";
        var mcEggs = vm.FilteredEggs;
        Assert.IsTrue(mcEggs.Count > 0);
        foreach (var egg in mcEggs)
        {
            Assert.AreEqual("minecraft", egg.Category.ToLowerInvariant());
        }

        // Egg selection and clamping
        var firstEgg = mcEggs[0];
        vm.SelectEgg(firstEgg);
        Assert.AreEqual(firstEgg.Id, vm.SelectedEgg?.Id);
        Assert.IsTrue(vm.RamMB >= firstEgg.Minimum.Ram);
        Assert.IsTrue(vm.CpuPercent >= firstEgg.Minimum.Cpu);
        Assert.IsTrue(vm.DiskMB >= firstEgg.Minimum.Disk);

        // Name valid and CanDeploy
        vm.ServerName = "Survival 1-20";
        Assert.IsTrue(vm.IsNameValid);
        Assert.IsTrue(vm.CanDeploy);

        // Deploy
        var deployed = await vm.DeployServerAsync();
        Assert.IsNotNull(deployed);
        Assert.AreEqual("Survival 1-20", deployed.Name);
        Assert.AreEqual("installing", deployed.State);
        Assert.IsTrue(vm.IsSuccess);
    }

    public void Test_ServerEggAndNode_GodPack_Properties()
    {
        var regularEgg = new ServerEgg("paper", "Paper 1.20", "Paper Minecraft", "minecraft", new ResourceRequirement(1024, 2048, 100), goldOnly: false);
        Assert.IsFalse(regularEgg.GoldOnly);
        Assert.IsNull(regularEgg.NodeId);

        var godEgg = new ServerEgg("fivem", "FiveM Server", "FiveM GTA V", "game", new ResourceRequirement(2048, 8192, 200), goldOnly: true, nodeId: "4");
        Assert.IsTrue(godEgg.GoldOnly);
        Assert.AreEqual("4", godEgg.NodeId);

        var regularNode = new ServerNode(1, "Node FR-01", "1", goldOnly: false);
        Assert.IsFalse(regularNode.GoldOnly);

        var godNode = new ServerNode(4, "Node VIP-01", "1", goldOnly: true);
        Assert.IsTrue(godNode.GoldOnly);

        // JSON roundtrip test
        string jsonEgg = System.Text.Json.JsonSerializer.Serialize(godEgg);
        Assert.IsTrue(jsonEgg.Contains("\"goldOnly\":true"));
        Assert.IsTrue(jsonEgg.Contains("\"nodeId\":\"4\""));

        var deserializedEgg = System.Text.Json.JsonSerializer.Deserialize<ServerEgg>(jsonEgg);
        Assert.IsNotNull(deserializedEgg);
        Assert.IsTrue(deserializedEgg.GoldOnly);
        Assert.AreEqual("4", deserializedEgg.NodeId);

        string jsonNode = System.Text.Json.JsonSerializer.Serialize(godNode);
        Assert.IsTrue(jsonNode.Contains("\"goldOnly\":true"));

        var deserializedNode = System.Text.Json.JsonSerializer.Deserialize<ServerNode>(jsonNode);
        Assert.IsNotNull(deserializedNode);
        Assert.IsTrue(deserializedNode.GoldOnly);
    }

    public async Task Test_CreateServerViewModel_GodPack_RestrictionsAsync()
    {
        Environment.SetEnvironmentVariable("OVERNODE_DEMO", "1");
        Environment.SetEnvironmentVariable("OVERNODE_FORCE_GOD_PACK", null);

        var godService = Overnode.App.Services.GodPackService.Shared;
        godService.SetDebugGodPack(false);

        var vm = new CreateServerViewModel();
        await vm.LoadOptionsAsync();

        Assert.IsFalse(vm.HasGodPack);

        var normalEgg = vm.Options!.Eggs.Find(e => !e.GoldOnly);
        var godEgg = vm.Options.Eggs.Find(e => e.GoldOnly);
        var normalNode = vm.Options.Nodes.Find(n => !n.GoldOnly);
        var godNode = vm.Options.Nodes.Find(n => n.GoldOnly);

        Assert.IsNotNull(normalEgg);
        Assert.IsNotNull(godEgg);
        Assert.IsNotNull(normalNode);
        Assert.IsNotNull(godNode);

        vm.ServerName = "Test Server";

        // 1. Regular egg + regular node -> Valid
        vm.SelectEgg(normalEgg!);
        vm.SelectedNode = normalNode;
        Assert.IsFalse(vm.IsEggGodPackLocked);
        Assert.IsFalse(vm.IsNodeGodPackLocked);
        Assert.IsFalse(vm.IsGodPackLocked);
        Assert.IsTrue(vm.CanDeploy);

        // 2. GodPack egg + regular node -> Locked for unprivileged user
        vm.SelectEgg(godEgg!);
        vm.SelectedNode = normalNode;
        Assert.IsTrue(vm.IsEggGodPackLocked);
        Assert.IsFalse(vm.IsNodeGodPackLocked);
        Assert.IsTrue(vm.IsGodPackLocked);
        Assert.IsFalse(vm.CanDeploy);

        var deployBlocked = await vm.DeployServerAsync();
        Assert.IsNull(deployBlocked);

        // 3. Regular egg + GodPack node -> Locked for unprivileged user
        vm.SelectEgg(normalEgg!);
        vm.SelectedNode = godNode;
        Assert.IsFalse(vm.IsEggGodPackLocked);
        Assert.IsTrue(vm.IsNodeGodPackLocked);
        Assert.IsTrue(vm.IsGodPackLocked);
        Assert.IsFalse(vm.CanDeploy);

        // 4. GodPack egg + GodPack node -> Both locked
        vm.SelectEgg(godEgg!);
        vm.SelectedNode = godNode;
        Assert.IsTrue(vm.IsEggGodPackLocked);
        Assert.IsTrue(vm.IsNodeGodPackLocked);
        Assert.IsTrue(vm.IsGodPackLocked);
        Assert.IsFalse(vm.CanDeploy);

        // 5. User unlocks God Pack -> Can deploy GodPack egg & node
        godService.SetDebugGodPack(true);
        Assert.IsTrue(vm.HasGodPack);
        Assert.IsFalse(vm.IsEggGodPackLocked);
        Assert.IsFalse(vm.IsNodeGodPackLocked);
        Assert.IsFalse(vm.IsGodPackLocked);
        Assert.IsTrue(vm.CanDeploy);

        var deployed = await vm.DeployServerAsync();
        Assert.IsNotNull(deployed);

        // Cleanup
        godService.SetDebugGodPack(false);
    }

    public void Test_GodPack_Tooltips_And_Localization()
    {
        var loc = Overnode.App.Localization.LocalizationManager.Instance;

        // Test French
        loc.SetLanguage(Overnode.App.Localization.AppLanguage.Fr);
        Assert.IsFalse(string.IsNullOrEmpty(loc["create_server_godpack_badge"]));
        Assert.IsTrue(loc["create_server_godpack_locked_tooltip"].Contains("God Pack"));
        Assert.IsTrue(loc["create_server_godpack_locked_tooltip"].Contains("Boutique"));
        Assert.IsTrue(loc["create_server_node_godpack_tooltip"].Contains("God Pack"));
        Assert.IsTrue(loc["create_server_node_godpack_tooltip"].Contains("Boutique"));
        Assert.IsTrue(loc["create_server_godpack_required_title"].Contains("Pack God") || loc["create_server_godpack_required_title"].Contains("God Pack"));
        Assert.IsTrue(loc["create_server_btn_get_godpack"].Contains("Boutique"));

        // Test English
        loc.SetLanguage(Overnode.App.Localization.AppLanguage.En);
        Assert.IsFalse(string.IsNullOrEmpty(loc["create_server_godpack_badge"]));
        Assert.IsTrue(loc["create_server_godpack_locked_tooltip"].Contains("God Pack"));
        Assert.IsTrue(loc["create_server_godpack_locked_tooltip"].Contains("Store"));
        Assert.IsTrue(loc["create_server_node_godpack_tooltip"].Contains("God Pack"));
        Assert.IsTrue(loc["create_server_node_godpack_tooltip"].Contains("Store"));
        Assert.IsTrue(loc["create_server_godpack_required_title"].Contains("God Pack"));
        Assert.IsTrue(loc["create_server_btn_get_godpack"].Contains("Store"));

        // Reset to French
        loc.SetLanguage(Overnode.App.Localization.AppLanguage.Fr);
    }
}
