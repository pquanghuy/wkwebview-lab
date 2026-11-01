import Foundation

/// Only the bundled document may access the bridge. Subframes never inherit access.
public struct BridgePolicy {
    public let document: URL
    public init(document: URL) { self.document = document.standardizedFileURL }
    public func allows(_ url: URL?, mainFrame: Bool) -> Bool {
        guard mainFrame, let url, url.isFileURL else { return false }
        return url.standardizedFileURL.path == document.path && url.query == nil
    }
    public func reply(to body: Any) throws -> String {
        guard let object = body as? [String: Any], object["version"] as? Int == 1,
              object["action"] as? String == "echo", let text = object["text"] as? String,
              text.utf8.count <= 1024 else { throw BridgeError.invalidMessage }
        return text
    }
}
public enum BridgeError: Error { case invalidMessage }
