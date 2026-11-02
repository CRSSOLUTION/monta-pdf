//
//  AppleSignIn.swift
//  MontaPDF
//

import Foundation

/// What we keep from a Sign in with Apple credential, in our own types,
/// so ViewModels don't depend on AuthenticationServices.
nonisolated struct AppleSignInCredential: Equatable, Sendable {
    let userID: String
    /// Sent by Apple only on the first sign-in.
    let fullName: String?
    /// Sent by Apple only on the first sign-in (may be a private relay address).
    let email: String?
    /// Short-lived code, used to revoke the token when the account is deleted.
    let authorizationCode: String?
}

nonisolated enum AppleSignInResult: Equatable, Sendable {
    case signedIn(AppleSignInCredential)
    /// The user closed the Apple sheet: no error message.
    case cancelled
    case failed
}
