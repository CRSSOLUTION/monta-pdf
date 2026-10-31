//
//  SessionStore.swift
//  MontaPDF
//

import Foundation

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

final class UserDefaultsSessionStore: SessionStore {
    private let defaults: UserDefaults
    private let currentUserKey = "session.currentUserID"
    private let profilePrefix = "session.profile."

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSession() -> UserSession? {
        guard let userID = defaults.string(forKey: currentUserKey) else { return nil }
        return rememberedProfile(for: userID) ?? UserSession(userID: userID)
    }

    func save(_ session: UserSession) {
        if let data = try? JSONEncoder().encode(session) {
            defaults.set(data, forKey: profilePrefix + session.userID)
        }
        defaults.set(session.userID, forKey: currentUserKey)
    }

    func signOut() {
        defaults.removeObject(forKey: currentUserKey)
    }

    func deleteAll() {
        if let userID = defaults.string(forKey: currentUserKey) {
            defaults.removeObject(forKey: profilePrefix + userID)
        }
        defaults.removeObject(forKey: currentUserKey)
    }

    func rememberedProfile(for userID: String) -> UserSession? {
        guard let data = defaults.data(forKey: profilePrefix + userID) else { return nil }
        return try? JSONDecoder().decode(UserSession.self, from: data)
    }
}
