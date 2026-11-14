//
//  DossierItemState.swift
//  MontaPDF
//

import Foundation

/// Where a checklist item stands.
nonisolated enum DossierItemState: Equatable, Sendable {
    /// No document yet.
    case missing
    /// Filled with a document.
    case added
    /// The user said it doesn't apply to them (e.g. a marriage certificate for a single person).
    case notApplicable
}
