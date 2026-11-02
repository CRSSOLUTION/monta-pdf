//
//  LaunchOptions.swift
//  MontaPDF
//

import Foundation

/// How the app was launched: normally, by unit tests, or by UI tests.
struct LaunchOptions {
    /// Passed by UI tests: in-memory store, nothing synced or kept.
    static let uiTestingArgument = "-ui-testing"
    /// Passed by UI tests that start signed in (Sign in with Apple can't be automated).
    static let signedInArgument = "-ui-testing-signed-in"

    let isRunningUnitTests: Bool
    let isUITesting: Bool
    let startsSignedIn: Bool

    init(processInfo: ProcessInfo = .processInfo) {
        isRunningUnitTests = processInfo.environment["XCTestConfigurationFilePath"] != nil
        isUITesting = processInfo.arguments.contains(Self.uiTestingArgument)
        startsSignedIn = isUITesting && processInfo.arguments.contains(Self.signedInArgument)
    }

    /// Tests get an in-memory store without CloudKit.
    var usesInMemoryStore: Bool { isRunningUnitTests || isUITesting }
}
