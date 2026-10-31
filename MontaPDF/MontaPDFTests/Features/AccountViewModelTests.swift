//
//  AccountViewModelTests.swift
//  MontaPDFTests
//

import Foundation
import SwiftData
import Testing
@testable import MontaPDF

@MainActor
struct AccountViewModelTests {
    private let repository: SwiftDataDocumentRepository
    private let session: SessionViewModel

    init() throws {
        repository = SwiftDataDocumentRepository(container: try makeInMemoryContainer())
        session = SessionViewModel(
            store: InMemorySessionStore(),
            credentialChecker: FakeCredentialChecker(),
            cloudStatus: FakeCloudStatus()
        )
        session.completeSignIn(userID: "abc", name: "Ana", email: "ana@example.com")
    }

    private func makeViewModel() -> AccountViewModel {
        AccountViewModel(session: session, repository: repository)
    }

    @Test func showsAccountAndUsage() throws {
        try repository.create(NewDocument(pdfData: Data(count: 100), pageCount: 1))
        try repository.create(NewDocument(pdfData: Data(count: 50), pageCount: 1, originalData: Data(count: 25)))
        let viewModel = makeViewModel()

        viewModel.load()

        #expect(viewModel.name == "Ana")
        #expect(viewModel.email == "ana@example.com")
        #expect(viewModel.documentCount == 2)
        #expect(viewModel.storageBytes == 175)
        #expect(viewModel.appVersion.isEmpty == false)
    }

    @Test func signOutEndsTheSessionAndKeepsDocuments() throws {
        try repository.create(NewDocument(pdfData: nil, pageCount: 1))
        let viewModel = makeViewModel()

        viewModel.signOut()

        #expect(session.isSignedIn == false)
        #expect(try repository.fetchAll().count == 1)
    }

    @Test func deleteNeedsTheConfirmationWord() throws {
        try repository.create(NewDocument(pdfData: nil, pageCount: 1))
        let viewModel = makeViewModel()
        viewModel.startDeleteAccount()

        viewModel.deleteConfirmationText = "nope"
        #expect(viewModel.canDeleteAccount == false)
        viewModel.confirmDeleteAccount()

        #expect(session.isSignedIn)
        #expect(try repository.fetchAll().count == 1)
    }

    @Test func deleteAccountRemovesDocumentsAndSignsOut() throws {
        try repository.create(NewDocument(pdfData: nil, pageCount: 1))
        let viewModel = makeViewModel()
        viewModel.startDeleteAccount()

        viewModel.deleteConfirmationText = viewModel.deleteConfirmationWord.lowercased()
        #expect(viewModel.canDeleteAccount)
        viewModel.confirmDeleteAccount()

        #expect(session.isSignedIn == false)
        #expect(try repository.fetchAll().isEmpty)
    }
}
