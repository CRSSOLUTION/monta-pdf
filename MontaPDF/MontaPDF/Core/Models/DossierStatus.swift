//
//  DossierStatus.swift
//  MontaPDF
//

import Foundation

/// The only three statuses a dossier can have. Always computed, never stored.
nonisolated enum DossierStatus: Equatable, Sendable {
    /// A required item is still missing, or nothing was added yet.
    case inProgress
    /// Every required item is added or marked as not applicable.
    case readyToSend
    /// The user confirmed it was sent.
    case sent(Date)

    init(progress: DossierProgress, sentAt: Date?) {
        if let sentAt {
            self = .sent(sentAt)
        } else {
            self = progress.isComplete ? .readyToSend : .inProgress
        }
    }
}
