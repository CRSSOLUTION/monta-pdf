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

    init() throws {
        repository = SwiftDataDocumentRepository(container: try makeInMemoryContainer())
    }

    private func makeViewModel(
        builder: FakePDFBuilder = FakePDFBuilder(),
        availability: FakeScannerAvailability = FakeScannerAvailability()
    ) -> DocumentListViewModel {
        DocumentListViewModel(
            repository: repository,
            namer: DocumentNamer(automaticTitle: { "Document \($0)" }),
            pdfBuilder: builder,
            scannerAvailability: availability
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
        #expect(viewModel.alert == nil)
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
        let viewModel = DocumentListViewModel(repository: FailingDocumentRepository())

        viewModel.load()

        #expect(viewModel.alert == .generic("Test failure"))
        #expect(viewModel.rows.isEmpty)
    }

    // MARK: - Scanner

    @Test func scanOpensTheScannerWhenAvailable() async {
        let viewModel = makeViewModel()

        await viewModel.scanTapped()

        #expect(viewModel.isScannerPresented)
        #expect(viewModel.alert == nil)
    }

    @Test func scanWithCameraDeniedExplainsHowToFix() async {
        let viewModel = makeViewModel(availability: FakeScannerAvailability(cameraAccess: .denied))

        await viewModel.scanTapped()

        #expect(viewModel.isScannerPresented == false)
        #expect(viewModel.alert == .cameraDenied)
    }

    @Test func savingScannedPagesCreatesOneDocumentAndShowsBanner() async throws {
        try addDocument(minute: 1)
        let viewModel = makeViewModel()
        viewModel.load()
        viewModel.isScannerPresented = true

        await viewModel.scannerFinished(with: [makeTestImage(), makeTestImage(), makeTestImage()])

        #expect(viewModel.isScannerPresented == false)
        #expect(viewModel.isSaving == false)
        #expect(viewModel.rows.count == 2)
        let newest = try #require(viewModel.rows.first)
        #expect(newest.title == "Document 2")
        #expect(newest.pageCount == 3)
        #expect(viewModel.savedBanner == SavedBanner(id: newest.id, title: "Document 2"))
        let stored = try #require(try repository.fetchAll().first)
        #expect(stored.pdfData == Data("pdf-3".utf8))
    }

    @Test func failedSaveKeepsPagesAndRetrySavesThem() async throws {
        let viewModel = makeViewModel(builder: FakePDFBuilder(failures: 1))

        await viewModel.saveScannedPages([makeTestImage(), makeTestImage()])

        #expect(viewModel.alert == .saveFailed)
        #expect(viewModel.rows.isEmpty)
        #expect(try repository.fetchAll().isEmpty)

        await viewModel.retrySave()

        #expect(viewModel.rows.count == 1)
        #expect(viewModel.rows.first?.pageCount == 2)
    }

    @Test func discardingPendingPagesMakesRetryDoNothing() async throws {
        let viewModel = makeViewModel(builder: FakePDFBuilder(failures: 1))
        await viewModel.saveScannedPages([makeTestImage()])

        viewModel.discardPendingPages()
        await viewModel.retrySave()

        #expect(viewModel.rows.isEmpty)
        #expect(viewModel.savedBanner == nil)
    }

    @Test func dismissBannerClearsIt() async {
        let viewModel = makeViewModel()
        await viewModel.saveScannedPages([makeTestImage()])
        #expect(viewModel.savedBanner != nil)

        viewModel.dismissBanner()

        #expect(viewModel.savedBanner == nil)
    }
}
