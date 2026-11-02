//
//  SystemAppleCredentialChecker.swift
//  MontaPDF
//

import AuthenticationServices

struct SystemAppleCredentialChecker: AppleCredentialChecking {
    func isAuthorized(userID: String) async -> Bool {
        do {
            let state = try await ASAuthorizationAppleIDProvider().credentialState(forUserID: userID)
            return state == .authorized
        } catch {
            // Offline or temporary failure: keep the user signed in.
            return true
        }
    }
}
