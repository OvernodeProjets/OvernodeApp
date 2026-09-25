import Foundation
import Darwin
import Combine

public final class DiscordRPCService: ObservableObject, @unchecked Sendable {
    public static let shared = DiscordRPCService()
    public static let defaultClientId = "972921155205877860"
    public static let defaultLargeImage = "https://cdn.discordapp.com/app-icons/972921155205877860/256fde33d60f15e1d524a187b359e9b9.png"
    public static let defaultWebsiteURL = "https://overnode.fr"
    
    @Published public private(set) var isConnected: Bool = false
    public let isEnabled: Bool = true
    
    private var socketFd: Int32 = -1
    private let queue = DispatchQueue(label: "fr.overnode.discord-rpc", qos: .utility)
    private var reconnectTimer: DispatchSourceTimer?
    private let startTime: Int = Int(Date().timeIntervalSince1970)
    private var isRunning: Bool = false
    
    private init() {}
    
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        scheduleConnection(immediate: true)
    }
    
    public func stop() {
        isRunning = false
        reconnectTimer?.cancel()
        reconnectTimer = nil
        disconnect()
    }
    
    private func scheduleConnection(immediate: Bool) {
        reconnectTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + (immediate ? 0.0 : 12.0), repeating: 12.0)
        timer.setEventHandler { [weak self] in self?.attemptConnection() }
        reconnectTimer = timer
        timer.resume()
    }
    
    private func candidateSocketPaths() -> [String] {
        var dirs: [String] = []
        if let tmp = ProcessInfo.processInfo.environment["TMPDIR"], !tmp.isEmpty { dirs.append(tmp) }
        if let xdg = ProcessInfo.processInfo.environment["XDG_RUNTIME_DIR"], !xdg.isEmpty { dirs.append(xdg) }
        dirs.append("/tmp")
        var paths: [String] = []
        for dir in dirs {
            let trimmed = dir.hasSuffix("/") ? String(dir.dropLast()) : dir
            for i in 0...9 {
                let p = "\(trimmed)/discord-ipc-\(i)"
                if FileManager.default.fileExists(atPath: p) && !paths.contains(p) { paths.append(p) }
            }
        }
        return paths
    }
    
    private func attemptConnection() {
        guard isRunning && socketFd == -1 else { return }
        for path in candidateSocketPaths() {
            if let fd = openSocket(path: path) {
                self.socketFd = fd
                let handshake = DiscordHandshake(v: 1, clientId: Self.defaultClientId)
                guard sendFrame(fd: fd, opcode: .handshake, payload: handshake) else {
                    closeSocket(); continue
                }
                _ = readFrame(fd: fd)
                sendDefaultActivity(fd: fd)
                Task { @MainActor [weak self] in self?.isConnected = true }
                startMonitoring(fd: fd)
                return
            }
        }
    }
    
    private func openSocket(path: String) -> Int32? {
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { return nil }
        var opt: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &opt, socklen_t(MemoryLayout<Int32>.size))
        var tv = timeval(tv_sec: 2, tv_usec: 0)
        setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))
        setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))
        
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let maxLen = MemoryLayout.size(ofValue: addr.sun_path)
        guard path.utf8.count < maxLen else { close(fd); return nil }
        strncpy(&addr.sun_path.0, path, maxLen - 1)
        
        let res = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                Darwin.connect(fd, sa, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard res == 0 else { close(fd); return nil }
        return fd
    }
    
    private func sendDefaultActivity(fd: Int32) {
        let activity = DiscordActivity(
            details: "Overnode App",
            assets: DiscordAssets(largeImage: Self.defaultLargeImage, largeText: "Overnode"),
            timestamps: DiscordTimestamps(start: startTime),
            buttons: [DiscordButton(label: "Site Web", url: Self.defaultWebsiteURL)]
        )
        let frame = DiscordSetActivityFrame(pid: Int(getpid()), activity: activity)
        _ = sendFrame(fd: fd, opcode: .frame, payload: frame)
    }
    
    private func startMonitoring(fd: Int32) {
        queue.async { [weak self] in
            var tv = timeval(tv_sec: 5, tv_usec: 0)
            setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))
            while let self = self, self.socketFd == fd {
                if self.readFrame(fd: fd) == nil {
                    let err = errno
                    if err == EAGAIN || err == EWOULDBLOCK { continue }
                    break
                }
            }
            self?.closeSocket()
        }
    }
    
    private func closeSocket() {
        guard socketFd >= 0 else { return }
        close(socketFd)
        socketFd = -1
        Task { @MainActor [weak self] in self?.isConnected = false }
    }
    
    public func disconnect() {
        queue.async { [weak self] in
            guard let self = self, self.socketFd >= 0 else { return }
            let empty = DiscordSetActivityFrame(pid: Int(getpid()), activity: nil)
            _ = self.sendFrame(fd: self.socketFd, opcode: .frame, payload: empty)
            self.closeSocket()
        }
    }
    
    public func sendFrame<T: Encodable>(fd: Int32, opcode: DiscordOpcode, payload: T) -> Bool {
        guard let data = try? JSONEncoder().encode(payload) else { return false }
        var op = opcode.rawValue.littleEndian
        var len = UInt32(data.count).littleEndian
        var hdr = Data()
        withUnsafeBytes(of: &op) { hdr.append(contentsOf: $0) }
        withUnsafeBytes(of: &len) { hdr.append(contentsOf: $0) }
        guard hdr.withUnsafeBytes({ Darwin.send(fd, $0.baseAddress, $0.count, 0) }) == 8 else { return false }
        return data.withUnsafeBytes { Darwin.send(fd, $0.baseAddress, $0.count, 0) } == data.count
    }
    
    public func readFrame(fd: Int32) -> (opcode: UInt32, data: Data)? {
        var header = [UInt8](repeating: 0, count: 8)
        guard Darwin.recv(fd, &header, 8, 0) == 8 else { return nil }
        let op = header[0..<4].withUnsafeBytes { $0.load(as: UInt32.self) }.littleEndian
        let len = header[4..<8].withUnsafeBytes { $0.load(as: UInt32.self) }.littleEndian
        guard len > 0 && len <= 1_048_576 else { return (op, Data()) }
        var body = Data(count: Int(len))
        var readTotal = 0
        while readTotal < Int(len) {
            let n = body.withUnsafeMutableBytes { ptr -> Int in
                Darwin.recv(fd, ptr.baseAddress!.advanced(by: readTotal), Int(len) - readTotal, 0)
            }
            if n <= 0 { return nil }
            readTotal += n
        }
        return (op, body)
    }
}
