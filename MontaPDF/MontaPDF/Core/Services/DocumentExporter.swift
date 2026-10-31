//
//  DocumentExporter.swift
//  MontaPDF
//

import Foundation

/// Writes a document to a temporary file so it can be shared as a real file (not a link).
protocol DocumentExporting {
    func export(_ data: Data, fileName: String) throws -> URL
}

struct TemporaryFileExporter: DocumentExporting {
    func export(_ data: Data, fileName: String) throws -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("Share", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)
        return url
    }
}
