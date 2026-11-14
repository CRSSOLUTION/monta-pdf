//
//  AppSchema.swift
//  MontaPDF
//

import SwiftData

/// Every SwiftData model of the app, so the app and the tests open the same schema.
enum AppSchema {
    static let models: [any PersistentModel.Type] = [Document.self, Dossier.self, DossierItem.self]

    static var schema: Schema { Schema(models) }
}
