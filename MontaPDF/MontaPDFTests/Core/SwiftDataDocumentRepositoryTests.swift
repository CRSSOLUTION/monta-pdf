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
        let pdf = Data("pdf".utf8)
        let document = try repository.create(NewDocument(pdfData: pdf, pageCount: 3, createdAt: referenceDate))

        #expect(document.title.isEmpty)
        #expect(document.isCustomTitle == false)
        #expect(document.pageCount == 3)
        #expect(document.pdfData == pdf)
        #expect(document.fileName == "\(document.id.uuidString).pdf")
        #expect(document.originalFileName == nil)
        #expect(document.originalData == nil)
        #expect(document.createdAt == referenceDate)
        #expect(try repository.fetchAll().map(\.id) == [document.id])
    }

    @Test func createWithCustomTitleKeepsTheOriginal() throws {
        let original = Data("docx".utf8)
        let document = try repository.create(NewDocument(
            pdfData: Data("pdf".utf8),
            pageCount: 1,
            customTitle: " Contract ",
            originalFileName: "Contract.docx",
            originalData: original
        ))

        #expect(document.title == "Contract")
        #expect(document.isCustomTitle)
        #expect(document.originalFileName == "Contract.docx")
        #expect(document.originalData == original)
    }

    @Test func fetchAllReturnsNewestFirst() throws {
        let old = try repository.create(NewDocument(pdfData: nil, pageCount: 1, createdAt: date(minutesAfterReference: 1)))
        let new = try repository.create(NewDocument(pdfData: nil, pageCount: 1, createdAt: date(minutesAfterReference: 2)))

        #expect(try repository.fetchAll().map(\.id) == [new.id, old.id])
    }

    @Test func renameSetsATrimmedCustomTitle() throws {
        let document = try repository.create(NewDocument(pdfData: nil, pageCount: 1))

        try repository.rename(document, to: "  Contract  ")

        #expect(document.title == "Contract")
        #expect(document.isCustomTitle)
    }

    @Test(arguments: ["", "   ", "\n"])
    func renameWithBlankTitleBringsBackTheAutomaticName(blank: String) throws {
        let document = try repository.create(NewDocument(pdfData: nil, pageCount: 1))
        try repository.rename(document, to: "Contract")

        try repository.rename(document, to: blank)

        #expect(document.title.isEmpty)
        #expect(document.isCustomTitle == false)
    }

    @Test func deleteRemovesTheDocument() throws {
        let kept = try repository.create(NewDocument(pdfData: nil, pageCount: 1))
        let removed = try repository.create(NewDocument(pdfData: nil, pageCount: 1))

        try repository.delete(removed)

        #expect(try repository.fetchAll().map(\.id) == [kept.id])
    }

    @Test func documentByIdFindsOnlyThatDocument() throws {
        let wanted = try repository.create(NewDocument(pdfData: nil, pageCount: 1))
        try repository.create(NewDocument(pdfData: nil, pageCount: 2))

        #expect(try repository.document(id: wanted.id)?.id == wanted.id)
        #expect(try repository.document(id: UUID()) == nil)
    }

    @Test func deleteAllRemovesEverything() throws {
        try repository.create(NewDocument(pdfData: nil, pageCount: 1))
        try repository.create(NewDocument(pdfData: nil, pageCount: 1))

        try repository.deleteAll()

        #expect(try repository.fetchAll().isEmpty)
    }
}
