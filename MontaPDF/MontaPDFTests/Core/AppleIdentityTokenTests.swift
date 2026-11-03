//
//  AppleIdentityTokenTests.swift
//  MontaPDFTests
//

import Foundation
import Testing
@testable import MontaPDF

struct AppleIdentityTokenTests {
    @Test func readsTheEmailFromThePayload() {
        let token = makeToken(["sub": "abc", "email": "ana@example.com"])
        #expect(AppleIdentityToken.email(from: token) == "ana@example.com")
    }

    @Test func readsAPrivateRelayEmail() {
        let token = makeToken(["email": "x7k2@privaterelay.appleid.com", "is_private_email": "true"])
        #expect(AppleIdentityToken.email(from: token) == "x7k2@privaterelay.appleid.com")
    }

    @Test func handlesPayloadsThatNeedBase64Padding() {
        // Different lengths exercise every padding case of base64url.
        for email in ["a@b.co", "ab@b.co", "abc@b.co", "abcd@b.co"] {
            #expect(AppleIdentityToken.email(from: makeToken(["email": email])) == email)
        }
    }

    @Test func returnsNilWithoutAnEmailClaim() {
        #expect(AppleIdentityToken.email(from: makeToken(["sub": "abc"])) == nil)
    }

    @Test func returnsNilForAnEmptyEmail() {
        #expect(AppleIdentityToken.email(from: makeToken(["email": "  "])) == nil)
    }

    @Test(arguments: [nil, "", "not-a-jwt", "a.b", "a.%%%.c", "a.b.c.d"])
    func returnsNilForMalformedTokens(token: String?) {
        #expect(AppleIdentityToken.email(from: token) == nil)
    }

    private func makeToken(_ claims: [String: String]) -> String {
        let header = base64URL(Data(#"{"alg":"RS256","kid":"test"}"#.utf8))
        let payload = base64URL(try! JSONSerialization.data(withJSONObject: claims))
        return "\(header).\(payload).signature"
    }

    private func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
