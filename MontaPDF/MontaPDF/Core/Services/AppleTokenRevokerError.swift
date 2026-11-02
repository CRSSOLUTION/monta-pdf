//
//  AppleTokenRevokerError.swift
//  MontaPDF
//

import Foundation

nonisolated enum AppleTokenRevokerError: Error {
    case missingAuthorizationCode
    case serverRejected(statusCode: Int)
}
