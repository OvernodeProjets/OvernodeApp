using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using Overnode.App.Models;
using Overnode.App.Services;

namespace Overnode.App.ViewModels;

public partial class CreateServerViewModel : ObservableObject
{
    private readonly ServerDeployService _service = ServerDeployService.Instance;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(IsNameValid))]
    [NotifyPropertyChangedFor(nameof(CanDeploy))]
    private string _serverName = string.Empty;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(FilteredEggs))]
    private string _selectedCategory = "all";

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(CanDeploy))]
    private ServerEgg? _selectedEgg;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(AvailableNodes))]
    [NotifyPropertyChangedFor(nameof(EffectiveNode))]
    private ServerLocation? _selectedLocation;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(EffectiveNode))]
    [NotifyPropertyChangedFor(nameof(CanDeploy))]
    private ServerNode? _selectedNode;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(CanDeploy))]
    private double _ramMB = 1024;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(CanDeploy))]
    private double _cpuPercent = 100;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(CanDeploy))]
    private double _diskMB = 2048;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(FilteredEggs))]
    [NotifyPropertyChangedFor(nameof(AvailableNodes))]
    [NotifyPropertyChangedFor(nameof(EffectiveNode))]
    [NotifyPropertyChangedFor(nameof(CanDeploy))]
    private DeployOptionsResponse? _options;

    [ObservableProperty]
    private bool _isLoading;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(CanDeploy))]
    private bool _isDeploying;

    [ObservableProperty]
    private string? _errorMessage;

    [ObservableProperty]
    private bool _isSuccess;

    public CreateServerViewModel() { }

    public List<ServerEgg> FilteredEggs
    {
        get
        {
            if (Options == null) return new();
            if (string.Equals(SelectedCategory, "all", StringComparison.OrdinalIgnoreCase))
                return Options.Eggs;

            return Options.Eggs.Where(e => string.Equals(e.Category, SelectedCategory, StringComparison.OrdinalIgnoreCase)).ToList();
        }
    }

    public List<ServerNode> AvailableNodes
    {
        get
        {
            if (Options == null) return new();
            if (SelectedLocation == null) return Options.Nodes;

            var matching = Options.Nodes.Where(n => LocationHelper.IsMatch(n, SelectedLocation)).ToList();
            return matching.Count > 0 ? matching : Options.Nodes;
        }
    }

    public ServerNode? EffectiveNode
    {
        get
        {
            if (SelectedNode != null && AvailableNodes.Any(n => n.Id == SelectedNode.Id))
                return SelectedNode;

            return AvailableNodes.FirstOrDefault() ?? Options?.Nodes.FirstOrDefault();
        }
    }

    public bool IsNameValid
    {
        get
        {
            var trimmed = ServerName.Trim();
            if (string.IsNullOrEmpty(trimmed) || trimmed.Length > 100) return false;
            return Regex.IsMatch(trimmed, @"^[a-zA-Z0-9\s\-_]+$");
        }
    }

    public bool CanDeploy
    {
        get
        {
            if (!IsNameValid || SelectedEgg == null || EffectiveNode == null || IsDeploying) return false;
            if (Options?.Resources.Remaining == null || Options.Resources.Remaining.Servers <= 0) return false;

            var rem = Options.Resources.Remaining;
            double minRam = SelectedEgg.Minimum?.Ram ?? 128;
            double minCpu = SelectedEgg.Minimum?.Cpu ?? 10;
            double minDisk = SelectedEgg.Minimum?.Disk ?? 256;

            return RamMB >= minRam && RamMB <= rem.Ram &&
                   CpuPercent >= minCpu && CpuPercent <= rem.Cpu &&
                   DiskMB >= minDisk && DiskMB <= rem.Disk;
        }
    }

    public async Task LoadOptionsAsync()
    {
        IsLoading = true;
        ErrorMessage = null;
        try
        {
            var res = await _service.FetchDeployOptionsAsync();
            Options = res;

            if (SelectedLocation == null)
            {
                SelectedLocation = res.Locations.FirstOrDefault(l => !l.Full) ?? res.Locations.FirstOrDefault();
            }

            SelectedNode = EffectiveNode;

            if (SelectedEgg == null && res.Eggs.Count > 0)
            {
                SelectEgg(res.Eggs[0]);
            }
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
        }
        finally
        {
            IsLoading = false;
        }
    }

    public void SelectEgg(ServerEgg egg)
    {
        SelectedEgg = egg;
        double minRam = Math.Max(128.0, egg.Minimum?.Ram ?? 128.0);
        double minCpu = Math.Max(10.0, egg.Minimum?.Cpu ?? 10.0);
        double minDisk = Math.Max(256.0, egg.Minimum?.Disk ?? 256.0);

        double remRam = Options?.Resources.Remaining?.Ram ?? 4096.0;
        double remCpu = Options?.Resources.Remaining?.Cpu ?? 200.0;
        double remDisk = Options?.Resources.Remaining?.Disk ?? 20480.0;

        RamMB = Math.Max(minRam, Math.Min(remRam, Math.Max(RamMB, minRam)));
        CpuPercent = Math.Max(minCpu, Math.Min(remCpu, Math.Max(CpuPercent, minCpu)));
        DiskMB = Math.Max(minDisk, Math.Min(remDisk, Math.Max(DiskMB, minDisk)));
    }

    public void SelectLocation(ServerLocation loc)
    {
        SelectedLocation = loc;
        var nodes = AvailableNodes;
        if (!nodes.Any(n => n.Id == SelectedNode?.Id))
        {
            SelectedNode = nodes.FirstOrDefault();
        }
    }

    public async Task<ServerInstance?> DeployServerAsync()
    {
        if (!CanDeploy || SelectedEgg == null || EffectiveNode == null) return null;

        IsDeploying = true;
        ErrorMessage = null;

        var payload = new CreateServerPayload
        {
            Name = ServerName.Trim(),
            Egg = SelectedEgg.Id,
            NodeId = EffectiveNode.Id,
            Ram = (int)RamMB,
            Disk = (int)DiskMB,
            Cpu = (int)CpuPercent
        };

        try
        {
            var res = await _service.CreateServerAsync(payload);
            var instance = res.ToServerInstance(
                payload.Name,
                payload.Ram,
                payload.Disk,
                payload.Cpu,
                EffectiveNode.Name
            );
            IsSuccess = true;
            return instance;
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
            return null;
        }
        finally
        {
            IsDeploying = false;
        }
    }
}
