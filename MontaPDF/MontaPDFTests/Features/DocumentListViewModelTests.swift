//
//  DocumentListViewModelTests.swift
//  MontaPDFTests
//

import Foundation
import SwiftData
import Testing
import UIKit
@testable import MontaPDF

@MainActor
struct DocumentListViewModelTests {
    private let repository: SwiftDataDocumentRepository
    private let exporter = FakeExporter()

    init() throws {
        repository = SwiftDataDocumentRepository(container: try makeInMemoryContainer())
    }

    private func makeViewModel() -> DocumentListViewModel {
        DocumentListViewModel(
            repository: repository,
            namer: DocumentNamer(automaticTitle: { "Document \($0)" }),
            exporter: exporter
        )
    }

    @discardableResult
    private func addDocument(minute: Double, pages: Int = 1) throws -> Document {
        try repository.create(NewDocument(pdfData: nil, pageCount: pages, createdAt: date(minutesAfterReference: minute)))
    }

    // MARK: - List

    @Test func startsEmpty() {
        let viewModel = makeViewModel()

        #expect(viewModel.rows.isEmpty)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func loadShowsNewestFirstWithAutomaticNames() throws {
        try addDocument(minute: 1, pages: 2)
        try addDocument(minute: 2, pages: 5)
        let viewModel = makeViewModel()

        viewModel.load()

        #expect(viewModel.rows.map(\.title) == ["Document 2", "Document 1"])
        #expect(viewModel.rows.map(\.pageCount) == [5, 2])
    }

    @Test func renameShowsCustomTitleAndRenumbersTheOthers() throws {
        let first = try addDocument(minute: 1)
        try addDocument(minute: 2)
        let viewModel = makeViewModel()
        viewModel.load()

        viewModel.rename(id: first.id, to: "Receipt")

        #expect(viewModel.rows.map(\.title) == ["Document 1", "Receipt"])
    }

    @Test func deleteAtOffsetsRemovesTheRowAndRenumbers() throws {
        try addDocument(minute: 1)
        try addDocument(minute: 2)
        try addDocument(minute: 3)
        let viewModel = makeViewModel()
        viewModel.load()

        // Rows are newest first, so offset 2 is the oldest document ("Document 1").
        viewModel.delete(at: IndexSet(integer: 2))

        #expect(viewModel.rows.map(\.title) == ["Document 2", "Document 1"])
        #expect(try repository.fetchAll().count == 2)
    }

    @Test func repositoryFailureShowsAnAlert() {
        let viewModel = DocumentListViewModel(
            repository: FailingDocumentRepository(),
            namer: DocumentNamer(),
            exporter: exporter
        )

        viewModel.load()

        #expect(viewModel.errorMessage == "Test failure")
        #expect(viewModel.rows.isEmpty)
    }

    // MARK: - Saved banner

    @Test func documentAddedReloadsAndShowsTheBanner() throws {
        try addDocument(minute: 1)
        let viewModel = makeViewModel()
        viewModel.load()
        let added = try addDocument(minute: 2, pages: 3)

        viewModel.documentAdded(id: added.id)

        #expect(viewModel.rows.count == 2)
        #expect(viewModel.rows.first?.pageCount == 3)
        #expect(viewModel.savedBanner == SavedBanner(id: added.id, title: "Document 2"))
    }

    @Test func dismissBannerClearsIt() throws {
        let added = try addDocument(minute: 1)
        let viewModel = makeViewModel()
        viewModel.documentAdded(id: added.id)
        #expect(viewModel.savedBanner != nil)

        viewModel.dismissBanner()

        #expect(viewModel.savedBanner == nil)
    }

    // MARK: - Rename, delete, share

    @Test func renameFlowUsesTheCurrentTitleAndSanitizes() throws {
        let document = try addDocument(minute: 1)
        let viewModel = makeViewModel()
        viewModel.load()

        viewModel.startRename(id: document.id)
        #expect(viewModel.isRenaming)
        #expect(viewModel.renameDraft == "Document 1")

        viewModel.renameDraft = " Bills/October "
        viewModel.confirmRename()

        #expect(viewModel.rows.first?.title == "BillsOctober")
    }

    @Test func renamingWithEmptyNameDoesNothing() throws {
        let document = try addDocument(minute: 1)
        let viewModel = makeViewModel()
        viewModel.load()

        viewModel.startRename(id: document.id)
        viewModel.renameDraft = "  "
        viewModel.confirmRename()

        #expect(viewModel.rows.first?.title == "Document 1")
        #expect(document.isCustomTitle == false)
    }

    @Test func deleteAsksFirstThenDeletes() throws {
        let document = try addDocument(minute: 1)
        let viewModel = makeViewModel()
        viewModel.load()

        viewModel.startDelete(id: document.id)
        #expect(viewModel.isConfirmingDelete)
        #expect(viewModel.deleteTarget?.title == "Document 1")
        #expect(viewModel.rows.count == 1)

        viewModel.confirmDelete()

        #expect(viewModel.rows.isEmpty)
        #expect(viewModel.deleteTarget == nil)
    }

    @Test func shareExportsThePDFWithTheDocumentName() throws {
        let document = try repository.create(NewDocument(pdfData: Data("pdf".utf8), pageCount: 1, customTitle: "Contract"))
        let viewModel = makeViewModel()
        viewModel.load()

        viewModel.share(id: document.id)

        #expect(viewModel.shareItem?.url.lastPathComponent == "Contract.pdf")
        #expect(exporter.exportedFileNames == ["Contract.pdf"])
    }

    @Test func shareWithoutPDFDoesNothing() throws {
        let document = try addDocument(minute: 1)
        let viewModel = makeViewModel()
        viewModel.load()

        viewModel.share(id: document.id)

        #expect(viewModel.shareItem == nil)
    }
}
