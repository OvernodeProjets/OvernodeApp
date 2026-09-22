import Foundation

public struct ResourceRequirement: Codable, Hashable, Sendable {
    public let ram: Double
    public let disk: Double
    public let cpu: Double
    
    enum CodingKeys: String, CodingKey {
        case ram, disk, cpu
    }
    
    public init(ram: Double = 0, disk: Double = 0, cpu: Double = 0) {
        self.ram = ram
        self.disk = disk
        self.cpu = cpu
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let r = try? container.decode(Double.self, forKey: .ram) {
            self.ram = r
        } else if let r = try? container.decode(Int.self, forKey: .ram) {
            self.ram = Double(r)
        } else {
            self.ram = 0
        }
        
        if let d = try? container.decode(Double.self, forKey: .disk) {
            self.disk = d
        } else if let d = try? container.decode(Int.self, forKey: .disk) {
            self.disk = Double(d)
        } else {
            self.disk = 0
        }
        
        if let c = try? container.decode(Double.self, forKey: .cpu) {
            self.cpu = c
        } else if let c = try? container.decode(Int.self, forKey: .cpu) {
            self.cpu = Double(c)
        } else {
            self.cpu = 0
        }
    }
}

public struct ServerEgg: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let category: String
    public let minimum: ResourceRequirement
    public let maximum: ResourceRequirement?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, category, minimum, maximum
    }
    
    public init(
        id: String,
        name: String,
        description: String = "",
        category: String = "other",
        minimum: ResourceRequirement = ResourceRequirement(),
        maximum: ResourceRequirement? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.minimum = minimum
        self.maximum = maximum
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(String.self, forKey: .id)) ?? ""
        self.name = (try? container.decode(String.self, forKey: .name)) ?? self.id
        self.description = (try? container.decode(String.self, forKey: .description)) ?? ""
        self.category = (try? container.decode(String.self, forKey: .category)) ?? "other"
        self.minimum = (try? container.decode(ResourceRequirement.self, forKey: .minimum)) ?? ResourceRequirement()
        self.maximum = try? container.decodeIfPresent(ResourceRequirement.self, forKey: .maximum)
    }
    
    public var iconName: String {
        switch category.lowercased() {
        case "minecraft": return "cube.fill"
        case "discord", "bot", "bots": return "bubble.left.and.text.bubble.right.fill"
        case "web", "databases": return "globe.americas.fill"
        case "game", "games": return "gamecontroller.fill"
        default: return "shippingbox.fill"
        }
    }
}

public struct EggCategory: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let icon: String
    
    public init(id: String, name: String, icon: String = "shippingbox") {
        self.id = id
        self.name = name
        self.icon = icon
    }
}

public struct ServerLocation: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let flags: [String]
    public let full: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, flags, full
    }
    
    public init(
        id: String,
        name: String,
        description: String = "",
        flags: [String] = [],
        full: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.flags = flags
        self.full = full
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let strId = try? container.decode(String.self, forKey: .id) {
            self.id = strId
        } else if let intId = try? container.decode(Int.self, forKey: .id) {
            self.id = String(intId)
        } else {
            self.id = ""
        }
        self.name = (try? container.decode(String.self, forKey: .name)) ?? self.id
        self.description = (try? container.decode(String.self, forKey: .description)) ?? ""
        self.flags = (try? container.decode([String].self, forKey: .flags)) ?? []
        self.full = (try? container.decode(Bool.self, forKey: .full)) ?? false
    }
}

public struct ServerNode: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let locationId: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, locationId, pterodactylNodeId
    }
    
    public init(id: Int, name: String, locationId: String) {
        self.id = id
        self.name = name
        self.locationId = locationId
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = (try? container.decode(String.self, forKey: .name)) ?? "Node"
        
        var resolvedId = 0
        if let intId = try? container.decode(Int.self, forKey: .id) {
            resolvedId = intId
        } else if let strId = try? container.decode(String.self, forKey: .id), let parsed = Int(strId) {
            resolvedId = parsed
        } else if let pteroId = try? container.decode(Int.self, forKey: .pterodactylNodeId) {
            resolvedId = pteroId
        }
        self.id = resolvedId
        
        if let locStr = try? container.decode(String.self, forKey: .locationId) {
            self.locationId = locStr
        } else if let locInt = try? container.decode(Int.self, forKey: .locationId) {
            self.locationId = String(locInt)
        } else {
            self.locationId = ""
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(locationId, forKey: .locationId)
    }
}

public struct DeployResourcesInfo: Codable, Sendable {
    public let current: ResourceBucket
    public let allowed: ResourceBucket
    public let remaining: ResourceBucket
    
    public init(current: ResourceBucket, allowed: ResourceBucket, remaining: ResourceBucket) {
        self.current = current
        self.allowed = allowed
        self.remaining = remaining
    }
}

public struct DeployOptionsResponse: Codable, Sendable {
    public let categories: [EggCategory]
    public let eggs: [ServerEgg]
    public let locations: [ServerLocation]
    public let nodes: [ServerNode]
    public let resources: DeployResourcesInfo
    
    public init(
        categories: [EggCategory],
        eggs: [ServerEgg],
        locations: [ServerLocation],
        nodes: [ServerNode],
        resources: DeployResourcesInfo
    ) {
        self.categories = categories
        self.eggs = eggs
        self.locations = locations
        self.nodes = nodes
        self.resources = resources
    }
}

public struct CreateServerPayload: Encodable, Sendable {
    public let name: String
    public let egg: String
    public let nodeId: Int
    public let ram: Int
    public let disk: Int
    public let cpu: Int
    
    public init(name: String, egg: String, nodeId: Int, ram: Int, disk: Int, cpu: Int) {
        self.name = name
        self.egg = egg
        self.nodeId = nodeId
        self.ram = ram
        self.disk = disk
        self.cpu = cpu
    }
}

public struct CreateServerResult: Decodable, Sendable {
    public let object: String?
    public let error: String?
    public let message: String?
    public let attributes: PteroServerWrapper.Attributes?
    
    public init(
        object: String? = nil,
        error: String? = nil,
        message: String? = nil,
        attributes: PteroServerWrapper.Attributes? = nil
    ) {
        self.object = object
        self.error = error
        self.message = message
        self.attributes = attributes
    }
    
    public func toServerInstance(
        fallbackName: String,
        fallbackRam: Int,
        fallbackDisk: Int,
        fallbackCpu: Int,
        fallbackNode: String?
    ) -> ServerInstance {
        if let attr = attributes {
            return ServerInstance(
                id: attr.id,
                identifier: attr.identifier.isEmpty ? UUID().uuidString.prefix(8).lowercased() : attr.identifier,
                name: attr.name.isEmpty ? fallbackName : attr.name,
                node: attr.node ?? fallbackNode,
                suspended: attr.suspended ?? false,
                state: "installing",
                memoryUsedMB: 0,
                memoryLimitMB: attr.limits?.memory ?? Double(fallbackRam),
                cpuUsedPercent: 0,
                cpuLimitPercent: attr.limits?.cpu ?? Double(fallbackCpu),
                diskUsedMB: 0,
                diskLimitMB: attr.limits?.disk ?? Double(fallbackDisk)
            )
        }
        return ServerInstance(
            id: Int.random(in: 1000...9999),
            identifier: UUID().uuidString.prefix(8).lowercased(),
            name: fallbackName,
            node: fallbackNode,
            suspended: false,
            state: "installing",
            memoryUsedMB: 0,
            memoryLimitMB: Double(fallbackRam),
            cpuUsedPercent: 0,
            cpuLimitPercent: Double(fallbackCpu),
            diskUsedMB: 0,
            diskLimitMB: Double(fallbackDisk)
        )
    }
}

