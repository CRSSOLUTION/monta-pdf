//
//  AppLinks.swift
//  MontaPDF
//

import Foundation

nonisolated enum AppLinks {
    static let privacyPolicy = URL(string: "https://crssolution.github.io/monta-pdf/privacy.html")!
    static let termsOfUse = URL(string: "https://crssolution.github.io/monta-pdf/terms.html")!
    static let supportEmail = "crls_ribeiro@icloud.com"
    static let support = URL(string: "mailto:\(supportEmail)")!
    /// Cloudflare Worker that revokes Sign in with Apple tokens (server/apple-revoke).
    static let appleTokenRevocation = URL(string: "https://montapdf-apple-revoke.crls-ribeiro-dev.workers.dev")!
}
