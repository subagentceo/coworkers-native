// AuthService.swift
// L2 Auth — mirrors Claude iOS app auth architecture
// Email login → session cookie → Keychain (kSecAttrAccessibleAfterFirstUnlock)

import Foundation
import Security

public struct SessionCredential: Codable, Sendable {
    public let email: String
    public let ts: TimeInterval
    public var base64Token: String {
        let json = "{\"email\":\"\"\(email)\"\":\"ts\":\(ts)}"
        return Data(json.utf8).base64EncodedString()
    }
    public var cookieHeader: String { "s=\(base64Token)" }
    public var isExpired: Bool { Date().timeIntervalSince1970 - ts > 86400 }
}

public enum KeychainError: Error, Sendable {
    case notFound, unexpectedData, status(OSStatus)
}

public struct KeychainStore: Sendable {
    private static let service = "com.managedcoworkers.native"
    private static let account = "session"

    public static func save(_ cred: SessionCredential) throws {
        let data = try JSONEncoder().encode(cred)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.status(status) }
    }

    public static func load() throws -> SessionCredential {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]
        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { throw KeychainError.notFound }
        guard let data = item as? Data else { throw KeychainError.unexpectedData }
        return try JSONDecoder().decode(SessionCredential.self, from: data)
    }

    public static func delete() {
        let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: account]
        SecItemDelete(query as CFDictionary)
    }

    public static func syncToAppGroup(_ cred: SessionCredential) {
        let d = UserDefaults(suiteName: "group.com.managedcoworkers.native")
        d?.set(cred.email, forKey: "email")
        d?.set(cred.ts, forKey: "sessionTs")
        d?.set(cred.base64Token, forKey: "sessionCookie")
        d?.synchronize()
    }
}

@MainActor
public final class AuthService: ObservableObject {
    public static let shared = AuthService()
    @Published public var credential: SessionCredential?
    @Published public var isLoading = false
    @Published public var error: String?
    private let baseURL = URL(string: "https://agentknowledgeworkers.com")!
    private init() { credential = try? KeychainStore.load() }
    public var isAuthenticated: Bool { !(credential?.isExpired ?? true) }
    public var sessionCookie: String? { credential?.base64Token }

    public func login(email: String) async throws {
        isLoading = true; error = nil; defer { isLoading = false }
        var req = URLRequest(url: baseURL.appending(path: "/api/login"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["email": email])
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw AuthError.unauthorized((try? JSONDecoder().decode([String:String].self, from: data))?["error"] ?? "Login failed")
        }
        let cred = SessionCredential(email: email, ts: Date().timeIntervalSince1970)
        try KeychainStore.save(cred)
        KeychainStore.syncToAppGroup(cred)
        credential = cred
    }

    public func logout() { KeychainStore.delete(); credential = nil }
}

public enum AuthError: LocalizedError {
    case unauthorized(String)
    public var errorDescription: String? { switch self { case .unauthorized(let m): return m } }
}