import Foundation
import Combine
import WidgetKit
import AppKit

@MainActor
public final class DailyRewardSyncManager: ObservableObject {
    public static let shared = DailyRewardSyncManager()
    
    private var syncTimer: Timer?
    private var isSyncing = false
    
    private init() {}
    
    /// Démarre la synchronisation en arrière-plan (au lancement, au retour d'activité, et par intervalle)
    public func startBackgroundSync() {
        sync()
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.sync()
            }
        }
        
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sync()
            }
        }
    }
    
    /// Synchronise l'état réel des récompenses quotidiennes depuis l'API Overnode
    public func sync() {
        guard !isSyncing else { return }
        isSyncing = true
        
        Task {
            defer { self.isSyncing = false }
            
            do {
                let status = try await DailyRewardService.shared.fetchStatus()
                
                // Fetch servers and their renewal statuses in parallel
                var serverRenewals: [ServerWidgetRenewalInfo] = []
                var serverList = await AuthService.shared.fetchServersStatus()
                if serverList.isEmpty {
                    if let data = UserDefaults.standard.data(forKey: "overnode_cached_servers"),
                       let cached = try? JSONDecoder().decode([ServerInstance].self, from: data) {
                        serverList = cached
                    }
                }
                
                if !serverList.isEmpty {
                    await withTaskGroup(of: ServerWidgetRenewalInfo?.self) { group in
                        for server in serverList.prefix(6) {
                            group.addTask {
                                if let renewal = await ServerService.shared.fetchRenewalStatus(serverId: server.identifier) {
                                    let remSec = ServerWidgetRenewalInfo.parseRemainingSeconds(from: renewal.nextRenewalAt)
                                    let formattedTime = ServerWidgetRenewalInfo.formatRemaining(seconds: remSec)
                                    return ServerWidgetRenewalInfo(
                                        identifier: server.identifier,
                                        name: server.name,
                                        nextRenewalAt: renewal.nextRenewalAt,
                                        remainingSeconds: remSec,
                                        formattedRemainingTime: formattedTime,
                                        canRenew: renewal.canRenew ?? false,
                                        isExpired: renewal.isExpired ?? (remSec != nil && remSec! <= 0)
                                    )
                                }
                                return nil
                            }
                        }
                        
                        for await item in group {
                            if let item = item {
                                serverRenewals.append(item)
                            }
                        }
                    }
                    
                    // Sort servers by urgency: expiring soonest first
                    serverRenewals.sort { ($0.remainingSeconds ?? .infinity) < ($1.remainingSeconds ?? .infinity) }
                }
                
                let widgetData = DailyRewardWidgetData(
                    isAuthenticated: true,
                    canClaim: status.canClaim,
                    currentStreak: status.currentStreak,
                    longestStreak: status.longestStreak,
                    lastClaimTimestamp: status.lastClaimTimestamp,
                    nextRewardAmount: status.nextReward?.amount ?? 25,
                    coins: status.totalCoinsEarned,
                    totalClaimed: status.totalClaimed,
                    streakProtection: status.streakProtection,
                    lastUpdated: Date(),
                    servers: serverRenewals
                )
                DailyRewardStorage.shared.saveWidgetData(widgetData)
            } catch {
                // If 401 unauthorized or session ended, reset to unauthenticated
                if let nsErr = error as NSError?, nsErr.code == 401 {
                    onLogout()
                }
            }
        }
    }
    
    /// Enregistre la déconnexion et réinitialise les données du widget
    public func onLogout() {
        let unauthData = DailyRewardWidgetData(
            isAuthenticated: false,
            canClaim: false,
            currentStreak: 0,
            longestStreak: 0,
            lastClaimTimestamp: 0,
            nextRewardAmount: 25,
            coins: 0,
            totalClaimed: 0,
            streakProtection: 0,
            lastUpdated: Date(),
            servers: []
        )
        DailyRewardStorage.shared.saveWidgetData(unauthData)
    }
}
