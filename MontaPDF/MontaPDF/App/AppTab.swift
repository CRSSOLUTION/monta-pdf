//
//  AppTab.swift
//  MontaPDF
//

import Foundation

/// The two tabs. Dossiers comes first: it is what makes the app different.
nonisolated enum AppTab: Hashable, Sendable {
    case dossiers
    case documents
}
