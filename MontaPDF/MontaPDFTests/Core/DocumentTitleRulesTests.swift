//
//  DocumentTitleRulesTests.swift
//  MontaPDFTests
//

import Testing
@testable import MontaPDF

struct DocumentTitleRulesTests {
    @Test func removesSlashAndColonAndTrims() {
        #expect(DocumentTitleRules.sanitize("  Invoice 10/2026: paid ") == "Invoice 102026 paid")
    }

    @Test func limitsTo80Characters() {
        let long = String(repeating: "a", count: 120)

        #expect(DocumentTitleRules.sanitize(long).count == 80)
    }

    @Test func fileNameAddsPDFExtension() {
        #expect(DocumentTitleRules.fileName(for: "Contract") == "Contract.pdf")
        #expect(DocumentTitleRules.fileName(for: "Contract", fileExtension: "docx") == "Contract.docx")
    }

    @Test func fileNameFallsBackWhenTitleIsEmpty() {
        #expect(DocumentTitleRules.fileName(for: " / ") == "Document.pdf")
    }

    @Test func titleFromImportedFileDropsTheExtension() {
        #expect(DocumentTitleRules.title(fromFileName: "Contract.docx") == "Contract")
        #expect(DocumentTitleRules.title(fromFileName: "photo.final.heic") == "photo.final")
    }
}
