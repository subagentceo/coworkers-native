// ShareViewController.swift — iOS Share Extension
// Share URLs/text/PDFs into Coworkers conversations from Safari, Files, Notes

import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    private let baseURL = URL(string: "https://agentknowledgeworkers.com")!
    override func viewDidLoad() { super.viewDidLoad(); Task { await run() } }
    private func run() async {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let items = item.attachments else { cancel(); return }
        var message: String?
        for p in items {
            if p.hasItemConformingToTypeIdentifier(UTType.url.identifier),
               let url = try? await p.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
                message = "Please analyze this page: \(url.absoluteString)"; break
            }
            if p.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
               let t = try? await p.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
                message = t; break
            }
            if p.hasItemConformingToTypeIdentifier(UTType.pdf.identifier),
               let url = try? await p.loadItem(forTypeIdentifier: UTType.pdf.identifier) as? URL {
                message = "Please summarize and analyze: \(url.lastPathComponent)"; break
            }
        }
        guard let msg = message else { cancel(); return }
        let defaults = UserDefaults(suiteName: "group.com.managedcoworkers.native")
        guard let cookie = defaults?.string(forKey: "sessionCookie") else {
            extensionContext?.completeRequest(returningItems: [], completionHandler: nil); return
        }
        do {
            var cReq = URLRequest(url: baseURL.appending(path: "/api/conversations"))
            cReq.httpMethod = "POST"; cReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
            cReq.setValue("s=\(cookie)", forHTTPHeaderField: "Cookie")
            cReq.httpBody = try JSONEncoder().encode(["plugin": "default"])
            let (cData, _) = try await URLSession.shared.data(for: cReq)
            let convId = (try? JSONDecoder().decode([String:String].self, from: cData))?["id"] ?? ""
            var mReq = URLRequest(url: baseURL.appending(path: "/api/chat"))
            mReq.httpMethod = "POST"; mReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
            mReq.setValue("s=\(cookie)", forHTTPHeaderField: "Cookie")
            struct Body: Encodable { let message, plugin, conversationId: String }
            mReq.httpBody = try JSONEncoder().encode(Body(message: msg, plugin: "default", conversationId: convId))
            _ = try await URLSession.shared.data(for: mReq)
        } catch {}
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    private func cancel() { extensionContext?.cancelRequest(withError: NSError(domain: "ShareExtension", code: 0)) }
}