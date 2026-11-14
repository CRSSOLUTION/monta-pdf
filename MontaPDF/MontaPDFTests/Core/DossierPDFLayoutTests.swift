//
//  DossierPDFLayoutTests.swift
//  MontaPDFTests
//

import Foundation
import Testing
@testable import MontaPDF

struct DossierPDFLayoutTests {
    private let titles = ["RG ou CNH", "Comprovante de renda", "Imposto de Renda", "Comprovante de residência", "Fiador: RG ou CNH"]
    private let pages = [2, 3, 8, 1, 2]

    @Test func matchesThePRDExample() {
        let entries = DossierPDFLayout.entries(titles: titles, pageCounts: pages, includesCover: true, includesSummary: true)

        #expect(entries.map(\.page) == [3, 5, 8, 16, 17])
        #expect(entries.map(\.title) == titles)
        #expect(DossierPDFLayout.totalPages(pageCounts: pages, includesCover: true, includesSummary: true) == 18)
    }

    @Test func withoutCoverAndSummaryTheFirstDocumentStartsOnPageOne() {
        let entries = DossierPDFLayout.entries(titles: titles, pageCounts: pages, includesCover: false, includesSummary: false)

        #expect(entries.map(\.page) == [1, 3, 6, 14, 15])
        #expect(DossierPDFLayout.totalPages(pageCounts: pages, includesCover: false, includesSummary: false) == 16)
    }

    @Test func onlyOneOfCoverOrSummaryAddsOnePage() {
        #expect(DossierPDFLayout.entries(titles: ["A"], pageCounts: [1], includesCover: true, includesSummary: false).first?.page == 2)
        #expect(DossierPDFLayout.entries(titles: ["A"], pageCounts: [1], includesCover: false, includesSummary: true).first?.page == 2)
    }

    @Test func longSummariesTakeMorePages() {
        let perPage = DossierPDFLayout.entriesPerSummaryPage

        #expect(DossierPDFLayout.summaryPageCount(entries: 0) == 1)
        #expect(DossierPDFLayout.summaryPageCount(entries: perPage) == 1)
        #expect(DossierPDFLayout.summaryPageCount(entries: perPage + 1) == 2)
        let entries = DossierPDFLayout.entries(
            titles: Array(repeating: "Doc", count: perPage + 1),
            pageCounts: Array(repeating: 1, count: perPage + 1),
            includesCover: true,
            includesSummary: true
        )
        #expect(entries.first?.page == 4)
    }
}
