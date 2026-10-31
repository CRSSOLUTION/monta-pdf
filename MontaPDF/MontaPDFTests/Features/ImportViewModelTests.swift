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

    @Test func mixingWordWithOtherFilesIsUnsupported() async throws {
        await viewModel.importFiles([
            ImportedFile(name: "Contract.docx", data: Data("docx".utf8)),
            try imageFile("a.png")
        ])

        #expect(viewModel.alert == .unsupported)
    }

    @Test func cancelDiscardsThePreview() async throws {
        await viewModel.importFiles([try imageFile("a.png")])

        viewModel.cancelPreview()

        #expect(viewModel.preview == nil)
        #expect(try repository.fetchAll().isEmpty)
    }
}
