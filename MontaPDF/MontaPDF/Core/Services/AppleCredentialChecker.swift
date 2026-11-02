//
//  AppleCredentialChecker.swift
//  MontaPDF
//

import Foundation

/// Checks whether the Apple ID is still authorized for the app (the user can revoke it in Settings).
protocol AppleCredentialChecking {
    func isAuthorized(userID: String) async -> Bool
}
