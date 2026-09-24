import XCTest
@testable import Overnode

final class DiscordRPCTests: XCTestCase {
    func testDiscordHandshakeEncoding() throws {
        let handshake = DiscordHandshake(v: 1, clientId: DiscordRPCService.defaultClientId)
        let data = try JSONEncoder().encode(handshake)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        
        XCTAssertTrue(json.contains(#""v":1"#))
        XCTAssertTrue(json.contains(#""client_id":"972921155205877860""#))
        
        let decoded = try JSONDecoder().decode(DiscordHandshake.self, from: data)
        XCTAssertEqual(decoded.v, 1)
        XCTAssertEqual(decoded.clientId, "972921155205877860")
    }
    
    func testDiscordActivityFrameEncoding() throws {
        let activity = DiscordActivity(
            details: "Overnode App",
            assets: DiscordAssets(
                largeImage: DiscordRPCService.defaultLargeImage,
                largeText: "Overnode"
            ),
            timestamps: DiscordTimestamps(start: 1700000000),
            buttons: [
                DiscordButton(label: "Site Web", url: DiscordRPCService.defaultWebsiteURL)
            ]
        )
        let frame = DiscordSetActivityFrame(pid: 1234, activity: activity, nonce: "test-nonce")
        let data = try JSONEncoder().encode(frame)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        
        XCTAssertTrue(json.contains(#""cmd":"SET_ACTIVITY""#))
        XCTAssertTrue(json.contains(#""details":"Overnode App""#))
        XCTAssertTrue(json.contains("972921155205877860"))
        XCTAssertTrue(json.contains(#""large_text":"Overnode""#))
        XCTAssertTrue(json.contains("overnode.fr"))
        XCTAssertTrue(json.contains(#""label":"Site Web""#))
        XCTAssertTrue(json.contains(#""start":1700000000"#))
        XCTAssertTrue(json.contains(#""pid":1234"#))
        XCTAssertTrue(json.contains(#""nonce":"test-nonce""#))
    }
    
    func testDiscordResponseFrameDecoding() throws {
        let jsonStr = """
        {
            "cmd": "DISPATCH",
            "evt": "READY",
            "nonce": null
        }
        """
        let json = jsonStr.data(using: .utf8)!
        
        let frame = try JSONDecoder().decode(DiscordResponseFrame.self, from: json)
        XCTAssertEqual(frame.cmd, "DISPATCH")
        XCTAssertEqual(frame.evt, "READY")
        XCTAssertNil(frame.nonce)
    }
    
    func testDiscordOpcodes() {
        XCTAssertEqual(DiscordOpcode.handshake.rawValue, 0)
        XCTAssertEqual(DiscordOpcode.frame.rawValue, 1)
        XCTAssertEqual(DiscordOpcode.close.rawValue, 2)
        XCTAssertEqual(DiscordOpcode.ping.rawValue, 3)
        XCTAssertEqual(DiscordOpcode.pong.rawValue, 4)
    }
    
    func testDiscordRPCServiceDefaults() {
        XCTAssertEqual(DiscordRPCService.defaultClientId, "972921155205877860")
        XCTAssertEqual(DiscordRPCService.defaultWebsiteURL, "https://overnode.fr")
        XCTAssertTrue(DiscordRPCService.defaultLargeImage.contains("972921155205877860"))
    }
    
    func testDiscordFrameHeaderLittleEndian() {
        var op = DiscordOpcode.frame.rawValue.littleEndian
        var len: UInt32 = UInt32(42).littleEndian
        var header = Data()
        withUnsafeBytes(of: &op) { header.append(contentsOf: $0) }
        withUnsafeBytes(of: &len) { header.append(contentsOf: $0) }
        
        XCTAssertEqual(header.count, 8)
        let decodedOp = header[0..<4].withUnsafeBytes { $0.load(as: UInt32.self) }.littleEndian
        let decodedLen = header[4..<8].withUnsafeBytes { $0.load(as: UInt32.self) }.littleEndian
        
        XCTAssertEqual(decodedOp, 1)
        XCTAssertEqual(decodedLen, 42)
    }
}
