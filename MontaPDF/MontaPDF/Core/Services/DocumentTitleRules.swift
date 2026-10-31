//
//  DocumentTitleRules.swift
//  MontaPDF
//

import Foundation

/// Rules for document names: up to 80 characters, no "/" or ":".
/// The ".pdf" extension is added only when the file is exported.
nonisolated enum DocumentTitleRules {
    static let maxLength = 80

    /// Removes forbidden characters, trims spaces and limits the length.
    static func sanitize(_ title: String) -> String {
        let cleaned = title
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: ":", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return String(cleaned.prefix(maxLength))
    }

    /// Name of the exported file, e.g. "Contract" → "Contract.pdf".
    static func fileName(for title: String, fileExtension: String = "pdf") -> String {
        let base = sanitize(title)
        return "\(base.isEmpty ? "Document" : base).\(fileExtension)"
    }

    /// Title for an imported file, e.g. "Contract.docx" → "Contract".
    static func title(fromFileName fileName: String) -> String {
        sanitize((fileName as NSString).deletingPathExtension)
    }
}
