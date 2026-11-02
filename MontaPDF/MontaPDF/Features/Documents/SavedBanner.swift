//
//  SavedBanner.swift
//  MontaPDF
//

import Foundation

/// Shown at the bottom of the list after a document is saved.
nonisolated struct SavedBanner: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
}
