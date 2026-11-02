//
//  AppStartupTests.swift
//  MontaPDFTests
//

import Foundation
import Testing
@testable import MontaPDF

@MainActor
struct AppStartupTests {
    @Test func successfulStartupHasAContainer() {
        let startup = AppStartup { try AppContainer(inMemory: true) }

        #expect(startup.container != nil)
        #expect(startup.failed == false)
    }

    @Test func failedStartupShowsTheErrorInsteadOfCrashing() {
        let startup = AppStartup { throw TestError() }

        #expect(startup.container == nil)
        #expect(startup.failed)
    }

    @Test func tryAgainRecoversWhenStorageOpens() {
        var attempts = 0
        let startup = AppStartup {
            attempts += 1
            if attempts == 1 { throw TestError() }
            return try AppContainer(inMemory: true)
        }
        #expect(startup.failed)

        startup.start()

        #expect(startup.failed == false)
        #expect(startup.container != nil)
        #expect(attempts == 2)
    }
}
