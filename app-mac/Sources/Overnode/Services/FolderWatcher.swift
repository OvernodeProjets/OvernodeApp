import Foundation
import CoreServices

/// Low-level watcher leveraging macOS kernel-level FSEvents for high-performance, battery-friendly directory monitoring.
public final class FolderWatcher: @unchecked Sendable {
    private var streamRef: FSEventStreamRef?
    private let path: String
    private let queue: DispatchQueue
    private let latency: TimeInterval
    private let onChange: @Sendable ([String]) -> Void
    private var isRunning = false
    
    public init(
        path: String,
        queue: DispatchQueue = DispatchQueue(label: "fr.overnode.folder-watcher", qos: .utility),
        latency: TimeInterval = 0.5,
        onChange: @escaping @Sendable ([String]) -> Void
    ) {
        self.path = path
        self.queue = queue
        self.latency = latency
        self.onChange = onChange
    }
    
    deinit {
        stop()
    }
    
    public func start() {
        guard !isRunning, FileManager.default.fileExists(atPath: path) else { return }
        
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        let callback: FSEventStreamCallback = { (streamRef, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds) in
            guard let info = clientCallBackInfo else { return }
            let watcher = Unmanaged<FolderWatcher>.fromOpaque(info).takeUnretainedValue()
            let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] ?? []
            watcher.handleEvents(paths: paths)
        }
        
        let flags = UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer)
        
        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            [path] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            latency,
            flags
        ) else {
            return
        }
        
        self.streamRef = stream
        FSEventStreamSetDispatchQueue(stream, queue)
        if FSEventStreamStart(stream) {
            isRunning = true
        }
    }
    
    public func stop() {
        guard isRunning, let stream = streamRef else { return }
        isRunning = false
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        streamRef = nil
    }
    
    private func handleEvents(paths: [String]) {
        onChange(paths)
    }
}
