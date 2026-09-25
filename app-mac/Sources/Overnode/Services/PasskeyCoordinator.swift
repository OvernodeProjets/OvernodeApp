import Foundation
import AppKit
import AuthenticationServices
import Combine

@MainActor
public final class PasskeyCoordinator: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    public static let shared = PasskeyCoordinator()
    
    @Published public private(set) var isAuthenticating: Bool = false
    @Published public var passkeyError: String?
    
    private var currentChallenge: String?
    private var completionHandler: ((Result<AuthStateResponse, Error>) -> Void)?
    
    private override init() {
        super.init()
    }
    
    public func startPasskeyAuth(completion: @escaping (Result<AuthStateResponse, Error>) -> Void) {
        self.completionHandler = completion
        self.isAuthenticating = true
        self.passkeyError = nil
        
        Task {
            do {
                let options = try await AuthService.shared.getPasskeyOptions()
                self.currentChallenge = options.challenge
                
                let domain = APIClient.shared.baseURL.host ?? "console.overnode.fr"
                let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: domain)
                
                guard let challengeData = Data(base64URLEncoded: options.challenge) else {
                    throw NSError(domain: "Passkey", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid challenge data"])
                }
                
                let assertionRequest = publicKeyCredentialProvider.createCredentialAssertionRequest(challenge: challengeData)
                let authController = ASAuthorizationController(authorizationRequests: [assertionRequest])
                authController.delegate = self
                authController.presentationContextProvider = self
                authController.performRequests()
            } catch {
                self.isAuthenticating = false
                self.passkeyError = error.localizedDescription
                self.completionHandler?(.failure(error))
                self.completionHandler = nil
            }
        }
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task {
            defer {
                self.isAuthenticating = false
            }
            
            guard let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion else {
                let err = NSError(domain: "Passkey", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unexpected credential type"])
                self.completionHandler?(.failure(err))
                self.completionHandler = nil
                return
            }
            
            let rawIdBase64 = credential.credentialID.base64URLEncodedString()
            let clientData = credential.rawClientDataJSON.base64URLEncodedString()
            let authData = credential.rawAuthenticatorData.base64URLEncodedString()
            let signature = credential.signature.base64URLEncodedString()
            let userHandle = credential.userID?.base64URLEncodedString()
            
            let payload = PasskeyVerifyPayload(
                id: rawIdBase64,
                rawId: rawIdBase64,
                response: PasskeyVerifyPayload.PasskeyResponseInner(
                    clientDataJSON: clientData,
                    authenticatorData: authData,
                    signature: signature,
                    userHandle: userHandle
                )
            )
            
            do {
                let authState = try await AuthService.shared.verifyPasskey(payload: payload)
                self.completionHandler?(.success(authState))
            } catch {
                self.passkeyError = error.localizedDescription
                self.completionHandler?(.failure(error))
            }
            self.completionHandler = nil
        }
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.isAuthenticating = false
        self.passkeyError = error.localizedDescription
        self.completionHandler?(.failure(error))
        self.completionHandler = nil
    }
    
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return NSApplication.shared.windows.first { $0.isKeyWindow } ?? NSApplication.shared.windows.first ?? ASPresentationAnchor()
    }
}

// Data extension for Base64URL encoding/decoding
extension Data {
    public init?(base64URLEncoded base64URLString: String) {
        var base64 = base64URLString
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = 4 - (base64.count % 4)
        if padding < 4 {
            base64.append(String(repeating: "=", count: padding))
        }
        self.init(base64Encoded: base64)
    }
    
    public func base64URLEncodedString() -> String {
        return self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
