import Foundation
import SwiftUI
import Combine

@MainActor
public final class CreateServerViewModel: ObservableObject {
    @Published public var serverName: String = ""
    @Published public var selectedCategory: String = "all"
    @Published public var selectedEgg: ServerEgg?
    @Published public var selectedLocation: ServerLocation?
    @Published public var selectedNode: ServerNode?
    
    @Published public var ramMB: Double = 1024
    @Published public var cpuPercent: Double = 100
    @Published public var diskMB: Double = 2048
    
    @Published public var options: DeployOptionsResponse?
    @Published public var isLoading: Bool = false
    @Published public var isDeploying: Bool = false
    @Published public var errorMessage: String?
    @Published public var isSuccess: Bool = false
    
    private let service = ServerDeployService.shared
    
    public init() {
        loadOptions()
    }
    
    public var filteredEggs: [ServerEgg] {
        guard let opts = options else { return [] }
        if selectedCategory == "all" {
            return opts.eggs
        }
        return opts.eggs.filter { $0.category.lowercased() == selectedCategory.lowercased() }
    }
    
    public var availableNodes: [ServerNode] {
        guard let opts = options else { return [] }
        guard let loc = selectedLocation else { return opts.nodes }
        
        let matching = opts.nodes.filter { node in
            LocationHelper.isMatch(node: node, location: loc)
        }
        return matching.isEmpty ? opts.nodes : matching
    }
    
    public var isNameValid: Bool {
        let trimmed = serverName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.count > 100 { return false }
        let regex = try? NSRegularExpression(pattern: "^[a-zA-Z0-9\\s\\-_]+$")
        let range = NSRange(location: 0, length: trimmed.utf16.count)
        return regex?.firstMatch(in: trimmed, options: [], range: range) != nil
    }
    
    public var canDeploy: Bool {
        guard isNameValid, selectedEgg != nil, effectiveNode != nil, !isDeploying else { return false }
        guard let rem = options?.resources.remaining else { return false }
        guard rem.servers > 0 else { return false }
        let minRam = selectedEgg?.minimum.ram ?? 128
        let minCpu = selectedEgg?.minimum.cpu ?? 10
        let minDisk = selectedEgg?.minimum.disk ?? 256
        return ramMB >= minRam && ramMB <= rem.ram &&
               cpuPercent >= minCpu && cpuPercent <= rem.cpu &&
               diskMB >= minDisk && diskMB <= rem.disk
    }
    
    public var effectiveNode: ServerNode? {
        if let sel = selectedNode, availableNodes.contains(where: { $0.id == sel.id }) {
            return sel
        }
        return availableNodes.first ?? options?.nodes.first
    }
    
    public func loadOptions() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let res = try await service.fetchDeployOptions()
                self.options = res
                if self.selectedLocation == nil {
                    self.selectedLocation = res.locations.first(where: { !$0.full }) ?? res.locations.first
                }
                self.selectedNode = self.availableNodes.first ?? res.nodes.first
                if self.selectedEgg == nil {
                    if let firstEgg = res.eggs.first {
                        self.selectEgg(firstEgg)
                    }
                }
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    public func selectEgg(_ egg: ServerEgg) {
        self.selectedEgg = egg
        let minRam = max(128.0, egg.minimum.ram)
        let minCpu = max(10.0, egg.minimum.cpu)
        let minDisk = max(256.0, egg.minimum.disk)
        
        let remRam = options?.resources.remaining.ram ?? 4096.0
        let remCpu = options?.resources.remaining.cpu ?? 200.0
        let remDisk = options?.resources.remaining.disk ?? 20480.0
        
        self.ramMB = max(minRam, min(remRam, max(self.ramMB, minRam)))
        self.cpuPercent = max(minCpu, min(remCpu, max(self.cpuPercent, minCpu)))
        self.diskMB = max(minDisk, min(remDisk, max(self.diskMB, minDisk)))
    }
    
    public func selectLocation(_ loc: ServerLocation) {
        self.selectedLocation = loc
        let nodesForLoc = availableNodes
        if !nodesForLoc.contains(where: { $0.id == selectedNode?.id }) {
            self.selectedNode = nodesForLoc.first
        }
    }
    
    public func deployServer() async -> ServerInstance? {
        guard canDeploy, let egg = selectedEgg, let node = effectiveNode else { return nil }
        isDeploying = true
        errorMessage = nil
        
        let payload = CreateServerPayload(
            name: serverName.trimmingCharacters(in: .whitespacesAndNewlines),
            egg: egg.id,
            nodeId: node.id,
            ram: Int(ramMB),
            disk: Int(diskMB),
            cpu: Int(cpuPercent)
        )
        
        do {
            let res = try await service.createServer(payload: payload)
            let instance = res.toServerInstance(
                fallbackName: payload.name,
                fallbackRam: payload.ram,
                fallbackDisk: payload.disk,
                fallbackCpu: payload.cpu,
                fallbackNode: node.name
            )
            self.isSuccess = true
            self.isDeploying = false
            return instance
        } catch {
            self.errorMessage = error.localizedDescription
            self.isDeploying = false
            return nil
        }
    }
}

