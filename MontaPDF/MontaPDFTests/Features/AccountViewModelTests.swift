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
    private let session: SessionManager
    private let revoker = FakeTokenRevoker()

    init() throws {
        repository = SwiftDataDocumentRepository(container: try makeInMemoryContainer())
        session = makeSessionManager()
        session.signIn(with: appleCredential(name: "Ana", email: "ana@example.com"))
    }

    private func makeViewModel() -> AccountViewModel {
        AccountViewModel(session: session, repository: repository, tokenRevoker: revoker)
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

    @Test func typingTheWordAsksToConfirmWithApple() throws {
        try repository.create(NewDocument(pdfData: nil, pageCount: 1))
        let viewModel = makeViewModel()
        viewModel.startDeleteAccount()

        viewModel.deleteConfirmationText = viewModel.deleteConfirmationWord.lowercased()
        #expect(viewModel.canDeleteAccount)
        viewModel.confirmDeleteAccount()

        #expect(viewModel.isConfirmingWithApple)
        // Nothing is deleted until Apple confirms.
        #expect(session.isSignedIn)
        #expect(try repository.fetchAll().count == 1)
    }

    @Test func deleteAccountRevokesThenDeletesAndSignsOut() async throws {
        try repository.create(NewDocument(pdfData: nil, pageCount: 1))
        let viewModel = makeViewModel()
        viewModel.isConfirmingWithApple = true

        await viewModel.deleteAccount(authorizationCode: "code-123")

        #expect(revoker.revokedCodes == ["code-123"])
        #expect(try repository.fetchAll().isEmpty)
        #expect(session.isSignedIn == false)
        #expect(viewModel.isConfirmingWithApple == false)
        #expect(viewModel.isDeleting == false)
    }

    @Test func failedRevocationKeepsEverythingAndShowsAnError() async throws {
        try repository.create(NewDocument(pdfData: nil, pageCount: 1))
        revoker.shouldFail = true
        let viewModel = makeViewModel()

        await viewModel.deleteAccount(authorizationCode: "code-123")

        #expect(viewModel.errorMessage != nil)
        #expect(try repository.fetchAll().count == 1)
        #expect(session.isSignedIn)
    }

    @Test func cancellingTheAppleConfirmationDeletesNothing() async throws {
        try repository.create(NewDocument(pdfData: nil, pageCount: 1))
        let viewModel = makeViewModel()
        viewModel.isConfirmingWithApple = true

        await viewModel.handleAppleConfirmation(.cancelled)

        #expect(viewModel.isConfirmingWithApple == false)
        #expect(viewModel.errorMessage == nil)
        #expect(revoker.revokedCodes.isEmpty)
        #expect(try repository.fetchAll().count == 1)
    }

    @Test func confirmingWithAppleUsesTheFreshCodeToDelete() async throws {
        try repository.create(NewDocument(pdfData: nil, pageCount: 1))
        let viewModel = makeViewModel()
        viewModel.isConfirmingWithApple = true

        await viewModel.handleAppleConfirmation(.signedIn(appleCredential(code: "fresh-code")))

        #expect(revoker.revokedCodes == ["fresh-code"])
        #expect(session.isSignedIn == false)
    }

    @Test func confirmationWithoutCodeShowsAnError() async throws {
        try repository.create(NewDocument(pdfData: nil, pageCount: 1))
        let viewModel = makeViewModel()

        await viewModel.handleAppleConfirmation(.signedIn(appleCredential(code: nil)))

        #expect(viewModel.errorMessage != nil)
        #expect(revoker.revokedCodes.isEmpty)
        #expect(try repository.fetchAll().count == 1)
    }
}
