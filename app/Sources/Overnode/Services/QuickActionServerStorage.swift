import Foundation

public final class QuickActionServerStorage: @unchecked Sendable {
    public static let shared = QuickActionServerStorage()
    
    private let key = "overnode_quick_action_server_id"
    public static let didChangeNotification = Notification.Name("overnode_quick_action_server_changed")
    
    private init() {}
    
    public func getSelectedServerIdentifier() -> String? {
        let val = UserDefaults.standard.string(forKey: key)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (val?.isEmpty ?? true) ? nil : val
    }
    
    public func setSelectedServerIdentifier(_ identifier: String?) {
        let trimmed = identifier?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let id = trimmed, !id.isEmpty {
            UserDefaults.standard.set(id, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
    }
}
