//
//  SessionViewModelTests.swift
//  MontaPDFTests
//

import AuthenticationServices
import Foundation
import Testing
@testable import MontaPDF

@MainActor
struct SessionViewModelTests {
    private let store = InMemorySessionStore()

    private func makeViewModel(authorized: Bool = true, iCloud: Bool = true) -> SessionViewModel {
        SessionViewModel(
            store: store,
            credentialChecker: FakeCredentialChecker(authorized: authorized),
            cloudStatus: FakeCloudStatus(isICloudAvailable: iCloud)
        )
    }

    @Test func withoutSessionShowsLogin() {
        #expect(makeViewModel().isSignedIn == false)
    }

    @Test func signInSavesTheSession() {
        let viewModel = makeViewModel()

        viewModel.completeSignIn(userID: "abc", name: "Ana Souza", email: "ana@example.com")

        #expect(viewModel.isSignedIn)
        #expect(viewModel.session == UserSession(userID: "abc", name: "Ana Souza", email: "ana@example.com"))
        #expect(store.loadSession()?.userID == "abc")
    }

    @Test func secondSignInKeepsNameAndEmailAppleDoesNotSendAgain() {
        let viewModel = makeViewModel()
        viewModel.completeSignIn(userID: "abc", name: "Ana", email: "ana@example.com")
        viewModel.signOut()

        viewModel.completeSignIn(userID: "abc", name: nil, email: "")

        #expect(viewModel.session?.name == "Ana")
        #expect(viewModel.session?.email == "ana@example.com")
    }

    @Test func savedSessionSkipsLogin() {
        store.save(UserSession(userID: "abc"))

        #expect(makeViewModel().isSignedIn)
    }

    @Test func cancelledSignInShowsNoError() {
        let viewModel = makeViewModel()

        viewModel.handleSignIn(.failure(ASAuthorizationError(.canceled)))

        #expect(viewModel.signInFailed == false)
        #expect(viewModel.isSignedIn == false)
    }

    @Test func failedSignInShowsAnError() {
        let viewModel = makeViewModel()

        viewModel.handleSignIn(.failure(ASAuthorizationError(.failed)))

        #expect(viewModel.signInFailed)

        viewModel.dismissSignInError()
        #expect(viewModel.signInFailed == false)
    }

    @Test func revokedCredentialSignsOut() async {
        store.save(UserSession(userID: "abc"))
        let viewModel = makeViewModel(authorized: false)

        await viewModel.validateCredential()

        #expect(viewModel.isSignedIn == false)
    }

    @Test func validCredentialStaysSignedIn() async {
        store.save(UserSession(userID: "abc"))
        let viewModel = makeViewModel(authorized: true)

        await viewModel.validateCredential()

        #expect(viewModel.isSignedIn)
    }

    @Test func reportsICloudAvailability() {
        #expect(makeViewModel(iCloud: false).isICloudAvailable == false)
    }

    @Test func accountDeletedForgetsTheProfile() {
        let viewModel = makeViewModel()
        viewModel.completeSignIn(userID: "abc", name: "Ana", email: nil)

        viewModel.accountDeleted()

        #expect(viewModel.isSignedIn == false)
        #expect(store.rememberedProfile(for: "abc") == nil)
    }
}
