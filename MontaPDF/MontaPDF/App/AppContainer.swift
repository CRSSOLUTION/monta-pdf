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
    let sessionManager: SessionManager

    /// Throws only when no store can be opened at all; the app then shows `StorageErrorView`.
    init(inMemory: Bool = false) throws {
        modelContainer = try Self.makeModelContainer(inMemory: inMemory)
        documentRepository = SwiftDataDocumentRepository(container: modelContainer)
        let sessionStore: SessionStore = inMemory
            ? InMemorySessionStore()
            : KeychainSessionStore(service: "com.crlsribeiro.MontaPDF.session")
        sessionManager = SessionManager(
            store: sessionStore,
            credentialChecker: SystemAppleCredentialChecker(),
            cloudStatus: SystemCloudStatus()
        )
    }

    /// Opens the iCloud-synced store. If CloudKit can't be set up (for example,
    /// a schema problem), falls back to a store on this device so the app still works.
    private static func makeModelContainer(inMemory: Bool) throws -> ModelContainer {
        let schema = Schema([Document.self])
        if inMemory {
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            return try ModelContainer(for: schema, configurations: [configuration])
        }
        do {
            let synced = ModelConfiguration(schema: schema, cloudKitDatabase: .private(cloudKitContainerIdentifier))
            return try ModelContainer(for: schema, configurations: [synced])
        } catch {
            let local = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
            return try ModelContainer(for: schema, configurations: [local])
        }
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
        AccountViewModel(
            session: sessionManager,
            repository: documentRepository,
            tokenRevoker: WorkerAppleTokenRevoker()
        )
    }

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(session: sessionManager)
    }
}
