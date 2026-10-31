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
    }

    lazy var documentRepository: DocumentRepository = SwiftDataDocumentRepository(
        container: modelContainer
    )

    func makeDocumentListViewModel() -> DocumentListViewModel {
        DocumentListViewModel(repository: documentRepository)
    }
}
