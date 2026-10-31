//
//  ImportKind.swift
//  MontaPDF
//

import Foundation
import UniformTypeIdentifiers

/// What the app does with an imported file, decided by its extension.
nonisolated enum ImportKind: Equatable, Sendable {
    case image
    case pdf
    case word
    case unsupported

    static let wordExtensions: Set<String> = ["docx", "doc"]

    /// Types offered in the Files picker.
    static var supportedTypes: [UTType] {
        var types: [UTType] = [.image, .pdf]
        types += wordExtensions.compactMap { UTType(filenameExtension: $0) }
        return types
    }

    static func classify(fileName: String) -> ImportKind {
        let ext = (fileName as NSString).pathExtension.lowercased()
        if wordExtensions.contains(ext) { return .word }
        guard let type = UTType(filenameExtension: ext) else { return .unsupported }
        if type.conforms(to: .pdf) { return .pdf }
        if type.conforms(to: .image) { return .image }
        return .unsupported
    }
}

/// A file picked by the user, already read into memory.
nonisolated struct ImportedFile: Sendable {
    let name: String
    let data: Data

    var kind: ImportKind { ImportKind.classify(fileName: name) }

    /// Reads files from the Files picker (they are security-scoped).
    static func read(_ urls: [URL]) throws -> [ImportedFile] {
        try urls.map { url in
            let didAccess = url.startAccessingSecurityScopedResource()
            defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
            return ImportedFile(name: url.lastPathComponent, data: try Data(contentsOf: url))
        }
    }
}
