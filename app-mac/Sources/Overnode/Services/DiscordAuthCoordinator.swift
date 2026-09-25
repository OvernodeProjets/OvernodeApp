import Foundation
import AppKit
import AuthenticationServices
import Combine

@MainActor
public final class DiscordAuthCoordinator: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    public static let shared = DiscordAuthCoordinator()
    
    @Published public private(set) var isAuthenticating: Bool = false
    @Published public var authError: String?
    
    private var authSession: ASWebAuthenticationSession?
    
    private override init() {
        super.init()
    }
    
    public func startDiscordAuth(completion: @escaping (Result<Void, Error>) -> Void) {
        let authURL = APIClient.shared.baseURL.appendingPathComponent("/auth/discord/login")
        let callbackURLScheme = "overnode"
        
        isAuthenticating = true
        authError = nil
        
        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: callbackURLScheme
        ) { [weak self] callbackURL, error in
            Task { @MainActor in
                self?.isAuthenticating = false
                
                if let error = error {
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        self?.authError = "cancelled"
                    } else {
                        self?.authError = error.localizedDescription
                    }
                    completion(.failure(error))
                    return
                }
                
                completion(.success(()))
            }
        }
        
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        self.authSession = session
        
        session.start()
    }
    
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApplication.shared.windows.first { $0.isKeyWindow } ?? NSApplication.shared.windows.first ?? ASPresentationAnchor()
    }
}
