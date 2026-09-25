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
                    lastUpdated: Date()
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
            lastUpdated: Date()
        )
        DailyRewardStorage.shared.saveWidgetData(unauthData)
    }
}
