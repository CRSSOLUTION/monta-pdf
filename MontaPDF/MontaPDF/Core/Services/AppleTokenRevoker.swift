//
//  AppleTokenRevoker.swift
//  MontaPDF
//

import Foundation

/// Revokes the user's Sign in with Apple token when the account is deleted
/// (App Store guideline 5.1.1(v)). The signing key lives on the server, never in the app.
protocol AppleTokenRevoking {
    func revoke(authorizationCode: String) async throws
}
