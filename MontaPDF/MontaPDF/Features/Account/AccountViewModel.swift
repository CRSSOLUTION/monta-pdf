//
//  AccountViewModel.swift
//  MontaPDF
//

import Foundation
import Observation

@Observable
@MainActor
final class AccountViewModel {
    private(set) var documentCount = 0
    private(set) var storageBytes: Int64 = 0
    private(set) var errorMessage: String?

    var isConfirmingSignOut = false
    var isConfirmingDelete = false
    var deleteConfirmationText = ""
    /// After typing the confirmation word, the user confirms with Apple once more.
    /// That fresh authorization code is what lets us revoke the Sign in with Apple token.
    var isConfirmingWithApple = false
    private(set) var isDeleting = false

    private let session: SessionManager
    private let repository: DocumentRepository
    private let tokenRevoker: AppleTokenRevoking
    private let bundle: Bundle

    init(
        session: SessionManager,
        repository: DocumentRepository,
        tokenRevoker: AppleTokenRevoking,
        bundle: Bundle = .main
    ) {
        self.session = session
        self.repository = repository
        self.tokenRevoker = tokenRevoker
        self.bundle = bundle
    }

    var name: String? { session.session?.name }
    var email: String? { session.session?.email }

    /// e.g. "1.0 (1)"
    var appVersion: String {
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    /// The word the user must type to delete the account ("DELETE", "EXCLUIR", "ELIMINAR").
    var deleteConfirmationWord: String {
        String(localized: "DELETE", comment: "Word typed to confirm account deletion")
    }

    var canDeleteAccount: Bool {
        deleteConfirmationText.trimmingCharacters(in: .whitespaces).uppercased()
            == deleteConfirmationWord.uppercased()
    }

    func load() {
        do {
            let documents = try repository.fetchAll()
            documentCount = documents.count
            storageBytes = documents.reduce(0) { total, document in
                total + Int64(document.pdfData?.count ?? 0) + Int64(document.originalData?.count ?? 0)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        session.signOut()
    }

    func startDeleteAccount() {
        deleteConfirmationText = ""
        isConfirmingDelete = true
    }

    /// Step 2: the confirmation word was typed, so ask Apple to confirm it's the user.
    func confirmDeleteAccount() {
        guard canDeleteAccount else { return }
        isConfirmingWithApple = true
    }

    func cancelAppleConfirmation() {
        isConfirmingWithApple = false
    }

    /// Step 3: result of "Continue with Apple" in the confirmation sheet.
    func handleAppleConfirmation(_ result: AppleSignInResult) async {
        switch result {
        case .signedIn(let credential):
            guard let code = credential.authorizationCode else {
                isConfirmingWithApple = false
                errorMessage = String(localized: "Couldn't delete your account. Please try again.")
                return
            }
            await deleteAccount(authorizationCode: code)
        case .cancelled:
            isConfirmingWithApple = false
        case .failed:
            isConfirmingWithApple = false
            errorMessage = String(localized: "Couldn't delete your account. Please try again.")
        }
    }

    /// Revokes the Apple token first; only then deletes the documents and signs out.
    /// If revoking fails (e.g. offline), nothing is deleted and the user can try again.
    func deleteAccount(authorizationCode: String) async {
        guard !isDeleting else { return }
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await tokenRevoker.revoke(authorizationCode: authorizationCode)
            try repository.deleteAll()
            isConfirmingWithApple = false
            session.accountDeleted()
        } catch {
            isConfirmingWithApple = false
            errorMessage = String(localized: "Couldn't delete your account. Check your connection and try again.")
        }
    }

    func dismissError() {
        errorMessage = nil
    }
}
