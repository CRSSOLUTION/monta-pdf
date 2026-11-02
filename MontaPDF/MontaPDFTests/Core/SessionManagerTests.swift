//
//  SessionManagerTests.swift
//  MontaPDFTests
//

import Foundation
import Testing
@testable import MontaPDF

@MainActor
struct SessionManagerTests {
    private let store = InMemorySessionStore()

    @Test func withoutSessionIsSignedOut() {
        #expect(makeSessionManager(store: store).isSignedIn == false)
    }

    @Test func signInSavesTheSession() {
        let manager = makeSessionManager(store: store)

        manager.signIn(with: appleCredential(name: "Ana Souza", email: "ana@example.com"))

        #expect(manager.isSignedIn)
        #expect(manager.session == UserSession(userID: "abc", name: "Ana Souza", email: "ana@example.com"))
        #expect(store.loadSession()?.userID == "abc")
    }

    @Test func secondSignInKeepsNameAndEmailAppleDoesNotSendAgain() {
        let manager = makeSessionManager(store: store)
        manager.signIn(with: appleCredential(name: "Ana", email: "ana@example.com"))
        manager.signOut()

        manager.signIn(with: appleCredential(name: nil, email: ""))

        #expect(manager.session?.name == "Ana")
        #expect(manager.session?.email == "ana@example.com")
    }

    @Test func savedSessionIsRestored() {
        store.save(UserSession(userID: "abc"))

        #expect(makeSessionManager(store: store).isSignedIn)
    }

    @Test func revokedCredentialSignsOut() async {
        store.save(UserSession(userID: "abc"))
        let manager = makeSessionManager(store: store, authorized: false)

        await manager.validateCredential()

        #expect(manager.isSignedIn == false)
    }

    @Test func validCredentialStaysSignedIn() async {
        store.save(UserSession(userID: "abc"))
        let manager = makeSessionManager(store: store, authorized: true)

        await manager.validateCredential()

        #expect(manager.isSignedIn)
    }

    @Test func reportsICloudAvailability() {
        #expect(makeSessionManager(store: store, iCloud: false).isICloudAvailable == false)
    }

    @Test func accountDeletedForgetsTheProfile() {
        let manager = makeSessionManager(store: store)
        manager.signIn(with: appleCredential(name: "Ana"))

        manager.accountDeleted()

        #expect(manager.isSignedIn == false)
        #expect(store.rememberedProfile(for: "abc") == nil)
    }
}
