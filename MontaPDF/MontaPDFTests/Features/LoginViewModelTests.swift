//
//  LoginViewModelTests.swift
//  MontaPDFTests
//

import Foundation
import Testing
@testable import MontaPDF

@MainActor
struct LoginViewModelTests {
    private let session = makeSessionManager()

    @Test func successfulSignInStartsTheSession() {
        let viewModel = LoginViewModel(session: session)

        viewModel.handleSignIn(.signedIn(appleCredential(name: "Ana")))

        #expect(session.isSignedIn)
        #expect(viewModel.signInFailed == false)
    }

    @Test func cancelledSignInShowsNoError() {
        let viewModel = LoginViewModel(session: session)

        viewModel.handleSignIn(.cancelled)

        #expect(viewModel.signInFailed == false)
        #expect(session.isSignedIn == false)
    }

    @Test func failedSignInShowsAnErrorThatCanBeDismissed() {
        let viewModel = LoginViewModel(session: session)

        viewModel.handleSignIn(.failed)
        #expect(viewModel.signInFailed)

        viewModel.dismissSignInError()
        #expect(viewModel.signInFailed == false)
    }

    @Test func showsWhetherICloudIsOn() {
        let viewModel = LoginViewModel(session: makeSessionManager(iCloud: false))

        #expect(viewModel.isICloudAvailable == false)
    }
}
