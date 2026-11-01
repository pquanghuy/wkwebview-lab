import SwiftUI
import WebKit
import Combine

@main
struct LabApp: App {
    var body: some Scene { WindowGroup { LabScreen() } }
}

struct LabScreen: View {
    @State private var presented = false
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("WKWebView Lab", systemImage: "network")
                        .font(.title.bold())
                    Text("A small, inspectable native–web integration.")
                        .foregroundStyle(.secondary)
                }
                Section("Explore") {
                    Label("Request / reply bridge", systemImage: "arrow.left.arrow.right")
                    Label("Restricted navigation", systemImage: "lock.shield")
                    Label("Loading and recovery", systemImage: "arrow.clockwise")
                }
                Section {
                    Button("Open lab") { presented = true }
                } footer: {
                    Text("Close and reopen the lab to exercise teardown. All web content is bundled; no account or network is required.")
                }
            }
            .navigationTitle("WebKit")
            .sheet(isPresented: $presented) { WebScreen() }
        }
    }
}

@MainActor
final class WebSession: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
    @Published var status = "Loading…"
    @Published var events: [String] = []
    let webView: WKWebView
    let policy: BridgePolicy
    private let bridge: ReplyBridge
    private var stopped = false

    override init() {
        let document = Bundle.main.url(forResource: "index", withExtension: "html")!
        policy = BridgePolicy(document: document)
        bridge = ReplyBridge(policy: policy)
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.userContentController.addScriptMessageHandler(bridge, contentWorld: .page, name: "lab")
        webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        // The controller retains the handler; the callback must not retain the session.
        bridge.onEvent = { [weak self] event in self?.record(event) }
        webView.navigationDelegate = self
        webView.uiDelegate = self
        reload()
    }
    func record(_ event: String) {
        events.insert(event, at: 0)
        events = Array(events.prefix(12))
    }
    func reload() {
        guard !stopped else { return }
        status = "Loading…"
        webView.loadFileURL(policy.document, allowingReadAccessTo: policy.document.deletingLastPathComponent())
    }
    func stop() {
        guard !stopped else { return }
        stopped = true
        webView.stopLoading()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "lab", contentWorld: .page)
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        bridge.onEvent = nil
    }
    deinit { print("WebSession released") }

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let allowed = policy.allows(action.request.url, mainFrame: action.targetFrame?.isMainFrame == true)
        if !allowed && action.targetFrame?.isMainFrame != false { record("Navigation blocked: \(action.request.url?.scheme ?? "unknown")") }
        let bundledFrame = action.targetFrame?.isMainFrame == false && action.request.url?.isFileURL == true && action.request.url?.standardizedFileURL.path == policy.document.deletingLastPathComponent().appendingPathComponent("frame.html").path
        decisionHandler((allowed || bundledFrame) ? .allow : .cancel)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        status = "Ready"
        record("Bundled page loaded")
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { failed(error) }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { failed(error) }
    private func failed(_ error: Error) {
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        status = "Load failed — use Reload"
        record("Navigation error \((error as NSError).code)")
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        status = "Web process stopped — use Reload"
        record("Web content process terminated")
    }
    func sendToPage() {
        guard status == "Ready" else { return }
        webView.callAsyncJavaScript("document.getElementById('native').textContent = message; return true;", arguments: ["message": "Hello from Swift — \(Date().formatted(date: .omitted, time: .standard))"], in: nil, in: .page) { [weak self] result in
            switch result {
            case .success: self?.record("Native → web delivered")
            case .failure: self?.record("Native → web failed")
            }
        }
    }
}

@MainActor
final class ReplyBridge: NSObject, WKScriptMessageHandlerWithReply {
    let policy: BridgePolicy
    var onEvent: ((String) -> Void)?
    init(policy: BridgePolicy) { self.policy = policy }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        guard policy.allows(message.frameInfo.request.url, mainFrame: message.frameInfo.isMainFrame) else {
            onEvent?("Bridge rejected: untrusted frame")
            replyHandler(nil, "Untrusted frame")
            return
        }
        do {
            let text = try policy.reply(to: message.body)
            onEvent?("Web → native echo accepted")
            replyHandler(["text": text, "source": "Swift"], nil)
        } catch {
            onEvent?("Bridge rejected: invalid message")
            replyHandler(nil, "Expected version 1, action echo, text ≤ 1024 UTF-8 bytes")
        }
    }
}

struct WebScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var session = WebSession()
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Label(session.status, systemImage: session.status == "Ready" ? "checkmark.circle" : "info.circle")
                        .font(.caption)
                    Spacer()
                    Button("Send to web") { session.sendToPage() }.disabled(session.status != "Ready")
                }.padding()
                WebSurface(session: session)
                VStack(alignment: .leading, spacing: 6) {
                    Text("EVENTS").font(.caption.bold()).foregroundStyle(.secondary)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(Array(session.events.enumerated()), id: \.offset) { _, event in
                                Text(event).font(.caption.monospaced()).frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }.frame(height: 90)
                }.padding().background(.thinMaterial)
            }
            .navigationTitle("Bridge lab").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .primaryAction) { Button("Reload") { session.reload() } }
            }
        }
    }
}
struct WebSurface: UIViewRepresentable {
    let session: WebSession
    func makeCoordinator() -> WebSession { session }
    func makeUIView(context: Context) -> WKWebView { session.webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    static func dismantleUIView(_ uiView: WKWebView, coordinator: WebSession) { coordinator.stop() }
}
