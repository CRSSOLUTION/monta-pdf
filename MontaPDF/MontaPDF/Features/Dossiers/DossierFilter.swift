//
//  DossierFilter.swift
//  MontaPDF
//

import Foundation

/// The two lists of the Dossiers screen. "In progress" also holds the ones ready to send.
nonisolated enum DossierFilter: Hashable, CaseIterable, Sendable {
    case inProgress
    case sent
}
