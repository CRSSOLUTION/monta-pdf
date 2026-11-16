//
//  Document+Dossiers.swift
//  MontaPDF
//

import Foundation

extension Document {
    /// Names of the dossiers that use this document, without repeats, in a stable order.
    var dossierNames: [String] {
        var seen = Set<String>()
        return (dossierItems ?? [])
            .compactMap { $0.dossier?.name }
            .sorted()
            .filter { seen.insert($0).inserted }
    }
}
