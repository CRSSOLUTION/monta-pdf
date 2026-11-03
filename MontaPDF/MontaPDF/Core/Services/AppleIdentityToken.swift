//
//  AppleIdentityToken.swift
//  MontaPDF
//

import Foundation

/// Reads the email from a Sign in with Apple identity token (a JWT).
/// Apple puts the email in `credential.email` only on the first sign-in,
/// but the identity token carries it on every sign-in.
/// We only read the payload for display; the token is not used to authorize anything.
nonisolated enum AppleIdentityToken {
    static func email(from token: String?) -> String? {
        guard let token else { return nil }
        let parts = token.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3, let payload = decodeBase64URL(String(parts[1])) else { return nil }
        guard let claims = try? JSONSerialization.jsonObject(with: payload) as? [String: Any],
              let email = claims["email"] as? String else { return nil }
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func decodeBase64URL(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        return Data(base64Encoded: base64)
    }
}
