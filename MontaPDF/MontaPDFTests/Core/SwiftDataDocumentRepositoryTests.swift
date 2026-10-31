//
//  SwiftDataDocumentRepositoryTests.swift
//  MontaPDFTests
//

import Foundation
import SwiftData
import Testing
@testable import MontaPDF

@MainActor
struct SwiftDataDocumentRepositoryTests {
    private let repository: SwiftDataDocumentRepository

    init() throws {
        repository = SwiftDataDocumentRepository(container: try makeInMemoryContainer())
    }

    @Test func createStoresAnAutomaticallyNamedDocument() throws {
        let document = try repository.create(
            pageCount: 3,
            fileName: "a.pdf",
            originalFileName: "photo.heic",
            createdAt: referenceDate
        )

        #expect(document.title.isEmpty)
        #expect(document.isCustomTitle == false)
        #expect(document.pageCount == 3)
        #expect(document.fileName == "a.pdf")
        #expect(document.originalFileName == "photo.heic")
        #expect(document.createdAt == referenceDate)
        #expect(try repository.fetchAll().map(\.id) == [document.id])
    }

    @Test func originalFileNameIsOptional() throws {
        let document = try repository.create(pageCount: 1, fileName: "scan.pdf")

        #expect(document.originalFileName == nil)
    }

    @Test func fetchAllReturnsNewestFirst() throws {
        let old = try repository.create(pageCount: 1, fileName: "old.pdf", originalFileName: nil, createdAt: date(minutesAfterReference: 1))
        let new = try repository.create(pageCount: 1, fileName: "new.pdf", originalFileName: nil, createdAt: date(minutesAfterReference: 2))

        #expect(try repository.fetchAll().map(\.id) == [new.id, old.id])
    }

    @Test func renameSetsATrimmedCustomTitle() throws {
        let document = try repository.create(pageCount: 1, fileName: "a.pdf")

        try repository.rename(document, to: "  Contract  ")

        #expect(document.title == "Contract")
        #expect(document.isCustomTitle)
    }

    @Test(arguments: ["", "   ", "\n"])
    func renameWithBlankTitleBringsBackTheAutomaticName(blank: String) throws {
        let document = try repository.create(pageCount: 1, fileName: "a.pdf")
        try repository.rename(document, to: "Contract")

        try repository.rename(document, to: blank)

        #expect(document.title.isEmpty)
        #expect(document.isCustomTitle == false)
    }

    @Test func deleteRemovesTheDocument() throws {
        let kept = try repository.create(pageCount: 1, fileName: "kept.pdf")
        let removed = try repository.create(pageCount: 1, fileName: "removed.pdf")

        try repository.delete(removed)

        #expect(try repository.fetchAll().map(\.id) == [kept.id])
    }
}
