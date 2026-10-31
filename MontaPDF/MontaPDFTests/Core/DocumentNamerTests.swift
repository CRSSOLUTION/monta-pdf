//
//  DocumentNamerTests.swift
//  MontaPDFTests
//

import Foundation
import SwiftData
import Testing
@testable import MontaPDF

@MainActor
struct DocumentNamerTests {
    /// SwiftData needs an active container for the model type, even for unsaved objects.
    private let container: ModelContainer
    private let namer = DocumentNamer(automaticTitle: { "Document \($0)" })

    init() throws {
        container = try makeInMemoryContainer()
    }

    @Test func emptyListHasNoTitles() {
        #expect(namer.displayTitles(for: []).isEmpty)
    }

    @Test func numbersAutomaticDocumentsByCreationDateOldestFirst() {
        let second = Document(createdAt: date(minutesAfterReference: 2))
        let first = Document(createdAt: date(minutesAfterReference: 1))
        let third = Document(createdAt: date(minutesAfterReference: 3))

        let titles = namer.displayTitles(for: [third, first, second])

        #expect(titles[first.id] == "Document 1")
        #expect(titles[second.id] == "Document 2")
        #expect(titles[third.id] == "Document 3")
    }

    @Test func customTitleIsKeptAndLeavesTheNumbering() {
        let first = Document(createdAt: date(minutesAfterReference: 1))
        let renamed = Document(title: "Invoice", isCustomTitle: true, createdAt: date(minutesAfterReference: 2))
        let third = Document(createdAt: date(minutesAfterReference: 3))

        let titles = namer.displayTitles(for: [first, renamed, third])

        #expect(titles[first.id] == "Document 1")
        #expect(titles[renamed.id] == "Invoice")
        #expect(titles[third.id] == "Document 2")
    }

    @Test func removingADocumentRenumbersTheOthers() {
        let first = Document(createdAt: date(minutesAfterReference: 1))
        let second = Document(createdAt: date(minutesAfterReference: 2))
        let third = Document(createdAt: date(minutesAfterReference: 3))
        #expect(namer.displayTitles(for: [first, second, third])[third.id] == "Document 3")

        let titles = namer.displayTitles(for: [second, third])

        #expect(titles[second.id] == "Document 1")
        #expect(titles[third.id] == "Document 2")
    }

    @Test func sameCreationDateUsesAStableOrder() throws {
        let createdAt = date(minutesAfterReference: 1)
        let a = Document(id: try #require(UUID(uuidString: "00000000-0000-0000-0000-00000000000A")), createdAt: createdAt)
        let b = Document(id: try #require(UUID(uuidString: "00000000-0000-0000-0000-00000000000B")), createdAt: createdAt)

        let forward = namer.displayTitles(for: [a, b])
        let backward = namer.displayTitles(for: [b, a])

        #expect(forward == backward)
        #expect(forward[a.id] == "Document 1")
        #expect(forward[b.id] == "Document 2")
    }

    @Test func defaultAutomaticTitleIsLocalizedDocumentNumber() {
        let document = Document(createdAt: referenceDate)

        let titles = DocumentNamer().displayTitles(for: [document])

        #expect(titles[document.id] == String(localized: "Document \(1)"))
    }
}
