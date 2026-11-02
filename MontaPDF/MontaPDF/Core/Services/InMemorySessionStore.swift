//
//  InMemorySessionStore.swift
//  MontaPDF
//

import Foundation

/// Session store kept in memory.
/// Used by unit tests, UI tests and Xcode previews; nothing is written to the Keychain.
final class InMemorySessionStore: SessionStore {
    private var currentUserID: String?
    private var profiles: [String: UserSession] = [:]

    func loadSession() -> UserSession? {
        currentUserID.flatMap { profiles[$0] }
    }

    func save(_ session: UserSession) {
        profiles[session.userID] = session
        currentUserID = session.userID
    }

    func signOut() {
        currentUserID = nil
    }

    func deleteAll() {
        if let currentUserID { profiles[currentUserID] = nil }
        currentUserID = nil
    }

    func rememberedProfile(for userID: String) -> UserSession? {
        profiles[userID]
    }
}
