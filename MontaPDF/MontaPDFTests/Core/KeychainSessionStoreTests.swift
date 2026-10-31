//
//  KeychainSessionStoreTests.swift
//  MontaPDFTests
//

import Foundation
import Security
import Testing
@testable import MontaPDF

/// The Keychain needs a signed app. CI builds without signing, where the
/// Keychain is unavailable, so these tests only run when it works.
private let isKeychainAvailable: Bool = {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "com.crlsribeiro.MontaPDF.probe",
        kSecAttrAccount as String: "probe",
        kSecValueData as String: Data("probe".utf8),
    ]
    SecItemDelete(query as CFDictionary)
    let status = SecItemAdd(query as CFDictionary, nil)
    SecItemDelete(query as CFDictionary)
    return status == errSecSuccess
}()

@MainActor
@Suite(.enabled(if: isKeychainAvailable, "Keychain unavailable (unsigned build)"))
struct KeychainSessionStoreTests {
    private let store = KeychainSessionStore(service: "com.crlsribeiro.MontaPDF.tests.\(UUID().uuidString)")

    @Test func startsSignedOut() {
        #expect(store.loadSession() == nil)
    }

    @Test func savedSessionIsLoadedBack() {
        let session = UserSession(userID: "abc", name: "Ana", email: "ana@example.com")

        store.save(session)

        #expect(store.loadSession() == session)
        store.deleteAll()
    }

    @Test func savingAgainUpdatesTheProfile() {
        store.save(UserSession(userID: "abc", name: "Ana", email: nil))

        store.save(UserSession(userID: "abc", name: "Ana Souza", email: "ana@example.com"))

        #expect(store.loadSession()?.name == "Ana Souza")
        store.deleteAll()
    }

    @Test func signOutRemembersTheProfile() {
        store.save(UserSession(userID: "abc", name: "Ana", email: "ana@example.com"))

        store.signOut()

        #expect(store.loadSession() == nil)
        #expect(store.rememberedProfile(for: "abc")?.name == "Ana")
        store.save(UserSession(userID: "abc"))
        store.deleteAll()
    }

    @Test func deleteAllForgetsTheProfile() {
        store.save(UserSession(userID: "abc", name: "Ana", email: nil))

        store.deleteAll()

        #expect(store.loadSession() == nil)
        #expect(store.rememberedProfile(for: "abc") == nil)
    }
}
