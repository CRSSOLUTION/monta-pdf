//
//  DocumentRoute.swift
//  MontaPDF
//

import Foundation

/// Opens a document from a dossier checklist. A separate type from the dossier id,
/// so both can be pushed on the same navigation stack.
nonisolated struct DocumentRoute: Hashable, Sendable {
    let id: UUID
}
