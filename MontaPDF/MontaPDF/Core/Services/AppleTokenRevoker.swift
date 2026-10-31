//
//  AppleTokenRevoker.swift
//  MontaPDF
//

import Foundation

nonisolated enum AppleTokenRevokerError: Error {
    case missingAuthorizationCode
    case serverRejected(statusCode: Int)
}

/// Revokes the user's Sign in with Apple token when the account is deleted
/// (App Store guideline 5.1.1(v)). The signing key lives on the server, never in the app.
protocol AppleTokenRevoking {
    func revoke(authorizationCode: String) async throws
}

/// Calls the Cloudflare Worker in `server/apple-revoke`.
struct WorkerAppleTokenRevoker: AppleTokenRevoking {
    var endpoint: URL = AppLinks.appleTokenRevocation
    var session: URLSession = .shared

    func revoke(authorizationCode: String) async throws {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20
        request.httpBody = try JSONEncoder().encode(["authorizationCode": authorizationCode])

        let (_, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw AppleTokenRevokerError.serverRejected(statusCode: status)
        }
    }
}
