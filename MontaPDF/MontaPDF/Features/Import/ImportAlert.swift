//
//  ImportAlert.swift
//  MontaPDF
//

import Foundation

nonisolated enum ImportAlert: Identifiable, Equatable, Sendable {
    case unsupported
    /// Word conversion failed; the user can still keep the original.
    case conversionFailed
    case failed

    var id: Self { self }
}
