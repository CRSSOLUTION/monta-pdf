//
//  SessionViewModel.swift
//  MontaPDF
//

import AuthenticationServices
import Foundation
import Observation

/// Owns the signed-in state. The app shows Login when `session` is nil.
@Observable
@MainActor
final class SessionViewModel {
    private(set) var session: UserSession?
    private(set) var signInFailed = false

    var isSignedIn: Bool { session != nil }

    private let store: SessionStore
    private let credentialChecker: AppleCredentialChecking
    private let cloudStatus: CloudStatusProviding

    init(
        store: SessionStore,
        credentialChecker: AppleCredentialChecking? = nil,
        cloudStatus: CloudStatusProviding? = nil
    ) {
        self.store = store
        self.credentialChecker = credentialChecker ?? SystemAppleCredentialChecker()
        self.cloudStatus = cloudStatus ?? SystemCloudStatus()
        self.session = store.loadSession()
    }

    var isICloudAvailable: Bool {
        cloudStatus.isICloudAvailable
    }

    /// Signs out if the user revoked Sign in with Apple for this app.
    func validateCredential() async {
        guard let userID = session?.userID else { return }
        let authorized = await credentialChecker.isAuthorized(userID: userID)
        if !authorized {
            signOut()
        }
    }

    func handleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                signInFailed = true
                return
            }
            let name = credential.fullName.flatMap {
                PersonNameComponentsFormatter.localizedString(from: $0, style: .default)
            }
            completeSignIn(userID: credential.user, name: name, email: credential.email)
        case .failure(let error):
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                return // Cancelled by the user: stay on the screen, no message.
            }
            signInFailed = true
        }
    }

    /// Apple sends name and email only the first time, so keep the ones we already know.
    func completeSignIn(userID: String, name: String?, email: String?) {
        let remembered = store.rememberedProfile(for: userID)
        let newSession = UserSession(
            userID: userID,
            name: name.nonEmpty ?? remembered?.name,
            email: email.nonEmpty ?? remembered?.email
        )
        store.save(newSession)
        session = newSession
        signInFailed = false
    }

    func dismissSignInError() {
        signInFailed = false
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
