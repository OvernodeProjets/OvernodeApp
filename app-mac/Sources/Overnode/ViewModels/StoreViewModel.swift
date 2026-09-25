import Foundation
import Combine

public enum StoreTab: String, CaseIterable, Identifiable {
    case resources = "resources"
    case bundles = "bundles"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .resources: return "cpu"
        case .bundles: return "cube.box"
        }
    }
}

@MainActor
public final class StoreViewModel: ObservableObject {
    @Published public var storeConfig: StoreConfigResponse?
    @Published public var userCoins: Int = 0
    @Published public var selectedTab: StoreTab = .resources
    @Published public var isLoading: Bool = false
    @Published public var isPurchasing: Bool = false
    @Published public var successMessage: String?
    @Published public var errorMessage: String?
    
    public let bundles: [StoreBundle] = [
        StoreBundle(
            id: "auto_renew",
            title: "Auto Renew",
            price: "2.99 €",
            period: "/ 30 days",
            description: "Vos serveurs sont automatiquement renouvelés sans interruption de service.",
            features: [
                "Renouvellement automatique de tous vos serveurs",
                "30 jours d'hébergement serein et continu",
                "Maintien en ligne garanti sans action manuelle"
            ],
            iconName: "arrow.triangle.2.circlepath",
            iconColor: "#4A90E2"
        ),
        StoreBundle(
            id: "upgraded_pack",
            title: "Upgraded Pack",
            price: "3.99 €",
            period: "/ 30 days",
            description: "Multipliez vos gains de coins et augmentez les quotas d'allocation de vos serveurs.",
            features: [
                "Multiplicateur 1.5x sur les gains AFK",
                "Quotas d'achat de RAM & Stockage augmentés de 1.5x",
                "Validité complète de 30 jours"
            ],
            iconName: "star.fill",
            iconColor: "#9B51E0"
        ),
        StoreBundle(
            id: "god_pack",
            title: "God Pack",
            price: "6.99 €",
            period: "/ 30 days",
            description: "La formule ultime combinant Auto Renew complet et tous les avantages Upgraded.",
            features: [
                "Renouvellement automatique total inclus",
                "Multiplicateur 1.5x AFK et limites étendues",
                "Support prioritaire Overnode"
            ],
            iconName: "crown.fill",
            iconColor: "#F2C94C"
        )
    ]
    
    private let service = StoreService.shared
    
    public init() {}
    
    public func loadConfig(initialCoins: Int? = nil) {
        if let initial = initialCoins {
            self.userCoins = initial
        }
        Task {
            isLoading = true
            errorMessage = nil
            do {
                let config = try await service.fetchStoreConfig()
                self.storeConfig = config
                if let balance = config.userBalance {
                    self.userCoins = balance
                }
            } catch {
                // If endpoint error, keep fallback prices
            }
            self.isLoading = false
        }
    }
    
    public func buyResource(
        resourceType: String,
        amount: Int,
        onSuccess: @escaping (Int) -> Void
    ) {
        guard amount > 0 else { return }
        isPurchasing = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                let res = try await service.buyResource(resourceType: resourceType, amount: amount)
                if res.success {
                    if let rem = res.remainingCoins {
                        self.userCoins = rem
                        onSuccess(rem)
                    }
                    self.successMessage = "Achat effectué avec succès !"
                    // Reload config to sync balances
                    self.loadConfig()
                } else {
                    self.errorMessage = "Impossible de finaliser l'achat."
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isPurchasing = false
        }
    }
    
    public func subscribeBundle(_ bundle: StoreBundle) {
        service.openSubscribeWeb()
    }
}

