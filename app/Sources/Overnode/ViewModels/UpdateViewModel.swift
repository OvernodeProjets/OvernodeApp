import Foundation
import SwiftUI
import Combine

@MainActor
public final class UpdateViewModel: ObservableObject {
    public static let shared = UpdateViewModel()
    
    @Published public var state: UpdateState = .idle
    @Published public var showModal: Bool = false
    @Published public var downloadProgress: Double = 0.0
    @Published public var errorMessage: String? = nil
    
    private let service: UpdateService
    
    public init(service: UpdateService = .shared) {
        self.service = service
    }
    
    public var currentVersion: String {
        service.currentAppVersion
    }
    
    public var hasUpdateAvailable: Bool {
        if case .available = state { return true }
        if case .downloading = state { return true }
        if case .readyToRestart = state { return true }
        return false
    }
    
    public var isDownloading: Bool {
        if case .downloading = state { return true }
        return false
    }
    
    public var availableUpdate: UpdateCheckResponse? {
        if case let .available(resp) = state { return resp }
        return nil
    }
    
    public func checkForUpdates(silent: Bool = false) async {
        if !silent {
            state = .checking
        }
        
        do {
            let res = try await service.checkForUpdates()
            if res.updateAvailable {
                state = .available(res)
                showModal = true
            } else {
                state = .upToDate(currentVersion: service.currentAppVersion)
                if !silent {
                    showModal = false
                }
            }
        } catch {
            if !silent {
                state = .failed(error.localizedDescription)
                errorMessage = error.localizedDescription
            }
        }
    }
    
    public func startDownloadAndInstall() async {
        guard let update = availableUpdate else { return }
        
        state = .downloading(progress: 0.0)
        downloadProgress = 0.0
        
        do {
            let fileURL = try await service.downloadUpdate(from: update.downloadUrl) { [weak self] p in
                Task { @MainActor in
                    self?.downloadProgress = p
                    self?.state = .downloading(progress: p)
                }
            }
            
            state = .readyToRestart
            try service.launchInstallerAndRestart(archiveURL: fileURL)
        } catch {
            state = .failed(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }
    
    public func dismiss() {
        showModal = false
    }
}

