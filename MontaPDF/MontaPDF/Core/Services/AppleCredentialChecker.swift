//
//  AppleCredentialChecker.swift
//  MontaPDF
//

import AuthenticationServices

/// Checks whether the Apple ID is still authorized for the app (the user can revoke it in Settings).
protocol AppleCredentialChecking {
    func isAuthorized(userID: String) async -> Bool
}

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

/// Tells whether iCloud is on, so we can warn that documents stay only on this device.
protocol CloudStatusProviding {
    var isICloudAvailable: Bool { get }
}

struct SystemCloudStatus: CloudStatusProviding {
    var isICloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }
}
