//
//  ImportAlert.swift
//  MontaPDF
//

import Foundation

nonisolated enum ImportAlert: Identifiable, Hashable, Sendable {
    case unsupported
    /// Word conversion failed; the user can still keep the original.
    case conversionFailed
    case failed
    /// Several files were picked and this many couldn't be imported.
    case someFilesSkipped(Int)

    var id: Self { self }
}
