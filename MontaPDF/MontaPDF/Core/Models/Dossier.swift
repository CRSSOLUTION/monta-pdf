//
//  Dossier.swift
//  MontaPDF
//

import Foundation
import SwiftData

/// A checklist of documents for one situation (renting an apartment, a new job...),
/// assembled into a single PDF. Every property has a default value and relationships
/// are optional, as CloudKit sync requires.
@Model
final class Dossier {
    var id: UUID = UUID()
    /// Name chosen by the user, e.g. "Apto Rua das Flores".
    var name: String = ""
    /// `DossierTemplate.ID` raw value of the template it was created from.
    var templateID: String = ""
    /// Name printed on the cover page. Empty means the cover shows only the dossier name.
    var coverName: String = ""
    var createdAt: Date = Date()
    /// Set when the user confirms the dossier was sent. `nil` means not sent.
    var sentAt: Date?
    /// True when something changed after the dossier was marked as sent.
    var editedAfterSending: Bool = false
    var includesCover: Bool = true
    var includesSummary: Bool = true

    @Relationship(deleteRule: .cascade, inverse: \DossierItem.dossier)
    var items: [DossierItem]? = []

    init(
        id: UUID = UUID(),
        name: String = "",
        templateID: String = "",
        coverName: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.templateID = templateID
        self.coverName = coverName
        self.createdAt = createdAt
    }

    /// Items in checklist order.
    var sortedItems: [DossierItem] {
        (items ?? []).sorted { $0.order < $1.order }
    }

    var progress: DossierProgress {
        DossierProgress(items: sortedItems.map(\.snapshot))
    }

    var status: DossierStatus {
        DossierStatus(progress: progress, sentAt: sentAt)
    }
}
