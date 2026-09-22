import Foundation

public struct PasskeyOptionsResponse: Codable {
    public let challenge: String
    public let rpId: String?
    public let timeout: Int?
    public let userVerification: String?
    
    enum CodingKeys: String, CodingKey {
        case challenge
        case rpId
        case timeout
        case userVerification
    }
}

public struct PasskeyVerifyPayload: Codable {
    public let id: String
    public let rawId: String
    public let response: PasskeyResponseInner
    public let type: String
    
    public struct PasskeyResponseInner: Codable {
        public let clientDataJSON: String
        public let authenticatorData: String
        public let signature: String
        public let userHandle: String?
    }
    
    public init(id: String, rawId: String, response: PasskeyResponseInner, type: String = "public-key") {
        self.id = id
        self.rawId = rawId
        self.response = response
        self.type = type
    }
}
