//
//  TestSupport.swift
//  MontaPDFTests
//

import Foundation
import SwiftData
import UIKit
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
let referenceDate = Date(timeIntervalSince1970: 1_700_000_000) // Nov 2023, always in the past

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

    func document(id: UUID) throws -> Document? { throw TestError() }

    func create(_ newDocument: NewDocument) throws -> Document { throw TestError() }

    func rename(_ document: Document, to title: String) throws { throw TestError() }

    func delete(_ document: Document) throws { throw TestError() }

    func deleteAll() throws { throw TestError() }
}

/// PDF builder that returns fixed bytes. It fails the first `failures` calls.
final class FakePDFBuilder: PDFBuilding, @unchecked Sendable {
    private let lock = NSLock()
    private var failuresLeft: Int

    init(failures: Int = 0) {
        failuresLeft = failures
    }

    func makePDF(from images: [PageImage]) throws -> Data {
        lock.lock()
        defer { lock.unlock() }
        if failuresLeft > 0 {
            failuresLeft -= 1
            throw TestError()
        }
        return blankPDF(pages: images.count)
    }
}

struct FakeScannerAvailability: ScannerAvailability {
    var isScannerSupported = true
    var cameraAccess: CameraAccess = .allowed
}

func makeTestImage(width: CGFloat = 20, height: CGFloat = 30) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { context in
        UIColor.gray.setFill()
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    }
}

/// Exporter that records what it was asked to export, without touching the disk.
final class FakeExporter: DocumentExporting {
    private(set) var exportedFileNames: [String] = []

    func export(_ data: Data, fileName: String) throws -> URL {
        exportedFileNames.append(fileName)
        return URL(fileURLWithPath: "/tmp/\(fileName)")
    }
}

/// Session store kept in memory.
final class InMemorySessionStore: SessionStore {
    private var currentUserID: String?
    private var profiles: [String: UserSession] = [:]

    func loadSession() -> UserSession? {
        currentUserID.flatMap { profiles[$0] }
    }

    func save(_ session: UserSession) {
        profiles[session.userID] = session
        currentUserID = session.userID
    }

    func signOut() {
        currentUserID = nil
    }

    func deleteAll() {
        if let currentUserID { profiles[currentUserID] = nil }
        currentUserID = nil
    }

    func rememberedProfile(for userID: String) -> UserSession? {
        profiles[userID]
    }
}

struct FakeCredentialChecker: AppleCredentialChecking {
    var authorized = true

    func isAuthorized(userID: String) async -> Bool { authorized }
}

struct FakeCloudStatus: CloudStatusProviding {
    var isICloudAvailable = true
}

/// Word converter that returns a fixed PDF, or fails.
final class FakeDocumentConverter: DocumentConverter {
    var shouldFail = false
    private(set) var convertedFileNames: [String] = []

    func convertToPDF(data: Data, fileName: String) async throws -> ConvertedPDF {
        convertedFileNames.append(fileName)
        if shouldFail { throw TestError() }
        return ConvertedPDF(data: Data("converted".utf8), pageCount: 4)
    }
}

/// A real one-page PDF, for code that opens the PDF with PDFKit.
func makeTestPDF(pages: Int = 1) throws -> Data {
    try ImagePDFBuilder().makePDF(from: (0..<pages).map { _ in makeTestPage() })
}

/// Records how many pages went through the enhancer.
final class FakeScanEnhancer: ScanEnhancing, @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var enhancedCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }

    func enhance(_ image: PageImage) -> PageImage {
        lock.lock()
        count += 1
        lock.unlock()
        return image
    }
}

/// Records revocation calls, or fails when asked to.
final class FakeTokenRevoker: AppleTokenRevoking {
    var shouldFail = false
    private(set) var revokedCodes: [String] = []

    func revoke(authorizationCode: String) async throws {
        if shouldFail { throw TestError() }
        revokedCodes.append(authorizationCode)
    }
}

@MainActor
func makeSessionManager(
    store: SessionStore = InMemorySessionStore(),
    authorized: Bool = true,
    iCloud: Bool = true
) -> SessionManager {
    SessionManager(
        store: store,
        credentialChecker: FakeCredentialChecker(authorized: authorized),
        cloudStatus: FakeCloudStatus(isICloudAvailable: iCloud)
    )
}

func appleCredential(
    userID: String = "abc",
    name: String? = nil,
    email: String? = nil,
    code: String? = "code-123"
) -> AppleSignInCredential {
    AppleSignInCredential(userID: userID, fullName: name, email: email, authorizationCode: code)
}

/// A small valid PNG page, as the scanner and the importer hand pages over.
func makeTestPage(width: CGFloat = 20, height: CGFloat = 30) -> PageImage {
    PageImage(data: makeTestImage(width: width, height: height).pngData() ?? Data())
}

/// A real PDF with blank A4 pages, so code that counts pages with PDFKit works.
func blankPDF(pages: Int) -> Data {
    let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
    return renderer.pdfData { context in
        for _ in 0..<pages { context.beginPage() }
    }
}
