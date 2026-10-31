//
//  UserDefaultsSessionStoreTests.swift
//  MontaPDFTests
//

import Foundation
import Testing
@testable import MontaPDF

@MainActor
struct UserDefaultsSessionStoreTests {
    private let defaults: UserDefaults
    private let store: UserDefaultsSessionStore

    init() throws {
        let suite = "UserDefaultsSessionStoreTests.\(UUID().uuidString)"
        defaults = try #require(UserDefaults(suiteName: suite))
        store = UserDefaultsSessionStore(defaults: defaults)
    }

    @Test func startsSignedOut() {
        #expect(store.loadSession() == nil)
    }

    @Test func savedSessionIsLoadedBack() {
        let session = UserSession(userID: "abc", name: "Ana", email: "ana@example.com")

        store.save(session)

        #expect(store.loadSession() == session)
    }

    @Test func signOutRemembersTheProfile() {
        store.save(UserSession(userID: "abc", name: "Ana", email: "ana@example.com"))

        store.signOut()

        #expect(store.loadSession() == nil)
        #expect(store.rememberedProfile(for: "abc")?.name == "Ana")
    }

    @Test func deleteAllForgetsTheProfile() {
        store.save(UserSession(userID: "abc", name: "Ana", email: nil))

        store.deleteAll()

        #expect(store.loadSession() == nil)
        #expect(store.rememberedProfile(for: "abc") == nil)
    }
}
