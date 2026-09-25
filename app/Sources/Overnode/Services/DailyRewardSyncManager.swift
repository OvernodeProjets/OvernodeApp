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
                                    let canRenew = renewal.canRenew ?? false
                                    let isExpired = renewal.isExpired ?? (remSec != nil && remSec! <= 0)
                                    let rawAvail = renewal.availableIn ?? renewal.calculatedAvailableIn
                                    let availSec = ServerWidgetRenewalInfo.parseAvailableInSeconds(
                                        canRenew: canRenew,
                                        isExpired: isExpired,
                                        availableInString: rawAvail,
                                        nextRenewalAt: renewal.nextRenewalAt
                                    )
                                    let formattedAvail = ServerWidgetRenewalInfo.formatAvailableIn(
                                        seconds: availSec,
                                        canRenew: canRenew,
                                        isExpired: isExpired,
                                        rawString: rawAvail
                                    )
                                    
                                    return ServerWidgetRenewalInfo(
                                        identifier: server.identifier,
                                        name: server.name,
                                        nextRenewalAt: renewal.nextRenewalAt,
                                        remainingSeconds: remSec,
                                        formattedRemainingTime: formattedTime,
                                        canRenew: canRenew,
                                        isExpired: isExpired,
                                        availableIn: rawAvail,
                                        availableInSeconds: availSec,
                                        formattedAvailableIn: formattedAvail
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
                    
                    // Sort servers: expired first, then ready to renew (canRenew == true), then soonest to become renewable
                    serverRenewals.sort { s1, s2 in
                        if s1.isExpired != s2.isExpired {
                            return s1.isExpired
                        }
                        if s1.canRenew != s2.canRenew {
                            return s1.canRenew
                        }
                        if s1.canRenew {
                            return (s1.remainingSeconds ?? .infinity) < (s2.remainingSeconds ?? .infinity)
                        }
                        return (s1.availableInSeconds ?? .infinity) < (s2.availableInSeconds ?? .infinity)
                    }
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
