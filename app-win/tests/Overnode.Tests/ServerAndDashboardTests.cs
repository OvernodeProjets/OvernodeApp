using System;
using System.Collections.Generic;
using System.Text.Json;
using Overnode.App.Models;

namespace Overnode.Tests;

public class ServerAndDashboardTests
{
    public void Test_ServerInstance_Permissions_Owner()
    {
        var server = new ServerInstance
        {
            Id = 10,
            Identifier = "test10",
            Name = "Owner Server",
            IsOwner = true,
            Permissions = new List<string>()
        };

        Assert.IsTrue(server.CanDelete, "Owner must be allowed to delete server");
        Assert.IsTrue(server.CanRenew, "Owner must be allowed to renew server");
        Assert.IsTrue(server.CanStart, "Owner must be allowed to start server");
        Assert.IsTrue(server.CanStop, "Owner must be allowed to stop server");
        Assert.IsTrue(server.CanRestart, "Owner must be allowed to restart server");
        Assert.IsFalse(server.IsShared, "Owner server is not shared");
    }

    public void Test_ServerInstance_Permissions_Subuser()
    {
        var subuserServer = new ServerInstance
        {
            Id = 20,
            Identifier = "test20",
            Name = "Shared Server",
            IsOwner = false,
            Permissions = new List<string> { "control.start", "control.restart" }
        };

        Assert.IsFalse(subuserServer.CanDelete, "Subuser must not be allowed to delete server");
        Assert.IsFalse(subuserServer.CanRenew, "Subuser must not be allowed to renew server");
        Assert.IsTrue(subuserServer.CanStart, "Subuser with control.start should be allowed to start");
        Assert.IsFalse(subuserServer.CanStop, "Subuser without control.stop should not be allowed to stop");
        Assert.IsTrue(subuserServer.CanRestart, "Subuser with control.restart should be allowed to restart");
        Assert.IsTrue(subuserServer.IsShared, "Server with isOwner=false must have isShared=true");
    }

    public void Test_PteroServerWrapper_Deserialization()
    {
        string json = """
        {
            "attributes": {
                "id": 42,
                "identifier": "abc12345",
                "name": "Production Node",
                "node": "Node FR-01",
                "suspended": false,
                "limits": {
                    "memory": 4096,
                    "cpu": 200,
                    "disk": 10240
                }
            }
        }
        """;

        var wrapper = JsonSerializer.Deserialize<PteroServerWrapper>(json);
        Assert.IsNotNull(wrapper, "Wrapper should deserialize");
        Assert.AreEqual(42, wrapper.Attributes.Id);
        Assert.AreEqual("abc12345", wrapper.Attributes.Identifier);
        Assert.AreEqual("Production Node", wrapper.Attributes.Name);
        Assert.AreEqual("Node FR-01", wrapper.Attributes.Node);

        var instance = wrapper.ToServerInstance();
        Assert.AreEqual(42, instance.Id);
        Assert.AreEqual("abc12345", instance.Identifier);
        Assert.AreEqual(4096.0, instance.MemoryLimitMB);
        Assert.AreEqual(200.0, instance.CpuLimitPercent);
        Assert.AreEqual(10240.0, instance.DiskLimitMB);
        Assert.AreEqual("offline", instance.State);
    }

    public void Test_ResourcesResponse_Calculations()
    {
        var res = new ResourcesResponse
        {
            Package = "Titanium",
            Allowed = new ResourceBucket(8192, 40960, 400, 4),
            Remaining = new ResourceBucket(4096, 20480, 200, 2),
            Current = new ResourceBucket(4096, 20480, 200, 2),
            Limits = new ResourceBucket(8192, 40960, 400, 4)
        };

        Assert.AreEqual(4.0, res.RamUsedGB);
        Assert.AreEqual(8.0, res.RamTotalGB);
        Assert.AreEqual(50.0, res.RamPercentage);

        Assert.AreEqual(20.0, res.DiskUsedGB);
        Assert.AreEqual(40.0, res.DiskTotalGB);
        Assert.AreEqual(50.0, res.DiskPercentage);

        Assert.AreEqual(50.0, res.CpuPercentage);
        Assert.AreEqual(50.0, res.ServersPercentage);
    }
}
