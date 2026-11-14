//
//  DossierRepository.swift
//  MontaPDF
//

import Foundation

@MainActor
protocol DossierRepository {
    /// All dossiers, newest first.
    func fetchAll() throws -> [Dossier]

    func dossier(id: UUID) throws -> Dossier?

    /// Creates a dossier with a copy of the template items, in the template order.
    /// An empty name falls back to the template title.
    @discardableResult
    func create(from template: DossierTemplate, name: String, coverName: String) throws -> Dossier

    func rename(_ dossier: Dossier, to name: String) throws

    func setCoverName(_ coverName: String, for dossier: Dossier) throws

    /// Adds an item at the end of the checklist. An empty title is ignored and returns `nil`.
    @discardableResult
    func addItem(to dossier: Dossier, title: String, isRequired: Bool) throws -> DossierItem?

    /// Renames an item. An empty title keeps the current one.
    func rename(_ item: DossierItem, to title: String) throws

    /// Fills an item with a document. Also clears "not applicable".
    func attach(_ document: Document, to item: DossierItem) throws

    /// Takes the document out of the item. The document stays in the library.
    func detach(_ item: DossierItem) throws

    /// Marks an item as not applicable (taking its document out) or as needed again.
    func setNotApplicable(_ notApplicable: Bool, for item: DossierItem) throws

    /// Saves the checklist order given by the array.
    func reorder(_ items: [DossierItem]) throws

    func remove(_ item: DossierItem) throws

    /// Whether the assembled PDF starts with a cover and a summary.
    func setOptions(includesCover: Bool, includesSummary: Bool, for dossier: Dossier) throws

    func markSent(_ dossier: Dossier, at date: Date) throws

    /// Takes a sent dossier back to "in progress".
    func reopen(_ dossier: Dossier) throws

    /// Deletes the dossier and its items. The documents stay in the library.
    func delete(_ dossier: Dossier) throws

    /// Deletes every dossier (used when the account is deleted).
    func deleteAll() throws
}
