//
//  TestSupport.swift
//  MontaPDFTests
//

import Foundation
import SwiftData
@testable import MontaPDF

@MainActor
func makeInMemoryContainer() throws -> ModelContainer {
    let schema = Schema([Document.self])
    let configuration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none
    )
    return try ModelContainer(for: schema, configurations: [configuration])
}

/// A fixed reference date so tests don't depend on the clock.
let referenceDate = Date(timeIntervalSince1970: 1_800_000_000)

func date(minutesAfterReference minutes: Double) -> Date {
    referenceDate.addingTimeInterval(minutes * 60)
}

struct TestError: Error, LocalizedError {
    var errorDescription: String? { "Test failure" }
}

/// Repository that always fails, to test error handling in ViewModels.
@MainActor
final class FailingDocumentRepository: DocumentRepository {
    func fetchAll() throws -> [Document] { throw TestError() }

    func create(pageCount: Int, fileName: String, originalFileName: String?, createdAt: Date) throws -> Document {
        throw TestError()
    }

    func rename(_ document: Document, to title: String) throws { throw TestError() }

    func delete(_ document: Document) throws { throw TestError() }
}
