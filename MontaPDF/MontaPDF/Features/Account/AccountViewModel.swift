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

    private let session: SessionViewModel
    private let repository: DocumentRepository
    private let bundle: Bundle

    init(session: SessionViewModel, repository: DocumentRepository, bundle: Bundle = .main) {
        self.session = session
        self.repository = repository
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

    func confirmDeleteAccount() {
        guard canDeleteAccount else { return }
        do {
            try repository.deleteAll()
            session.accountDeleted()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func dismissError() {
        errorMessage = nil
    }
}
