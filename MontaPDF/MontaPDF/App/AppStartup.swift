//
//  AppStartup.swift
//  MontaPDF
//

import Foundation
import Observation

/// Builds the AppContainer at launch. If the storage can't be opened, keeps the
/// error so the app shows a friendly screen with "Try Again" instead of crashing.
@Observable
@MainActor
final class AppStartup {
    private(set) var container: AppContainer?
    private(set) var failed = false

    private let makeContainer: () throws -> AppContainer

    init(makeContainer: @escaping () throws -> AppContainer) {
        self.makeContainer = makeContainer
        start()
    }

    func start() {
        do {
            container = try makeContainer()
            failed = false
        } catch {
            container = nil
            failed = true
        }
    }
}
