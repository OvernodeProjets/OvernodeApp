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
}
