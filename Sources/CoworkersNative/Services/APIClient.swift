// APIClient.swift — URLSession actor connecting to coworkers-agent Worker
import Foundation

public struct Plugin: Codable, Identifiable, Sendable { public let id, name, icon, description: String }
public struct APIMessage: Codable, Identifiable, Sendable { public let id, role, content, timestamp: String; public let tokens: Int? }
public struct APIConversation: Codable, Identifiable, Sendable { public let id, title, plugin: String; public let messages: [APIMessage]; public let createdAt, updatedAt: String }
public struct ChatResponse: Codable, Sendable { public let conversationId: String; public let message: APIMessage; public let title: String }
public struct MemoryEntry: Codable, Identifiable, Sendable { public let id, content: String; public let tags: [String]; public let createdAt: String }

public actor APIClient {
    public static let shared = APIClient()
    private let baseURL = URL(string: "https://agentknowledgeworkers.com")!
    private let session: URLSession
    private init() {
        let cfg = URLSessionConfiguration.default
        cfg.httpAdditionalHeaders = ["User-Agent": "CoworkersNative/1.0 (iOS 18; Swift 6)", "Accept": "application/json"]
        cfg.timeoutIntervalForRequest = 30
        cfg.httpShouldSetCookies = false
        session = URLSession(configuration: cfg)
    }
    private func build(_ method: String, path: String, body: (any Encodable)? = nil, cookie: String) throws -> URLRequest {
        var req = URLRequest(url: baseURL.appending(path: path))
        req.httpMethod = method
        req.setValue("s=\(cookie)", forHTTPHeaderField: "Cookie")
        if let body { req.setValue("application/json", forHTTPHeaderField: "Content-Type"); req.httpBody = try JSONEncoder().encode(body) }
        return req
    }
    private func get<T: Decodable>(_ type: T.Type, path: String, cookie: String) async throws -> T {
        let (data, _) = try await session.data(for: build("GET", path: path, cookie: cookie))
        return try JSONDecoder().decode(type, from: data)
    }
    public func plugins(cookie: String)       async throws -> [Plugin]           { try await get([Plugin].self,          path: "/api/plugins",            cookie: cookie) }
    public func conversations(cookie: String) async throws -> [APIConversation]  { try await get([APIConversation].self, path: "/api/conversations",       cookie: cookie) }
    public func conversation(_ id: String, cookie: String) async throws -> APIConversation { try await get(APIConversation.self, path: "/api/conversations/\(id)", cookie: cookie) }
    public func memory(cookie: String)        async throws -> [MemoryEntry]      { try await get([MemoryEntry].self,     path: "/api/memory",             cookie: cookie) }
    public func createConversation(plugin: String, cookie: String) async throws -> APIConversation {
        struct B: Encodable { let plugin: String }
        let (data, _) = try await session.data(for: build("POST", path: "/api/conversations", body: B(plugin: plugin), cookie: cookie))
        return try JSONDecoder().decode(APIConversation.self, from: data)
    }
    public func deleteConversation(_ id: String, cookie: String) async throws { _ = try await session.data(for: build("DELETE", path: "/api/conversations/\(id)", cookie: cookie)) }
    public func sendMessage(conversationId: String?, message: String, plugin: String, cookie: String) async throws -> ChatResponse {
        struct B: Encodable { let message, plugin: String; let conversationId: String? }
        let req = try build("POST", path: "/api/chat", body: B(message: message, plugin: plugin, conversationId: conversationId), cookie: cookie)
        let (data, resp) = try await session.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(ChatResponse.self, from: data)
    }
    public func addMemory(content: String, tags: [String], cookie: String) async throws -> MemoryEntry {
        struct B: Encodable { let content: String; let tags: [String] }
        let (data, _) = try await session.data(for: build("POST", path: "/api/memory", body: B(content: content, tags: tags), cookie: cookie))
        return try JSONDecoder().decode(MemoryEntry.self, from: data)
    }
    public func deleteMemory(_ id: String, cookie: String) async throws { _ = try await session.data(for: build("DELETE", path: "/api/memory/\(id)", cookie: cookie)) }
}