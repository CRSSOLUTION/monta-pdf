//
//  SessionStore.swift
//  MontaPDF
//

import Foundation
import Security

/// Keeps the session between launches.
protocol SessionStore {
    func loadSession() -> UserSession?
    func save(_ session: UserSession)
    /// Signs out but remembers name and email, because Apple won't send them again.
    func signOut()
    /// Forgets everything about the account (used when the account is deleted).
    func deleteAll()
    func rememberedProfile(for userID: String) -> UserSession?
}

/// Stores the Apple user ID, name and email in the Keychain (not in UserDefaults),
/// readable only on this device after the first unlock.
final class KeychainSessionStore: SessionStore {
    private let service: String
    private let currentUserAccount = "currentUserID"
    private let profilePrefix = "profile."

    init(service: String = "com.crlsribeiro.MontaPDF.session") {
        self.service = service
    }

    func loadSession() -> UserSession? {
        guard
            let data = read(account: currentUserAccount),
            let userID = String(data: data, encoding: .utf8)
        else { return nil }
        return rememberedProfile(for: userID) ?? UserSession(userID: userID)
    }

    func save(_ session: UserSession) {
        if let data = try? JSONEncoder().encode(session) {
            write(data, account: profilePrefix + session.userID)
        }
        write(Data(session.userID.utf8), account: currentUserAccount)
    }

    func signOut() {
        delete(account: currentUserAccount)
    }

    func deleteAll() {
        if let session = loadSession() {
            delete(account: profilePrefix + session.userID)
        }
        delete(account: currentUserAccount)
    }

    func rememberedProfile(for userID: String) -> UserSession? {
        guard let data = read(account: profilePrefix + userID) else { return nil }
        return try? JSONDecoder().decode(UserSession.self, from: data)
    }

    // MARK: - Keychain

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    private func read(account: String) -> Data? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    private func write(_ data: Data, account: String) {
        let query = baseQuery(account: account)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            SecItemAdd(query.merging(attributes) { _, new in new } as CFDictionary, nil)
        }
    }

    private func delete(account: String) {
        SecItemDelete(baseQuery(account: account) as CFDictionary)
    }
}
