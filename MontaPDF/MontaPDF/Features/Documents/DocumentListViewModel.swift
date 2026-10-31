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
    /// `false` for imported Word files kept without a PDF.
    var hasPDF = true
    /// Set for imported files (e.g. "Contract.docx").
    var originalFileName: String?
    var hasOriginal = false
}

nonisolated enum ShareFormat: Sendable {
    case pdf
    case original
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

    // Rename, delete and share
    var isRenaming = false
    var renameDraft = ""
    private(set) var renameTargetID: UUID?
    var isConfirmingDelete = false
    private(set) var deleteTarget: DocumentRow?
    var shareItem: ShareItem?
    /// Word imports ask whether to share the PDF or the original file.
    var isChoosingShareFormat = false
    private(set) var shareChoiceID: UUID?

    let importer: ImportViewModel

    private let repository: DocumentRepository
    private let namer: DocumentNamer
    private let pdfBuilder: PDFBuilding
    private let scanEnhancer: ScanEnhancing
    private let scannerAvailability: ScannerAvailability
    private let exporter: DocumentExporting
    private var documents: [Document] = []
    private var thumbnails: [UUID: UIImage] = [:]
    /// Pages kept after a failed save, so the user can try again without scanning again.
    private var pendingPages: [UIImage] = []

    init(
        repository: DocumentRepository,
        namer: DocumentNamer? = nil,
        pdfBuilder: PDFBuilding? = nil,
        scannerAvailability: ScannerAvailability? = nil,
        exporter: DocumentExporting? = nil,
        converter: DocumentConverter? = nil,
        scanEnhancer: ScanEnhancing? = nil
    ) {
        // Defaults are created here (not as default arguments) so they run on the main actor.
        let pdfBuilder = pdfBuilder ?? ImagePDFBuilder()
        self.repository = repository
        self.namer = namer ?? DocumentNamer()
        self.pdfBuilder = pdfBuilder
        self.scanEnhancer = scanEnhancer ?? DocumentScanEnhancer()
        self.scannerAvailability = scannerAvailability ?? SystemScannerAvailability()
        self.exporter = exporter ?? TemporaryFileExporter()
        self.importer = ImportViewModel(
            repository: repository,
            pdfBuilder: pdfBuilder,
            converter: converter ?? WebKitDocumentConverter()
        )
        importer.onSaved = { [weak self] id in
            self?.documentAdded(id: id)
        }
    }

    func makeViewerViewModel(for id: UUID) -> DocumentViewerViewModel {
        DocumentViewerViewModel(documentID: id, repository: repository, namer: namer, exporter: exporter)
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
            let enhancer = scanEnhancer
            let data = try await Task.detached(priority: .userInitiated) {
                // Clean up the pages (shadows, folds, white paper) before building the PDF.
                try builder.makePDF(from: pages.map { enhancer.enhance($0) })
            }.value
            let document = try repository.create(NewDocument(pdfData: data, pageCount: pages.count))
            pendingPages = []
            documentAdded(id: document.id)
        } catch {
            pendingPages = pages
            alert = .saveFailed
        }
    }

    /// Reloads the list and shows the "saved" banner for a new document.
    func documentAdded(id: UUID) {
        load()
        if let row = rows.first(where: { $0.id == id }) {
            savedBanner = SavedBanner(id: id, title: row.title)
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
            try repository.rename(document, to: DocumentTitleRules.sanitize(title))
            documents = try repository.fetchAll()
        }
    }

    func startRename(id: UUID) {
        guard let row = rows.first(where: { $0.id == id }) else { return }
        renameTargetID = id
        renameDraft = row.title
        isRenaming = true
    }

    func confirmRename() {
        guard let id = renameTargetID else { return }
        let newTitle = DocumentTitleRules.sanitize(renameDraft)
        guard !newTitle.isEmpty else { return }
        rename(id: id, to: newTitle)
        renameTargetID = nil
        if savedBanner?.id == id {
            savedBanner = nil
        }
    }

    func startDelete(id: UUID) {
        guard let row = rows.first(where: { $0.id == id }) else { return }
        deleteTarget = row
        isConfirmingDelete = true
    }

    func confirmDelete() {
        guard let target = deleteTarget else { return }
        delete(ids: [target.id])
        thumbnails[target.id] = nil
        deleteTarget = nil
    }

    /// Shares the PDF. Word imports first ask: PDF or original?
    func share(id: UUID) {
        guard let document = documents.first(where: { $0.id == id }) else { return }
        switch (document.pdfData != nil, document.originalData != nil) {
        case (true, true):
            shareChoiceID = id
            isChoosingShareFormat = true
        case (true, false):
            share(id: id, format: .pdf)
        case (false, true):
            share(id: id, format: .original)
        case (false, false):
            break
        }
    }

    func share(id: UUID, format: ShareFormat) {
        guard
            let document = documents.first(where: { $0.id == id }),
            let row = rows.first(where: { $0.id == id })
        else { return }
        perform {
            switch format {
            case .pdf:
                guard let data = document.pdfData else { return }
                let url = try exporter.export(data, fileName: DocumentTitleRules.fileName(for: row.title))
                shareItem = ShareItem(url: url)
            case .original:
                guard let data = document.originalData else { return }
                let ext = ((document.originalFileName ?? "") as NSString).pathExtension
                let url = try exporter.export(
                    data,
                    fileName: DocumentTitleRules.fileName(for: row.title, fileExtension: ext.isEmpty ? "docx" : ext)
                )
                shareItem = ShareItem(url: url)
            }
        }
    }

    func shareChosen(_ format: ShareFormat) {
        guard let id = shareChoiceID else { return }
        shareChoiceID = nil
        share(id: id, format: format)
    }

    /// First page of the PDF, cached after the first render.
    func thumbnail(for id: UUID) async -> UIImage? {
        if let cached = thumbnails[id] { return cached }
        guard let data = documents.first(where: { $0.id == id })?.pdfData else { return nil }
        let image = await ThumbnailRenderer.render(data, size: CGSize(width: 120, height: 160))
        thumbnails[id] = image
        return image
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
                    pageCount: document.pageCount,
                    hasPDF: document.pdfData != nil,
                    originalFileName: document.originalFileName,
                    hasOriginal: document.originalData != nil
                )
            }
    }
}
