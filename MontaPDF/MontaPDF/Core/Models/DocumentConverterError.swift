//
//  DocumentConverterError.swift
//  MontaPDF
//

import Foundation

nonisolated enum DocumentConverterError: Error {
    case loadFailed
    case emptyDocument
    case timedOut
}
