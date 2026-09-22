import Foundation

public struct ResourceBucket: Codable, Equatable {
    public let ram: Double
    public let disk: Double
    public let cpu: Double
    public let servers: Int
    
    public init(ram: Double = 0, disk: Double = 0, cpu: Double = 0, servers: Int = 0) {
        self.ram = ram
        self.disk = disk
        self.cpu = cpu
        self.servers = servers
    }
}

public struct ResourcesResponse: Codable, Equatable {
    public let package: String?
    public let allowed: ResourceBucket
    public let remaining: ResourceBucket
    public let current: ResourceBucket
    public let limits: ResourceBucket
    
    public var ramUsedGB: Double {
        return current.ram / 1024.0
    }
    
    public var ramTotalGB: Double {
        return limits.ram / 1024.0
    }
    
    public var diskUsedGB: Double {
        return current.disk / 1024.0
    }
    
    public var diskTotalGB: Double {
        return limits.disk / 1024.0
    }
    
    public var ramPercentage: Double {
        guard limits.ram > 0 else { return 0 }
        return min((current.ram / limits.ram) * 100.0, 100.0)
    }
    
    public var cpuPercentage: Double {
        guard limits.cpu > 0 else { return 0 }
        return min((current.cpu / limits.cpu) * 100.0, 100.0)
    }
    
    public var diskPercentage: Double {
        guard limits.disk > 0 else { return 0 }
        return min((current.disk / limits.disk) * 100.0, 100.0)
    }
    
    public var serversPercentage: Double {
        guard limits.servers > 0 else { return 0 }
        return min((Double(current.servers) / Double(limits.servers)) * 100.0, 100.0)
    }
    
    public static var preview: ResourcesResponse {
        ResourcesResponse(
            package: "Titanium",
            allowed: ResourceBucket(ram: 8192, disk: 40960, cpu: 250, servers: 3),
            remaining: ResourceBucket(ram: 4096, disk: 20480, cpu: 100, servers: 1),
            current: ResourceBucket(ram: 4096, disk: 20480, cpu: 150, servers: 2),
            limits: ResourceBucket(ram: 8192, disk: 40960, cpu: 250, servers: 3)
        )
    }
    
    public static var empty: ResourcesResponse {
        ResourcesResponse(
            package: nil,
            allowed: ResourceBucket(ram: 0, disk: 0, cpu: 0, servers: 0),
            remaining: ResourceBucket(ram: 0, disk: 0, cpu: 0, servers: 0),
            current: ResourceBucket(ram: 0, disk: 0, cpu: 0, servers: 0),
            limits: ResourceBucket(ram: 0, disk: 0, cpu: 0, servers: 0)
        )
    }
}
