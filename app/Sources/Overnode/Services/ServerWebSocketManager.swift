import Foundation
import Combine

public struct LivePteroStats: Codable, Sendable {
    public let cpuAbsolute: Double?
    public let diskBytes: Double?
    public let memoryBytes: Double?
    public let memoryLimitBytes: Double?
    public let state: String?
    
    enum CodingKeys: String, CodingKey {
        case cpuAbsolute = "cpu_absolute"
        case diskBytes = "disk_bytes"
        case memoryBytes = "memory_bytes"
        case memoryLimitBytes = "memory_limit_bytes"
        case state
    }
}

public final class ServerWebSocketManager: @unchecked Sendable {
    public static let shared = ServerWebSocketManager()
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var isConnected: Bool = false
    private var currentServerId: String?
    
    public var onConsoleOutput: ((String) -> Void)?
    public var onStatusChange: ((String) -> Void)?
    public var onStatsUpdate: ((LivePteroStats) -> Void)?
    
    private init() {}
    
    public func connect(serverId: String) {
        disconnect()
        self.currentServerId = serverId
        
        Task {
            struct WsCredsResponse: Decodable {
                struct InnerData: Decodable {
                    let token: String
                    let socket: String
                }
                let data: InnerData
            }
            
            guard let creds: WsCredsResponse = try? await APIClient.shared.request(
                endpoint: "/api/server/\(serverId)/websocket"
            ) else {
                return
            }
            
            guard let url = URL(string: creds.data.socket) else { return }
            
            var request = URLRequest(url: url)
            request.setValue("https://panel.overnode.fr", forHTTPHeaderField: "Origin")
            
            let session = URLSession(configuration: .default)
            let task = session.webSocketTask(with: request)
            self.webSocketTask = task
            task.resume()
            self.isConnected = true
            
            // Send auth event
            sendJson(["event": "auth", "args": [creds.data.token]])
            
            // Start receive loop
            receiveMessage()
        }
    }
    
    public func sendCommand(_ command: String) {
        sendJson(["event": "send command", "args": [command]])
    }
    
    public func sendPowerSignal(_ signal: ServerPowerSignal) {
        sendJson(["event": "set state", "args": [signal.rawValue]])
    }
    
    public func disconnect() {
        isConnected = false
        currentServerId = nil
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
    }
    
    private func sendJson(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let str = String(data: data, encoding: .utf8) else { return }
        webSocketTask?.send(.string(str)) { _ in }
    }
    
    private func receiveMessage() {
        guard isConnected, let task = webSocketTask else { return }
        
        task.receive { [weak self] result in
            guard let self = self, self.isConnected else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleIncomingText(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleIncomingText(text)
                    }
                @unknown default:
                    break
                }
                self.receiveMessage()
                
            case .failure:
                self.isConnected = false
            }
        }
    }
    
    private func handleIncomingText(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let event = json["event"] as? String else { return }
        
        let args = json["args"] as? [Any] ?? []
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch event {
            case "auth success":
                // Immediately ask Wings for buffered logs & current stats
                self.sendJson(["event": "send logs", "args": [NSNull()]])
                self.sendJson(["event": "send stats", "args": [NSNull()]])
                
            case "console output":
                if let line = args.first as? String {
                    let cleaned = self.stripAnsiCodes(line)
                    self.onConsoleOutput?(cleaned)
                }
                
            case "status":
                if let status = args.first as? String {
                    self.onStatusChange?(status)
                }
                
            case "stats":
                if let statsJson = args.first as? String,
                   let statsData = statsJson.data(using: .utf8),
                   let stats = try? JSONDecoder().decode(LivePteroStats.self, from: statsData) {
                    self.onStatsUpdate?(stats)
                }
                
            default:
                break
            }
        }
    }
    
    private func stripAnsiCodes(_ str: String) -> String {
        let pattern = "\u{001B}\\[[0-9;]*[a-zA-Z]"
        return (try? NSRegularExpression(pattern: pattern).stringByReplacingMatches(in: str, range: NSRange(location: 0, length: str.utf16.count), withTemplate: "")) ?? str
    }
}
