//
//  DocumentShareFilesTests.swift
//  MontaPDFTests
//

import Foundation
import SwiftData
import Testing
@testable import MontaPDF

@MainActor
struct DocumentShareFilesTests {
    private let container: ModelContainer
    private let exporter = FakeExporter()
    private var shareFiles: DocumentShareFiles { DocumentShareFiles(exporter: exporter) }

    init() throws {
        container = try makeInMemoryContainer()
    }

    @Test func pdfIsNamedAfterTheTitle() throws {
        let document = Document(pdfData: Data("pdf".utf8))

        let url = try shareFiles.pdfURL(for: document, title: "Contract")

        #expect(url?.lastPathComponent == "Contract.pdf")
    }

    @Test func noPDFMeansNoFile() throws {
        let document = Document(originalData: Data("docx".utf8))

        #expect(try shareFiles.pdfURL(for: document, title: "Contract") == nil)
    }

    @Test func originalKeepsItsExtension() throws {
        let document = Document(originalFileName: "Lease.doc", originalData: Data("doc".utf8))

        let url = try shareFiles.originalURL(for: document, title: "Lease")

        #expect(url?.lastPathComponent == "Lease.doc")
    }

    @Test func originalWithoutExtensionFallsBackToDocx() throws {
        let document = Document(originalFileName: "Lease", originalData: Data("doc".utf8))

        let url = try shareFiles.originalURL(for: document, title: "Lease")

        #expect(url?.lastPathComponent == "Lease.docx")
    }

    @Test func noOriginalMeansNoFile() throws {
        let document = Document(pdfData: Data("pdf".utf8))

        #expect(try shareFiles.originalURL(for: document, title: "Scan") == nil)
    }
}
