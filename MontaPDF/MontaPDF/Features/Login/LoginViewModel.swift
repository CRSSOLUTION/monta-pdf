//
//  LoginViewModel.swift
//  MontaPDF
//

import Foundation
import Observation

/// State of the Login screen. The session itself lives in `SessionManager`.
@Observable
@MainActor
final class LoginViewModel {
    private(set) var signInFailed = false

    private let session: SessionManager

    init(session: SessionManager) {
        self.session = session
    }

    var isICloudAvailable: Bool { session.isICloudAvailable }

    func handleSignIn(_ result: AppleSignInResult) {
        switch result {
        case .signedIn(let credential):
            session.signIn(with: credential)
            signInFailed = false
        case .cancelled:
            break // The user closed the Apple sheet: stay on the screen, no message.
        case .failed:
            signInFailed = true
        }
    }

    func dismissSignInError() {
        signInFailed = false
    }
}
