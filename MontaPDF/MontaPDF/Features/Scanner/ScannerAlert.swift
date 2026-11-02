//
//  ScannerAlert.swift
//  MontaPDF
//

import Foundation

nonisolated enum ScannerAlert: Identifiable, Equatable, Sendable {
    case scannerUnavailable
    case cameraDenied
    /// Building or saving the PDF failed; the pages are kept for a retry.
    case saveFailed
    case failed(String)

    var id: String {
        switch self {
        case .scannerUnavailable: "scannerUnavailable"
        case .cameraDenied: "cameraDenied"
        case .saveFailed: "saveFailed"
        case .failed(let message): "failed-\(message)"
        }
    }
}
