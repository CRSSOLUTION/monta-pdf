//
//  DocumentViewerViewModelTests.swift
//  MontaPDFTests
//

import Foundation
import SwiftData
import Testing
@testable import MontaPDF

@MainActor
struct DocumentViewerViewModelTests {
    private let repository: SwiftDataDocumentRepository
    private let exporter = FakeExporter()

    init() throws {
        repository = SwiftDataDocumentRepository(container: try makeInMemoryContainer())
    }

    private func makeViewModel(for id: UUID) -> DocumentViewerViewModel {
        DocumentViewerViewModel(
            documentID: id,
            repository: repository,
            namer: DocumentNamer(automaticTitle: { "Document \($0)" }),
            exporter: exporter
        )
    }

    @Test func loadShowsTitleAndPreparesTheShareFile() throws {
        let document = try repository.create(NewDocument(pdfData: Data("pdf".utf8), pageCount: 1))
        let viewModel = makeViewModel(for: document.id)

        viewModel.load()

        #expect(viewModel.state == .ready)
        #expect(viewModel.title == "Document 1")
        #expect(viewModel.pdfData == Data("pdf".utf8))
        #expect(viewModel.shareURL?.lastPathComponent == "Document 1.pdf")
        #expect(exporter.exportedFileNames == ["Document 1.pdf"])
    }

    @Test func documentWithoutPDFYetIsDownloading() throws {
        let document = try repository.create(NewDocument(pdfData: nil, pageCount: 1))
        let viewModel = makeViewModel(for: document.id)

        viewModel.load()

        #expect(viewModel.state == .downloading)
        #expect(viewModel.shareURL == nil)
    }

    @Test func unknownDocumentIsNotFound() {
        let viewModel = makeViewModel(for: UUID())

        viewModel.load()

        #expect(viewModel.state == .notFound)
    }

    @Test func renameStartsWithCurrentTitleAndSavesTheNewOne() throws {
        let document = try repository.create(NewDocument(pdfData: Data("pdf".utf8), pageCount: 1))
        let viewModel = makeViewModel(for: document.id)
        viewModel.load()

        viewModel.startRename()
        #expect(viewModel.renameDraft == "Document 1")
        #expect(viewModel.isRenaming)

        viewModel.renameDraft = "Lease: 2026"
        viewModel.confirmRename()

        #expect(viewModel.title == "Lease 2026")
        #expect(document.isCustomTitle)
    }

    @Test func deleteRemovesTheDocumentAndClosesTheViewer() throws {
        let document = try repository.create(NewDocument(pdfData: Data("pdf".utf8), pageCount: 1))
        let viewModel = makeViewModel(for: document.id)
        viewModel.load()

        viewModel.confirmDelete()

        #expect(viewModel.isDeleted)
        #expect(try repository.fetchAll().isEmpty)
    }
}
