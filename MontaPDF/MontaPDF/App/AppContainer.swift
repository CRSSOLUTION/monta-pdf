//
//  AppContainer.swift
//  MontaPDF
//

import Foundation
import SwiftData

/// Builds the app dependencies (SwiftData container, repositories, ViewModels).
@MainActor
final class AppContainer {
    static let cloudKitContainerIdentifier = "iCloud.com.crlsribeiro.MontaPDF"

    let modelContainer: ModelContainer
    let documentRepository: DocumentRepository
    let sessionViewModel: SessionViewModel

    init(inMemory: Bool = false) {
        let schema = Schema([Document.self])
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
        } else {
            configuration = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .private(Self.cloudKitContainerIdentifier)
            )
        }

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        documentRepository = SwiftDataDocumentRepository(container: modelContainer)
        let defaults = inMemory ? (UserDefaults(suiteName: "MontaPDF.InMemory") ?? .standard) : .standard
        sessionViewModel = SessionViewModel(store: UserDefaultsSessionStore(defaults: defaults))
    }

    /// The three ViewModels of the My Documents screen, already wired together:
    /// after a scan or an import is saved, the list reloads and shows the "saved" banner.
    func makeDocumentsFeature() -> DocumentsFeature {
        let pdfBuilder = ImagePDFBuilder()
        let list = DocumentListViewModel(
            repository: documentRepository,
            namer: DocumentNamer(),
            exporter: TemporaryFileExporter()
        )
        let scanner = ScannerViewModel(
            repository: documentRepository,
            pdfBuilder: pdfBuilder,
            scanEnhancer: DocumentScanEnhancer(),
            availability: SystemScannerAvailability()
        )
        let importer = ImportViewModel(
            repository: documentRepository,
            pdfBuilder: pdfBuilder,
            converter: WebKitDocumentConverter()
        )
        scanner.onSaved = { [weak list] id in list?.documentAdded(id: id) }
        importer.onSaved = { [weak list] id in list?.documentAdded(id: id) }
        return DocumentsFeature(
            list: list,
            scanner: scanner,
            importer: importer,
            makeViewer: { [unowned self] id in self.makeDocumentViewerViewModel(for: id) }
        )
    }

    func makeDocumentViewerViewModel(for id: UUID) -> DocumentViewerViewModel {
        DocumentViewerViewModel(
            documentID: id,
            repository: documentRepository,
            namer: DocumentNamer(),
            exporter: TemporaryFileExporter()
        )
    }

    func makeAccountViewModel() -> AccountViewModel {
        AccountViewModel(session: sessionViewModel, repository: documentRepository)
    }
}

/// ViewModels used by the My Documents screen.
struct DocumentsFeature {
    let list: DocumentListViewModel
    let scanner: ScannerViewModel
    let importer: ImportViewModel
    /// Builds the ViewModel of the PDF viewer for a document.
    let makeViewer: (UUID) -> DocumentViewerViewModel
}
