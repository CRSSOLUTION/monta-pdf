//
//  DossierListViewModelTests.swift
//  MontaPDFTests
//

import Foundation
import SwiftData
import Testing
@testable import MontaPDF

@MainActor
struct DossierListViewModelTests {
    private let repository: SwiftDataDossierRepository
    private let documents: SwiftDataDocumentRepository
    private let session: SessionManager
    private let rental: DossierTemplate

    init() throws {
        let container = try makeInMemoryContainer()
        repository = SwiftDataDossierRepository(container: container)
        documents = SwiftDataDocumentRepository(container: container)
        session = makeSessionManager()
        rental = try #require(DossierTemplates.template(id: .rental, localization: "pt-BR"))
    }

    private func makeViewModel() -> DossierListViewModel {
        DossierListViewModel(repository: repository, session: session) {
            DossierTemplates.all(localization: "pt-BR")
        }
    }

    @Test func startsEmpty() {
        let viewModel = makeViewModel()

        viewModel.load()

        #expect(viewModel.isEmpty)
        #expect(viewModel.visibleRows.isEmpty)
        #expect(viewModel.availableTemplates.count == 5)
    }

    @Test func createOpensTheNewDossierAndClosesTheSheet() throws {
        let viewModel = makeViewModel()
        viewModel.startCreating()
        #expect(viewModel.isCreating)

        let id = try #require(viewModel.create(from: rental, name: "Apto Rua das Flores", coverName: "Ana Souza"))

        #expect(viewModel.isCreating == false)
        #expect(viewModel.isEmpty == false)
        #expect(viewModel.visibleRows.map(\.id) == [id])
        let row = try #require(viewModel.visibleRows.first)
        #expect(row.name == "Apto Rua das Flores")
        #expect(row.templateID == .rental)
        #expect(row.progress.addedRequired == 0)
        #expect(row.progress.required == 5)
        #expect(row.status == .inProgress)
    }

    @Test func sentDossiersMoveToTheSentFilter() throws {
        let inProgress = try repository.create(from: rental, name: "Apto", coverName: "")
        let sent = try repository.create(from: rental, name: "Casa", coverName: "")
        try repository.markSent(sent, at: referenceDate)
        let viewModel = makeViewModel()

        viewModel.load()

        #expect(viewModel.inProgressRows.map(\.id) == [inProgress.id])
        #expect(viewModel.sentRows.map(\.id) == [sent.id])
        #expect(viewModel.visibleRows.map(\.id) == [inProgress.id])

        viewModel.filter = .sent
        #expect(viewModel.visibleRows.map(\.id) == [sent.id])
    }

    @Test func readyToSendStaysInTheInProgressFilter() throws {
        let dossier = try repository.create(from: rental, name: "Apto", coverName: "")
        for item in dossier.sortedItems where item.isRequired {
            try repository.attach(try documents.create(NewDocument(pdfData: nil, pageCount: 1)), to: item)
        }
        let viewModel = makeViewModel()

        viewModel.load()

        #expect(viewModel.inProgressRows.first?.status == .readyToSend)
        #expect(viewModel.sentRows.isEmpty)
    }

    @Test func coverNameComesFromTheAppleAccount() {
        #expect(makeViewModel().defaultCoverName.isEmpty)

        session.signIn(with: appleCredential(name: "Ana Souza"))

        #expect(makeViewModel().defaultCoverName == "Ana Souza")
    }

}
