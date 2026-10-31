//
//  DocumentListViewModel.swift
//  MontaPDF
//

import Foundation
import Observation
import UIKit

/// What the document list shows for each document.
nonisolated struct DocumentRow: Identifiable, Sendable {
    let id: UUID
    let title: String
    let createdAt: Date
    let pageCount: Int
}

/// Shown at the bottom of the list after a document is saved.
nonisolated struct SavedBanner: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
}

nonisolated enum DocumentListAlert: Identifiable, Equatable, Sendable {
    case scannerUnavailable
    case cameraDenied
    case saveFailed
    case generic(String)

    var id: String {
        switch self {
        case .scannerUnavailable: "scannerUnavailable"
        case .cameraDenied: "cameraDenied"
        case .saveFailed: "saveFailed"
        case .generic(let message): "generic-\(message)"
        }
    }
}

@Observable
@MainActor
final class DocumentListViewModel {
    private(set) var rows: [DocumentRow] = []
    private(set) var isSaving = false
    private(set) var savedBanner: SavedBanner?
    var alert: DocumentListAlert?
    var isScannerPresented = false

    private let repository: DocumentRepository
    private let namer: DocumentNamer
    private let pdfBuilder: PDFBuilding
    private let scannerAvailability: ScannerAvailability
    private var documents: [Document] = []
    /// Pages kept after a failed save, so the user can try again without scanning again.
    private var pendingPages: [UIImage] = []

    init(
        repository: DocumentRepository,
        namer: DocumentNamer = DocumentNamer(),
        pdfBuilder: PDFBuilding = ImagePDFBuilder(),
        scannerAvailability: ScannerAvailability = SystemScannerAvailability()
    ) {
        self.repository = repository
        self.namer = namer
        self.pdfBuilder = pdfBuilder
        self.scannerAvailability = scannerAvailability
    }

    // MARK: - Loading

    func load() {
        perform {
            documents = try repository.fetchAll()
        }
    }

    // MARK: - Scanning

    /// Called by the Scan button. Opens the scanner or explains why it can't.
    /// Returns sample pages on the simulator, which has no camera.
    func scanTapped() async {
        guard scannerAvailability.isScannerSupported else {
            #if DEBUG && targetEnvironment(simulator)
            await saveScannedPages(SampleScan.pages())
            #else
            alert = .scannerUnavailable
            #endif
            return
        }
        guard scannerAvailability.cameraAccess != .denied else {
            alert = .cameraDenied
            return
        }
        isScannerPresented = true
    }

    func scannerFinished(with pages: [UIImage]) async {
        isScannerPresented = false
        await saveScannedPages(pages)
    }

    func scannerCancelled() {
        isScannerPresented = false
    }

    func scannerFailed(_ error: Error) {
        isScannerPresented = false
        alert = .generic(error.localizedDescription)
    }

    func retrySave() async {
        await saveScannedPages(pendingPages)
    }

    func discardPendingPages() {
        pendingPages = []
    }

    func saveScannedPages(_ pages: [UIImage]) async {
        guard !pages.isEmpty, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            let builder = pdfBuilder
            let data = try await Task.detached(priority: .userInitiated) {
                try builder.makePDF(from: pages)
            }.value
            let document = try repository.create(NewDocument(pdfData: data, pageCount: pages.count))
            pendingPages = []
            documents = try repository.fetchAll()
            rebuildRows()
            let title = rows.first(where: { $0.id == document.id })?.title ?? document.title
            savedBanner = SavedBanner(id: document.id, title: title)
        } catch {
            pendingPages = pages
            alert = .saveFailed
        }
    }

    func dismissBanner() {
        savedBanner = nil
    }

    // MARK: - Editing

    func delete(at offsets: IndexSet) {
        let ids = offsets.map { rows[$0].id }
        delete(ids: ids)
    }

    func delete(ids: [UUID]) {
        perform {
            for document in documents where ids.contains(document.id) {
                try repository.delete(document)
            }
            documents = try repository.fetchAll()
        }
    }

    func rename(id: UUID, to title: String) {
        guard let document = documents.first(where: { $0.id == id }) else { return }
        perform {
            try repository.rename(document, to: title)
            documents = try repository.fetchAll()
        }
    }

    // MARK: - Private

    private func perform(_ work: () throws -> Void) {
        do {
            try work()
        } catch {
            alert = .generic(error.localizedDescription)
        }
        rebuildRows()
    }

    private func rebuildRows() {
        let titles = namer.displayTitles(for: documents)
        rows = documents
            .sorted { $0.createdAt > $1.createdAt }
            .map { document in
                DocumentRow(
                    id: document.id,
                    title: titles[document.id] ?? document.title,
                    createdAt: document.createdAt,
                    pageCount: document.pageCount
                )
            }
    }
}
