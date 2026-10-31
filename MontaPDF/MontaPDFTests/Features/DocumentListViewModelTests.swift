//
//  DocumentListViewModelTests.swift
//  MontaPDFTests
//

import Foundation
import SwiftData
import Testing
@testable import MontaPDF

@MainActor
struct DocumentListViewModelTests {
    private let repository: SwiftDataDocumentRepository
    private let viewModel: DocumentListViewModel

    init() throws {
        repository = SwiftDataDocumentRepository(container: try makeInMemoryContainer())
        viewModel = DocumentListViewModel(
            repository: repository,
            namer: DocumentNamer(automaticTitle: { "Document \($0)" })
        )
    }

    @discardableResult
    private func addDocument(minute: Double, pages: Int = 1) throws -> Document {
        try repository.create(
            pageCount: pages,
            fileName: "\(minute).pdf",
            originalFileName: nil,
            createdAt: date(minutesAfterReference: minute)
        )
    }

    @Test func startsEmpty() {
        #expect(viewModel.rows.isEmpty)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func loadShowsNewestFirstWithAutomaticNames() throws {
        try addDocument(minute: 1, pages: 2)
        try addDocument(minute: 2, pages: 5)

        viewModel.load()

        #expect(viewModel.rows.map(\.title) == ["Document 2", "Document 1"])
        #expect(viewModel.rows.map(\.pageCount) == [5, 2])
    }

    @Test func renameShowsCustomTitleAndRenumbersTheOthers() throws {
        let first = try addDocument(minute: 1)
        try addDocument(minute: 2)
        viewModel.load()

        viewModel.rename(id: first.id, to: "Receipt")

        #expect(viewModel.rows.map(\.title) == ["Document 1", "Receipt"])
    }

    @Test func deleteAtOffsetsRemovesTheRowAndRenumbers() throws {
        try addDocument(minute: 1)
        try addDocument(minute: 2)
        try addDocument(minute: 3)
        viewModel.load()

        // Rows are newest first, so offset 2 is the oldest document ("Document 1").
        viewModel.delete(at: IndexSet(integer: 2))

        #expect(viewModel.rows.map(\.title) == ["Document 2", "Document 1"])
        #expect(try repository.fetchAll().count == 2)
    }

    @Test func renameUnknownIdChangesNothing() throws {
        try addDocument(minute: 1)
        viewModel.load()

        viewModel.rename(id: UUID(), to: "Ghost")

        #expect(viewModel.rows.map(\.title) == ["Document 1"])
    }

    @Test func failureShowsAnErrorThatCanBeDismissed() {
        let failing = DocumentListViewModel(repository: FailingDocumentRepository())

        failing.load()

        #expect(failing.errorMessage == "Test failure")
        #expect(failing.rows.isEmpty)

        failing.dismissError()

        #expect(failing.errorMessage == nil)
    }
}
