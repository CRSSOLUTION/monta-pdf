//
//  WorkerAppleTokenRevoker.swift
//  MontaPDF
//

import Foundation

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
