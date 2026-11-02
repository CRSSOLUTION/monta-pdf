//
//  AppleSignInMapper.swift
//  MontaPDF
//

import AuthenticationServices
import Foundation

/// The only place that reads AuthenticationServices types. Views call it with the
/// result of `SignInWithAppleButton` and hand our own `AppleSignInResult` to ViewModels.
nonisolated enum AppleSignInMapper {
    static func map(_ result: Result<ASAuthorization, Error>) -> AppleSignInResult {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                return .failed
            }
            return .signedIn(AppleSignInCredential(
                userID: credential.user,
                fullName: credential.fullName.flatMap {
                    PersonNameComponentsFormatter.localizedString(from: $0, style: .default)
                },
                email: credential.email,
                authorizationCode: credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
            ))
        case .failure(let error):
            return map(error)
        }
    }

    static func map(_ error: Error) -> AppleSignInResult {
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            return .cancelled
        }
        return .failed
    }
}
