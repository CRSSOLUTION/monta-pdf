//
//  DossierPDFLayout.swift
//  MontaPDF
//

import Foundation

/// Page numbers of an assembled dossier: cover, summary, then each document.
nonisolated enum DossierPDFLayout {
    /// Summary lines that fit on one A4 page.
    static let entriesPerSummaryPage = 24

    static func summaryPageCount(entries: Int) -> Int {
        max(1, Int((Double(entries) / Double(entriesPerSummaryPage)).rounded(.up)))
    }

    /// Pages before the first document.
    static func frontPageCount(entries: Int, includesCover: Bool, includesSummary: Bool) -> Int {
        (includesCover ? 1 : 0) + (includesSummary ? summaryPageCount(entries: entries) : 0)
    }

    /// Where each document starts, given the page count of each one.
    static func entries(
        titles: [String],
        pageCounts: [Int],
        includesCover: Bool,
        includesSummary: Bool
    ) -> [AssembledDossierPDF.Entry] {
        var page = frontPageCount(entries: titles.count, includesCover: includesCover, includesSummary: includesSummary) + 1
        return zip(titles, pageCounts).map { title, count in
            defer { page += count }
            return AssembledDossierPDF.Entry(title: title, page: page)
        }
    }

    static func totalPages(pageCounts: [Int], includesCover: Bool, includesSummary: Bool) -> Int {
        frontPageCount(entries: pageCounts.count, includesCover: includesCover, includesSummary: includesSummary)
            + pageCounts.reduce(0, +)
    }
}
