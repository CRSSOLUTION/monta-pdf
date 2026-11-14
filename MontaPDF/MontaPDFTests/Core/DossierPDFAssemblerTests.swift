//
//  DossierPDFAssemblerTests.swift
//  MontaPDFTests
//

import Foundation
import PDFKit
import Testing
@testable import MontaPDF

struct DossierPDFAssemblerTests {
    private func input(
        cover: Bool = true,
        summary: Bool = true,
        sections: [DossierPDFInput.Section]
    ) -> DossierPDFInput {
        DossierPDFInput(
            name: "Apto Rua das Flores",
            templateTitle: "Aluguel de imóvel",
            coverName: "Ana Souza",
            date: referenceDate,
            includesCover: cover,
            includesSummary: summary,
            sections: sections
        )
    }

    private let sections = [
        DossierPDFInput.Section(title: "RG ou CNH", pdfData: blankPDF(pages: 2)),
        DossierPDFInput.Section(title: "Comprovante de renda", pdfData: blankPDF(pages: 3))
    ]

    @Test func coverAndSummaryComeBeforeTheDocuments() throws {
        let result = try DossierPDFAssembler().assemble(input(sections: sections))

        #expect(result.pageCount == 7)
        #expect(result.entries.map(\.page) == [3, 5])
        let pdf = try #require(PDFDocument(data: result.data))
        #expect(pdf.pageCount == 7)
        let cover = pdf.page(at: 0)?.string ?? ""
        #expect(cover.contains("Apto Rua das Flores"))
        #expect(cover.contains("Ana Souza"))
        let summary = pdf.page(at: 1)?.string ?? ""
        #expect(summary.contains("1. RG ou CNH"))
        #expect(summary.contains("2. Comprovante de renda"))
    }

    @Test func withoutCoverAndSummaryOnlyTheDocumentsRemain() throws {
        let result = try DossierPDFAssembler().assemble(input(cover: false, summary: false, sections: sections))

        #expect(result.pageCount == 5)
        #expect(result.entries.map(\.page) == [1, 3])
    }

    @Test func nothingToAssembleIsAnError() {
        #expect(throws: DossierPDFError.noDocuments) {
            try DossierPDFAssembler().assemble(input(sections: []))
        }
    }

    @Test func anUnreadableDocumentIsNamedInTheError() {
        let broken = [DossierPDFInput.Section(title: "Fiador", pdfData: Data("not a pdf".utf8))]

        #expect(throws: DossierPDFError.unreadableDocument("Fiador")) {
            try DossierPDFAssembler().assemble(input(sections: broken))
        }
    }
}
