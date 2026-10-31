//
//  UserSession.swift
//  MontaPDF
//

import Foundation

/// The signed-in Apple account. Apple sends name and email only on the first sign-in.
nonisolated struct UserSession: Codable, Equatable, Sendable {
    var userID: String
    var name: String?
    var email: String?
}
