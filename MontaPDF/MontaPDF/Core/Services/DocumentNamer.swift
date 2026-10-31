//
//  DocumentNamer.swift
//  MontaPDF
//

import Foundation

/// Computes the title shown for each document.
///
/// Documents without a custom title are called "Document N", where N is the
/// position of the document among the automatically named documents, ordered
/// by `createdAt` (oldest is 1). A renamed document keeps its custom title and
/// leaves the numbering.
struct DocumentNamer {
    var automaticTitle: (Int) -> String = { number in
        String(localized: "Document \(number)")
    }

    /// Returns the display title for every document, keyed by `Document.id`.
    func displayTitles(for documents: [Document]) -> [UUID: String] {
        var titles: [UUID: String] = [:]

        for document in documents where document.isCustomTitle {
            titles[document.id] = document.title
        }

        let automatic = documents
            .filter { !$0.isCustomTitle }
            .sorted(by: Self.creationOrder)

        for (index, document) in automatic.enumerated() {
            titles[document.id] = automaticTitle(index + 1)
        }

        return titles
    }

    /// Oldest first. Ties are broken by `id` so the order is stable on every device.
    private static func creationOrder(_ lhs: Document, _ rhs: Document) -> Bool {
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        }
        return lhs.id.uuidString < rhs.id.uuidString
    }
}
