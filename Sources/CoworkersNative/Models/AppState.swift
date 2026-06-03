// AppState.swift — SwiftData cache + @Observable ViewModel
import Foundation
import SwiftData

@Model public final class CachedConversation {
    @Attribute(.unique) public var id: String
    public var title, plugin: String
    public var updatedAt: Date
    public var messages: [CachedMessage]
    public init(from api: APIConversation) {
        id = api.id; title = api.title; plugin = api.plugin
        updatedAt = ISO8601DateFormatter().date(from: api.updatedAt) ?? .now
        messages = api.messages.map { CachedMessage(from: $0) }
    }
}

@Model public final class CachedMessage {
    @Attribute(.unique) public var id: String
    public var role, content, timestamp: String
    public init(from api: APIMessage) { id = api.id; role = api.role; content = api.content; timestamp = api.timestamp }
}

public extension ModelContainer {
    static let coworkers: ModelContainer = {
        let schema = Schema([CachedConversation.self, CachedMessage.self])
        return try! ModelContainer(for: schema, configurations: ModelConfiguration("CoworkersCache", schema: schema))
    }()
}

public enum AppTab: String, CaseIterable { case conversations = "Chats"; case memory = "Memory" }

@MainActor @Observable
public final class AppViewModel {
    public static let shared = AppViewModel()
    public var tab: AppTab = .conversations
    public var selectedConvId: String?
    public var conversations: [APIConversation] = []
    public var plugins: [Plugin] = []
    public var memory: [MemoryEntry] = []
    public var currentPlugin = "default"
    public var loadingConvs = false
    public var loadingChat = false
    public var error: String?
    private init() {}
    private var cookie: String { AuthService.shared.sessionCookie ?? "" }
    public func loadAll() async {
        guard AuthService.shared.isAuthenticated else { return }
        async let a: () = loadPlugins()
        async let b: () = loadConversations()
        _ = await (a, b)
    }
    public func loadPlugins() async {
        do { plugins = try await APIClient.shared.plugins(cookie: cookie) } catch { self.error = error.localizedDescription }
    }
    public func loadConversations() async {
        loadingConvs = true; defer { loadingConvs = false }
        do { conversations = try await APIClient.shared.conversations(cookie: cookie) } catch { self.error = error.localizedDescription }
    }
    public func loadMemory() async {
        do { memory = try await APIClient.shared.memory(cookie: cookie) } catch { self.error = error.localizedDescription }
    }
    public func createConversation() async -> APIConversation? {
        do { let c = try await APIClient.shared.createConversation(plugin: currentPlugin, cookie: cookie); conversations.insert(c, at: 0); return c }
        catch { self.error = error.localizedDescription; return nil }
    }
    public func deleteConversation(_ id: String) async {
        do { try await APIClient.shared.deleteConversation(id, cookie: cookie); conversations.removeAll { $0.id == id } }
        catch { self.error = error.localizedDescription }
    }
    public func send(_ text: String, in convId: String?, plugin: String) async -> ChatResponse? {
        loadingChat = true; defer { loadingChat = false }
        do { let r = try await APIClient.shared.sendMessage(conversationId: convId, message: text, plugin: plugin, cookie: cookie); await loadConversations(); return r }
        catch { self.error = error.localizedDescription; return nil }
    }
    public func addMemory(content: String, tags: [String]) async {
        do { let e = try await APIClient.shared.addMemory(content: content, tags: tags, cookie: cookie); memory.append(e) }
        catch { self.error = error.localizedDescription }
    }
    public func deleteMemory(_ id: String) async {
        do { try await APIClient.shared.deleteMemory(id, cookie: cookie); memory.removeAll { $0.id == id } }
        catch { self.error = error.localizedDescription }
    }
}