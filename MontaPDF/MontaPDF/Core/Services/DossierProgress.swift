//
//  DossierProgress.swift
//  MontaPDF
//

import Foundation

/// Progress of a dossier, always shown as "X of Y required".
/// Items marked as not applicable leave the count; optional items never enter it.
nonisolated struct DossierProgress: Equatable, Sendable {
    /// Required items that have a document (the X).
    let addedRequired: Int
    /// Required items that still count (the Y).
    let required: Int
    /// Titles of the required items still missing, in checklist order.
    let missingTitles: [String]
    /// Items with a document, required or optional.
    let addedTotal: Int

    init(items: [DossierItemSnapshot]) {
        let counted = items.filter { $0.isRequired && $0.state != .notApplicable }
        addedRequired = counted.filter { $0.state == .added }.count
        required = counted.count
        missingTitles = counted.filter { $0.state == .missing }.map(\.title)
        addedTotal = items.filter { $0.state == .added }.count
    }

    /// Nothing required is missing and there is at least one document to assemble.
    var isComplete: Bool {
        missingTitles.isEmpty && addedTotal > 0
    }
}
