//
//  ShareItem.swift
//  MontaPDF
//

import Foundation

/// Identifiable wrapper so a file URL can drive `.sheet(item:)`.
nonisolated struct ShareItem: Identifiable, Equatable, Sendable {
    let id = UUID()
    let url: URL
}
