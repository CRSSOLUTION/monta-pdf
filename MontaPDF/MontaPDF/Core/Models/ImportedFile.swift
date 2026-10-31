//
//  ImportedFile.swift
//  MontaPDF
//

import Foundation

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
