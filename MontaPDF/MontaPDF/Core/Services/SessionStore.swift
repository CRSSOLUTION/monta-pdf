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
