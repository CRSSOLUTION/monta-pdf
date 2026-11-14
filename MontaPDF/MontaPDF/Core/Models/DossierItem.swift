//
//  DossierItem.swift
//  MontaPDF
//

import Foundation
import SwiftData

/// One line of a dossier checklist ("RG ou CNH"), optionally linked to a document
/// of the library. The same document can fill items of several dossiers.
@Model
final class DossierItem {
    var id: UUID = UUID()
    var title: String = ""
    var isRequired: Bool = true
    var isNotApplicable: Bool = false
    /// Position in the checklist, starting at 0.
    var order: Int = 0
    var dossier: Dossier?
    /// The document that fills this item. Deleting the document sets this back to `nil`.
    var document: Document?

    init(
        id: UUID = UUID(),
        title: String = "",
        isRequired: Bool = true,
        isNotApplicable: Bool = false,
        order: Int = 0
    ) {
        self.id = id
        self.title = title
        self.isRequired = isRequired
        self.isNotApplicable = isNotApplicable
        self.order = order
    }

    var state: DossierItemState {
        if isNotApplicable { return .notApplicable }
        return document == nil ? .missing : .added
    }

    /// Plain values used by `DossierProgress`, so the rules can be tested without SwiftData.
    var snapshot: DossierItemSnapshot {
        DossierItemSnapshot(title: title, isRequired: isRequired, state: state)
    }
}
