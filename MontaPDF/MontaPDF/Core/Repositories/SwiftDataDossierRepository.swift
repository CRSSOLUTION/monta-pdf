//
//  SwiftDataDossierRepository.swift
//  MontaPDF
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataDossierRepository: DossierRepository {
    /// Kept so the container lives as long as the repository uses its context.
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init(container: ModelContainer) {
        self.container = container
    }

    func fetchAll() throws -> [Dossier] {
        let descriptor = FetchDescriptor<Dossier>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func dossier(id: UUID) throws -> Dossier? {
        var descriptor = FetchDescriptor<Dossier>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    @discardableResult
    func create(from template: DossierTemplate, name: String, coverName: String) throws -> Dossier {
        let cleanName = DocumentTitleRules.sanitize(name)
        let dossier = Dossier(
            name: cleanName.isEmpty ? template.title : cleanName,
            templateID: template.id.rawValue,
            coverName: coverName.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        context.insert(dossier)
        for (index, templateItem) in template.items.enumerated() {
            let item = DossierItem(title: templateItem.title, isRequired: templateItem.isRequired, order: index)
            context.insert(item)
            item.dossier = dossier
        }
        try context.save()
        return dossier
    }

    func rename(_ dossier: Dossier, to name: String) throws {
        let cleanName = DocumentTitleRules.sanitize(name)
        guard !cleanName.isEmpty else { return }
        dossier.name = cleanName
        try context.save()
    }

    func setCoverName(_ coverName: String, for dossier: Dossier) throws {
        dossier.coverName = coverName.trimmingCharacters(in: .whitespacesAndNewlines)
        try context.save()
    }

    @discardableResult
    func addItem(to dossier: Dossier, title: String, isRequired: Bool) throws -> DossierItem? {
        let cleanTitle = DocumentTitleRules.sanitize(title)
        guard !cleanTitle.isEmpty else { return nil }
        let nextOrder = (dossier.items ?? []).map(\.order).max().map { $0 + 1 } ?? 0
        let item = DossierItem(title: cleanTitle, isRequired: isRequired, order: nextOrder)
        context.insert(item)
        item.dossier = dossier
        markEdited(dossier)
        try context.save()
        return item
    }

    func rename(_ item: DossierItem, to title: String) throws {
        let cleanTitle = DocumentTitleRules.sanitize(title)
        guard !cleanTitle.isEmpty else { return }
        item.title = cleanTitle
        markEdited(item.dossier)
        try context.save()
    }

    func attach(_ document: Document, to item: DossierItem) throws {
        item.document = document
        item.isNotApplicable = false
        markEdited(item.dossier)
        try context.save()
    }

    func detach(_ item: DossierItem) throws {
        item.document = nil
        markEdited(item.dossier)
        try context.save()
    }

    func setNotApplicable(_ notApplicable: Bool, for item: DossierItem) throws {
        item.isNotApplicable = notApplicable
        if notApplicable {
            item.document = nil
        }
        markEdited(item.dossier)
        try context.save()
    }

    func reorder(_ items: [DossierItem]) throws {
        for (index, item) in items.enumerated() {
            item.order = index
        }
        markEdited(items.first?.dossier)
        try context.save()
    }

    func remove(_ item: DossierItem) throws {
        let dossier = item.dossier
        // Leave the checklist right away, without waiting for the context to process the delete.
        dossier?.items?.removeAll { $0.id == item.id }
        context.delete(item)
        markEdited(dossier)
        try context.save()
    }

    func markSent(_ dossier: Dossier, at date: Date) throws {
        dossier.sentAt = date
        dossier.editedAfterSending = false
        try context.save()
    }

    func reopen(_ dossier: Dossier) throws {
        dossier.sentAt = nil
        dossier.editedAfterSending = false
        try context.save()
    }

    func delete(_ dossier: Dossier) throws {
        context.delete(dossier)
        try context.save()
    }

    func deleteAll() throws {
        // One by one (not a batch delete) so CloudKit also removes each record.
        for dossier in try fetchAll() {
            context.delete(dossier)
        }
        try context.save()
    }

    /// A sent dossier that changes keeps its "sent" status and shows a warning.
    private func markEdited(_ dossier: Dossier?) {
        guard let dossier, dossier.sentAt != nil else { return }
        dossier.editedAfterSending = true
    }
}
