import XCTest
@testable import LabCore

final class BridgePolicyTests: XCTestCase {
    let policy = BridgePolicy(document: URL(fileURLWithPath: "/bundle/index.html"))
    func testOnlyTrustedMainDocument() {
        XCTAssertTrue(policy.allows(URL(fileURLWithPath: "/bundle/index.html"), mainFrame: true))
        XCTAssertFalse(policy.allows(URL(fileURLWithPath: "/bundle/index.html"), mainFrame: false))
        XCTAssertFalse(policy.allows(URL(string: "https://example.com/index.html"), mainFrame: true))
        XCTAssertFalse(policy.allows(URL(fileURLWithPath: "/bundle/other.html"), mainFrame: true))
        XCTAssertFalse(policy.allows(nil, mainFrame: true))
    }
    func testEchoPreservesUntrustedCharactersAsData() throws {
        let text = "'); alert('x'); // 🧪"
        XCTAssertEqual(try policy.reply(to: ["version": 1, "action": "echo", "text": text]), text)
    }
    func testUTF8LimitIsBytesNotCharacters() throws {
        XCTAssertEqual(try policy.reply(to: ["version": 1, "action": "echo", "text": String(repeating: "a", count: 1024)]).count, 1024)
        XCTAssertThrowsError(try policy.reply(to: ["version": 1, "action": "echo", "text": String(repeating: "🧪", count: 257)]))
    }
    func testMalformedAndOversizedMessagesFail() {
        for body: Any in ["echo", ["version": 2, "action": "echo", "text": "hello"], ["version": 1, "action": "delete", "text": "hello"], ["version": 1, "action": "echo", "text": String(repeating: "a", count: 1025)]] {
            XCTAssertThrowsError(try policy.reply(to: body))
        }
    }
}
