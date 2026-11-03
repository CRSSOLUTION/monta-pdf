//
//  ImportViewModelTests.swift
//  MontaPDFTests
//

import Foundation
import SwiftData
import Testing
import UIKit
@testable import MontaPDF

@MainActor
struct ImportViewModelTests {
    private let repository: SwiftDataDocumentRepository
    private let converter = FakeDocumentConverter()
    private let viewModel: ImportViewModel

    init() throws {
        repository = SwiftDataDocumentRepository(container: try makeInMemoryContainer())
        viewModel = ImportViewModel(repository: repository, pdfBuilder: FakePDFBuilder(), converter: converter)
    }

    private func imageFile(_ name: String) throws -> ImportedFile {
        ImportedFile(name: name, data: try #require(makeTestImage().pngData()))
    }

    @Test func severalImagesBecomeOnePreviewWithAutomaticName() async throws {
        await viewModel.importFiles([try imageFile("a.png"), try imageFile("b.png")])

        let preview = try #require(viewModel.preview)
        #expect(preview.pageCount == 2)
        #expect(preview.title == nil)
        #expect(preview.isWord == false)
    }

    @Test func singleImageKeepsItsFileName() async throws {
        await viewModel.importFiles([try imageFile("Receipt.heic")])

        #expect(viewModel.preview?.title == "Receipt")
    }

    @Test func savingThePreviewCreatesTheDocument() async throws {
        var savedID: UUID?
        viewModel.onSaved = { savedID = $0 }
        await viewModel.importFiles([try imageFile("Receipt.png")])

        viewModel.savePreview()

        let document = try #require(try repository.fetchAll().first)
        #expect(document.title == "Receipt")
        #expect(document.pageCount == 1)
        #expect(savedID == document.id)
        #expect(viewModel.preview == nil)
    }

    @Test func pdfIsSavedAsItIsWithoutPreview() async throws {
        let pdf = try makeTestPDF(pages: 3)

        await viewModel.importFiles([ImportedFile(name: "Bill.pdf", data: pdf)])

        #expect(viewModel.preview == nil)
        let document = try #require(try repository.fetchAll().first)
        #expect(document.title == "Bill")
        #expect(document.pageCount == 3)
        #expect(document.pdfData == pdf)
    }

    @Test func invalidPDFIsRejected() async throws {
        await viewModel.importFiles([ImportedFile(name: "Broken.pdf", data: Data("nope".utf8))])

        #expect(viewModel.alert == .unsupported)
        #expect(try repository.fetchAll().isEmpty)
    }

    @Test func wordIsConvertedAndKeepsTheOriginal() async throws {
        let docx = Data("docx".utf8)
        await viewModel.importFiles([ImportedFile(name: "Contract.docx", data: docx)])

        let preview = try #require(viewModel.preview)
        #expect(preview.isWord)
        #expect(preview.pageCount == 4)
        #expect(preview.title == "Contract")
        #expect(converter.convertedFileNames == ["Contract.docx"])

        viewModel.savePreview()

        let document = try #require(try repository.fetchAll().first)
        #expect(document.title == "Contract")
        #expect(document.originalFileName == "Contract.docx")
        #expect(document.originalData == docx)
        #expect(document.pdfData == Data("converted".utf8))
    }

    @Test func keepOriginalSavesTheWordFileWithoutPDF() async throws {
        await viewModel.importFiles([ImportedFile(name: "Contract.docx", data: Data("docx".utf8))])

        viewModel.keepOriginal()

        let document = try #require(try repository.fetchAll().first)
        #expect(document.pdfData == nil)
        #expect(document.originalData == Data("docx".utf8))
        #expect(viewModel.preview == nil)
    }

    @Test func failedConversionStillAllowsKeepingTheOriginal() async throws {
        converter.shouldFail = true
        await viewModel.importFiles([ImportedFile(name: "Contract.docx", data: Data("docx".utf8))])

        #expect(viewModel.alert == .conversionFailed)
        #expect(viewModel.preview == nil)

        viewModel.keepOriginal()

        #expect(try repository.fetchAll().first?.originalFileName == "Contract.docx")
    }

    @Test func unsupportedFormatSavesNothing() async throws {
        await viewModel.importFiles([ImportedFile(name: "sheet.xlsx", data: Data("x".utf8))])

        #expect(viewModel.alert == .unsupported)
        #expect(try repository.fetchAll().isEmpty)
    }

    @Test func severalPDFsBecomeOneDocumentEach() async throws {
        var savedIDs: [UUID] = []
        viewModel.onSaved = { savedIDs.append($0) }

        await viewModel.importFiles([
            ImportedFile(name: "Grocery receipt.pdf", data: try makeTestPDF(pages: 1)),
            ImportedFile(name: "Lecture notes.pdf", data: try makeTestPDF(pages: 2)),
            ImportedFile(name: "Carrot cake recipe.pdf", data: try makeTestPDF(pages: 1))
        ])

        let documents = try repository.fetchAll()
        #expect(documents.count == 3)
        #expect(Set(documents.map(\.title)) == ["Grocery receipt", "Lecture notes", "Carrot cake recipe"])
        #expect(documents.first { $0.title == "Lecture notes" }?.pageCount == 2)
        #expect(savedIDs.count == 3)
        #expect(viewModel.alert == nil)
        #expect(viewModel.preview == nil)
    }

    @Test func mixedFilesAreEachSavedWithoutPreview() async throws {
        await viewModel.importFiles([
            ImportedFile(name: "Contract.docx", data: Data("docx".utf8)),
            ImportedFile(name: "Bill.pdf", data: try makeTestPDF(pages: 3)),
            try imageFile("Photo.png")
        ])

        let documents = try repository.fetchAll()
        #expect(documents.count == 3)
        let contract = try #require(documents.first { $0.title == "Contract" })
        #expect(contract.pdfData == Data("converted".utf8))
        #expect(contract.originalData == Data("docx".utf8))
        #expect(documents.first { $0.title == "Bill" }?.pageCount == 3)
        #expect(documents.first { $0.title == "Photo" }?.pageCount == 1)
        #expect(viewModel.preview == nil)
        #expect(viewModel.alert == nil)
    }

    @Test func wordThatFailsInABatchKeepsTheOriginal() async throws {
        converter.shouldFail = true

        await viewModel.importFiles([
            ImportedFile(name: "Contract.docx", data: Data("docx".utf8)),
            ImportedFile(name: "Bill.pdf", data: try makeTestPDF(pages: 1))
        ])

        let contract = try #require(try repository.fetchAll().first { $0.title == "Contract" })
        #expect(contract.pdfData == nil)
        #expect(contract.originalData == Data("docx".utf8))
        #expect(viewModel.alert == nil)
    }

    @Test func unreadableFilesInABatchAreSkippedAndCounted() async throws {
        await viewModel.importFiles([
            ImportedFile(name: "Bill.pdf", data: try makeTestPDF(pages: 1)),
            ImportedFile(name: "Broken.pdf", data: Data("nope".utf8)),
            ImportedFile(name: "sheet.xlsx", data: Data("x".utf8))
        ])

        #expect(try repository.fetchAll().map(\.title) == ["Bill"])
        #expect(viewModel.alert == .someFilesSkipped(2))
    }

    @Test func cancelDiscardsThePreview() async throws {
        await viewModel.importFiles([try imageFile("a.png")])

        viewModel.cancelPreview()

        #expect(viewModel.preview == nil)
        #expect(try repository.fetchAll().isEmpty)
    }
}
