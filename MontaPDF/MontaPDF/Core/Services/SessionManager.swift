//
//  SessionManager.swift
//  MontaPDF
//

import Foundation
import Observation

/// App-wide session state, shared by Login, Account and the root view.
/// The app shows Login while `session` is nil.
@Observable
@MainActor
final class SessionManager {
    private(set) var session: UserSession?

    var isSignedIn: Bool { session != nil }

    var isICloudAvailable: Bool { cloudStatus.isICloudAvailable }

    private let store: SessionStore
    private let credentialChecker: AppleCredentialChecking
    private let cloudStatus: CloudStatusProviding

    init(store: SessionStore, credentialChecker: AppleCredentialChecking, cloudStatus: CloudStatusProviding) {
        self.store = store
        self.credentialChecker = credentialChecker
        self.cloudStatus = cloudStatus
        self.session = store.loadSession()
    }

    /// Apple sends name and email only the first time, so keep the ones we already know.
    func signIn(with credential: AppleSignInCredential) {
        let remembered = store.rememberedProfile(for: credential.userID)
        let newSession = UserSession(
            userID: credential.userID,
            name: credential.fullName.nonEmpty ?? remembered?.name,
            email: credential.email.nonEmpty ?? remembered?.email
        )
        store.save(newSession)
        session = newSession
    }

    /// Signs out if the user revoked Sign in with Apple for this app in Settings.
    func validateCredential() async {
        guard let userID = session?.userID else { return }
        let authorized = await credentialChecker.isAuthorized(userID: userID)
        if !authorized {
            signOut()
        }
    }

    func signOut() {
        store.signOut()
        session = nil
    }

    /// Forgets the account after its documents were deleted.
    func accountDeleted() {
        store.deleteAll()
        session = nil
    }
}

private extension Optional where Wrapped == String {
    var nonEmpty: String? {
        guard let value = self?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value
    }
}
