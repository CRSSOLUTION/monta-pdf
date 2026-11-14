//
//  DossierDetailViewModel.swift
//  MontaPDF
//

import Foundation
import Observation

/// One dossier and its checklist: fill items by scanning, importing or reusing a
/// document of the library, mark them as not applicable, rename, add, reorder and remove.
@Observable
@MainActor
final class DossierDetailViewModel {
    let dossierID: UUID
    private(set) var dossier: Dossier?
    private(set) var isLoaded = false
    var errorMessage: String?

    // Filling an item
    var isAddOptionsPresented = false
    var isFileImporterPresented = false
    var isPhotoPickerPresented = false
    var isLibraryPresented = false
    private(set) var libraryDocuments: [LibraryDocument] = []

    // Renaming, adding and removing items
    var isRenaming = false
    var renameDraft = ""
    var isAddingItem = false
    var isConfirmingRemove = false

    let scanner: ScannerViewModel
    let importer: ImportViewModel

    /// The item being filled, renamed or removed.
    private(set) var targetItemID: UUID?
    private var thumbnails: [UUID: Data] = [:]

    private let repository: DossierRepository
    private let documents: DocumentRepository
    private let namer: DocumentNamer

    init(
        dossierID: UUID,
        repository: DossierRepository,
        documents: DocumentRepository,
        scanner: ScannerViewModel,
        importer: ImportViewModel
    ) {
        self.dossierID = dossierID
        self.repository = repository
        self.documents = documents
        self.scanner = scanner
        self.importer = importer
        self.namer = DocumentNamer()
        scanner.onSaved = { [weak self] id in self?.documentSaved(id: id) }
        importer.onSaved = { [weak self] id in self?.documentSaved(id: id) }
    }

    var requiredItems: [DossierItem] { dossier?.sortedItems.filter(\.isRequired) ?? [] }
    var optionalItems: [DossierItem] { dossier?.sortedItems.filter { !$0.isRequired } ?? [] }

    var targetItem: DossierItem? {
        guard let targetItemID else { return nil }
        return dossier?.sortedItems.first { $0.id == targetItemID }
    }

    func load() {
        dossier = try? repository.dossier(id: dossierID)
        isLoaded = true
    }

    // MARK: - Filling an item

    func startAdding(_ item: DossierItem) {
        targetItemID = item.id
        isAddOptionsPresented = true
    }

    func scan() async {
        await scanner.scanTapped()
    }

    func importFile() {
        isFileImporterPresented = true
    }

    func choosePhotos() {
        isPhotoPickerPresented = true
    }

    func chooseFromLibrary() {
        do {
            let all = try documents.fetchAll()
            let titles = namer.displayTitles(for: all)
            libraryDocuments = all.map {
                LibraryDocument(id: $0.id, title: titles[$0.id] ?? $0.title, pageCount: $0.pageCount, createdAt: $0.createdAt)
            }
            isLibraryPresented = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func libraryDocumentChosen(id: UUID) {
        isLibraryPresented = false
        guard let item = targetItem else { return }
        perform {
            guard let document = try documents.document(id: id) else { return }
            try repository.attach(document, to: item)
        }
        targetItemID = nil
    }

    /// A scan or an import finished. The first saved document fills the item and,
    /// unless the user already named it, takes the item title ("Fiador: RG ou CNH").
    func documentSaved(id: UUID) {
        guard let item = targetItem else { return }
        targetItemID = nil
        perform {
            guard let document = try documents.document(id: id) else { return }
            if !document.isCustomTitle {
                try documents.rename(document, to: item.title)
            }
            try repository.attach(document, to: item)
        }
    }

    func removeDocument(from item: DossierItem) {
        perform { try repository.detach(item) }
    }

    func setNotApplicable(_ notApplicable: Bool, for item: DossierItem) {
        perform { try repository.setNotApplicable(notApplicable, for: item) }
    }

    // MARK: - Editing the list

    func startRename(_ item: DossierItem) {
        targetItemID = item.id
        renameDraft = item.title
        isRenaming = true
    }

    func confirmRename() {
        guard let item = targetItem else { return }
        perform { try repository.rename(item, to: renameDraft) }
        targetItemID = nil
    }

    func startAddingItem() {
        isAddingItem = true
    }

    func addItem(title: String, isRequired: Bool) {
        guard let dossier else { return }
        perform { _ = try repository.addItem(to: dossier, title: title, isRequired: isRequired) }
        isAddingItem = false
    }

    func startRemove(_ item: DossierItem) {
        targetItemID = item.id
        isConfirmingRemove = true
    }

    func confirmRemove() {
        guard let item = targetItem else { return }
        perform { try repository.remove(item) }
        targetItemID = nil
    }

    func removeRequired(at offsets: IndexSet) {
        remove(offsets.map { requiredItems[$0] })
    }

    func removeOptional(at offsets: IndexSet) {
        remove(offsets.map { optionalItems[$0] })
    }

    func moveRequired(from source: IndexSet, to destination: Int) {
        saveOrder(Self.moving(requiredItems, from: source, to: destination) + optionalItems)
    }

    func moveOptional(from source: IndexSet, to destination: Int) {
        saveOrder(requiredItems + Self.moving(optionalItems, from: source, to: destination))
    }

    // MARK: - Thumbnails

    /// First page of the item's document, cached after the first render.
    func thumbnail(for item: DossierItem) async -> Data? {
        guard let document = item.document else { return nil }
        if let cached = thumbnails[document.id] { return cached }
        guard let data = document.pdfData else { return nil }
        let image = await ThumbnailRenderer.render(data, size: CGSize(width: 88, height: 116))
        thumbnails[document.id] = image
        return image
    }

    // MARK: - Private

    /// Same result as SwiftUI's `move(fromOffsets:toOffset:)`, without importing SwiftUI here.
    static func moving<T>(_ items: [T], from source: IndexSet, to destination: Int) -> [T] {
        let moved = source.map { items[$0] }
        var rest = items.enumerated().filter { !source.contains($0.offset) }.map(\.element)
        let insertAt = destination - source.filter { $0 < destination }.count
        rest.insert(contentsOf: moved, at: min(max(insertAt, 0), rest.count))
        return rest
    }

    private func remove(_ items: [DossierItem]) {
        perform {
            for item in items {
                try repository.remove(item)
            }
        }
    }

    private func saveOrder(_ items: [DossierItem]) {
        perform { try repository.reorder(items) }
    }

    private func perform(_ work: () throws -> Void) {
        do {
            try work()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
