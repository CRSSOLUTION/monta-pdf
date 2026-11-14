//
//  AssembleDossierViewModelTests.swift
//  MontaPDFTests
//

import Foundation
import SwiftData
import Testing
@testable import MontaPDF

@MainActor
struct AssembleDossierViewModelTests {
    private let repository: SwiftDataDossierRepository
    private let documents: SwiftDataDocumentRepository
    private let exporter = FakeExporter()
    private let dossier: Dossier

    init() throws {
        let container = try makeInMemoryContainer()
        repository = SwiftDataDossierRepository(container: container)
        documents = SwiftDataDocumentRepository(container: container)
        let rental = try #require(DossierTemplates.template(id: .rental, localization: "pt-BR"))
        dossier = try repository.create(from: rental, name: "Apto Rua das Flores", coverName: "Ana Souza")
    }

    private func makeViewModel() -> AssembleDossierViewModel {
        AssembleDossierViewModel(
            dossierID: dossier.id,
            repository: repository,
            assembler: DossierPDFAssembler(),
            exporter: exporter,
            now: { referenceDate }
        )
    }

    /// Fills the required items with real PDFs of 2, 3, 8, 1 and 2 pages (the PRD example).
    private func fillRequiredItems() throws {
        let pages = [2, 3, 8, 1, 2]
        for (item, count) in zip(dossier.sortedItems.filter(\.isRequired), pages) {
            let document = try documents.create(NewDocument(pdfData: blankPDF(pages: count), pageCount: count))
            try repository.attach(document, to: item)
        }
    }

    @Test func loadAssemblesTheWholeDossier() async throws {
        try fillRequiredItems()
        let viewModel = makeViewModel()

        await viewModel.load()

        let assembled = try #require(viewModel.assembled)
        #expect(assembled.pageCount == 18)
        #expect(assembled.entries.map(\.page) == [3, 5, 8, 16, 17])
        #expect(viewModel.isAssembling == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func turningOffCoverAndSummaryIsSavedAndReassembles() async throws {
        try fillRequiredItems()
        let viewModel = makeViewModel()
        await viewModel.load()

        await viewModel.setIncludesCover(false)
        await viewModel.setIncludesSummary(false)

        #expect(dossier.includesCover == false)
        #expect(dossier.includesSummary == false)
        #expect(viewModel.assembled?.pageCount == 16)
        #expect(viewModel.assembled?.entries.first?.page == 1)
    }

    @Test func emptyDossierShowsAnError() async {
        let viewModel = makeViewModel()

        await viewModel.load()

        #expect(viewModel.assembled == nil)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func documentsWithoutAPDFAreLeftOutAndListed() async throws {
        try fillRequiredItems()
        let wordOnly = try documents.create(NewDocument(pdfData: nil, pageCount: 0, originalData: Data("docx".utf8)))
        let marriage = try #require(dossier.sortedItems.first { $0.title == "Certidão de casamento" })
        try repository.attach(wordOnly, to: marriage)
        let viewModel = makeViewModel()

        await viewModel.load()

        #expect(viewModel.unavailableTitles == ["Certidão de casamento"])
        #expect(viewModel.assembled?.pageCount == 18)
    }

    @Test func shareUsesTheDossierAndCoverNames() async throws {
        try fillRequiredItems()
        let viewModel = makeViewModel()
        await viewModel.load()

        viewModel.share()

        #expect(exporter.exportedFileNames == ["Apto Rua das Flores - Ana Souza.pdf"])
        #expect(viewModel.shareItem != nil)
    }

    @Test func completedShareAsksToMarkAsSent() async throws {
        try fillRequiredItems()
        let viewModel = makeViewModel()
        await viewModel.load()
        viewModel.share()

        viewModel.shareFinished(completed: true)
        #expect(viewModel.shareItem == nil)
        viewModel.shareSheetDismissed()
        #expect(viewModel.isAskingSent)

        viewModel.markSent()
        #expect(dossier.status == .sent(referenceDate))
    }

    @Test func cancelledShareDoesNotAsk() async throws {
        try fillRequiredItems()
        let viewModel = makeViewModel()
        await viewModel.load()
        viewModel.share()

        viewModel.shareFinished(completed: false)
        viewModel.shareSheetDismissed()

        #expect(viewModel.isAskingSent == false)
        #expect(dossier.sentAt == nil)
    }

    @Test func alreadySentDossierIsNotAskedAgain() async throws {
        try fillRequiredItems()
        try repository.markSent(dossier, at: referenceDate)
        let viewModel = makeViewModel()
        await viewModel.load()
        viewModel.share()

        viewModel.shareFinished(completed: true)
        viewModel.shareSheetDismissed()

        #expect(viewModel.isAskingSent == false)
    }
}
