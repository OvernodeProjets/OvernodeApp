import Foundation
import Combine

public struct BundleStatusResponse: Codable, Sendable {
    public let hasGodPack: Bool?
    public let hasAutoRenew: Bool?
    public let hasUpgradedPack: Bool?
    
    enum CodingKeys: String, CodingKey {
        case hasGodPack
        case hasAutoRenew
        case hasUpgradedPack
    }
}

public struct UpdaterGodPackCheckResponse: Codable, Sendable {
    public let discordId: String?
    public let hasGodPack: Bool
}

@MainActor
public final class GodPackService: ObservableObject {
    public static let shared = GodPackService()
    
    @Published public var hasGodPack: Bool = false
    @Published public var isChecking: Bool = false
    @Published public var lastCheckedAt: Date? = nil
    @Published public var lastError: String? = nil
    @Published public var activeDiscordId: String? = nil
    @Published public var savedDiscordId: String? = nil
    
    private let client = APIClient.shared
    private let updateService = UpdateService.shared
    public static let discordIdStorageKey = "overnode_godpack_discord_id"
    
    private init() {
        if let stored = UserDefaults.standard.string(forKey: Self.discordIdStorageKey)?.trimmingCharacters(in: .whitespacesAndNewlines), !stored.isEmpty {
            self.savedDiscordId = stored
        }
        if ProcessInfo.processInfo.environment["OVERNODE_FORCE_GOD_PACK"] == "1" {
            self.hasGodPack = true
        }
    }
    
    /// Sauvegarde manuellement l'identifiant Discord VIP dans les préférences locales
    public func saveDiscordId(_ id: String) {
        let clean = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        self.savedDiscordId = clean
        UserDefaults.standard.set(clean, forKey: Self.discordIdStorageKey)
    }
    
    /// Efface l'identifiant Discord VIP sauvegardé et réinitialise l'accès
    public func clearSavedDiscordId() {
        UserDefaults.standard.removeObject(forKey: Self.discordIdStorageKey)
        self.savedDiscordId = nil
        self.activeDiscordId = nil
        self.hasGodPack = false
    }
    
    /// Vérifie si l'utilisateur possède le Pack God via le backend Toledo ou la liste VIP du portail Updater.
    public func checkAccess(user: User? = nil, explicitDiscordId: String? = nil) async {
        if ProcessInfo.processInfo.environment["OVERNODE_FORCE_GOD_PACK"] == "1" {
            self.hasGodPack = true
            return
        }
        
        isChecking = true
        lastError = nil
        
        var verified = false
        var verifiedDiscordId: String? = nil
        
        // 1. Vérification via Toledo Cloud API (/api/bundles/status)
        do {
            let status: BundleStatusResponse = try await client.request(endpoint: "/api/bundles/status")
            if status.hasGodPack == true {
                verified = true
            }
        } catch {
            // Non-bloquant, on poursuit la vérification via le portail Updater
        }
        
        // 2. Collecte de tous les identifiants Discord candidats
        var candidateIds: [String] = []
        if let explicit = explicitDiscordId?.trimmingCharacters(in: .whitespacesAndNewlines), !explicit.isEmpty {
            candidateIds.append(explicit)
        }
        if let saved = savedDiscordId?.trimmingCharacters(in: .whitespacesAndNewlines), !saved.isEmpty, !candidateIds.contains(saved) {
            candidateIds.append(saved)
        }
        if let stored = UserDefaults.standard.string(forKey: Self.discordIdStorageKey)?.trimmingCharacters(in: .whitespacesAndNewlines), !stored.isEmpty, !candidateIds.contains(stored) {
            candidateIds.append(stored)
        }
        if let rpcId = DiscordRPCService.shared.currentDiscordUserId?.trimmingCharacters(in: .whitespacesAndNewlines), !rpcId.isEmpty, !candidateIds.contains(rpcId) {
            candidateIds.append(rpcId)
        }
        if let userDId = user?.discordId?.trimmingCharacters(in: .whitespacesAndNewlines), !userDId.isEmpty, !candidateIds.contains(userDId) {
            candidateIds.append(userDId)
        }
        if let uid = user?.id, uid.count >= 17, CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: uid)), !candidateIds.contains(uid) {
            candidateIds.append(uid)
        }
        
        // 3. Vérification via OvernodeApp-Updater (/api/v1/godpack/check/:discordId)
        for candidate in candidateIds {
            if let updaterVerified = await checkUpdaterDiscordId(candidate), updaterVerified {
                verified = true
                verifiedDiscordId = candidate
                break
            }
        }
        
        if verified {
            if let validId = verifiedDiscordId {
                self.activeDiscordId = validId
                self.savedDiscordId = validId
                UserDefaults.standard.set(validId, forKey: Self.discordIdStorageKey)
            }
            self.hasGodPack = true
        } else {
            self.hasGodPack = false
            if explicitDiscordId != nil && !candidateIds.isEmpty {
                self.activeDiscordId = nil
            }
        }
        
        self.lastCheckedAt = Date()
        self.isChecking = false
    }
    
    public func checkUpdaterDiscordId(_ discordId: String) async -> Bool? {
        guard let encoded = discordId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return nil
        }
        
        let urlsToTry: [URL] = [
            updateService.updaterBaseURL.appendingPathComponent("api/v1/godpack/check/\(encoded)"),
            URL(string: "http://127.0.0.1:3344/api/v1/godpack/check/\(encoded)"),
            URL(string: "http://localhost:3344/api/v1/godpack/check/\(encoded)"),
            URL(string: "http://127.0.0.1:3000/api/v1/godpack/check/\(encoded)"),
            URL(string: "http://localhost:3000/api/v1/godpack/check/\(encoded)")
        ].compactMap { $0 }
        
        for url in urlsToTry {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 4
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    continue
                }
                let decoded = try JSONDecoder().decode(UpdaterGodPackCheckResponse.self, from: data)
                if decoded.hasGodPack {
                    return true
                }
            } catch {
                continue
            }
        }
        return false
    }
    
    /// Méthode d'aide pour forcer manuellement le statut en local pour les tests
    public func setDebugGodPack(_ active: Bool) {
        self.hasGodPack = active
    }
}
