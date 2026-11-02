//
//  AppleSignInMapperTests.swift
//  MontaPDFTests
//

import AuthenticationServices
import Testing
@testable import MontaPDF

struct AppleSignInMapperTests {
    @Test func cancelledByTheUserIsCancelled() {
        #expect(AppleSignInMapper.map(ASAuthorizationError(.canceled)) == .cancelled)
    }

    @Test(arguments: [ASAuthorizationError.Code.failed, .invalidResponse, .unknown, .notHandled])
    func otherAppleErrorsFail(code: ASAuthorizationError.Code) {
        #expect(AppleSignInMapper.map(ASAuthorizationError(code)) == .failed)
    }

    @Test func unrelatedErrorsFail() {
        #expect(AppleSignInMapper.map(TestError()) == .failed)
    }
}
