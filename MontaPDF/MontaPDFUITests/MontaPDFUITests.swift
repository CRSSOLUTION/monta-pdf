//
//  MontaPDFUITests.swift
//  MontaPDFUITests
//
//  Created by Carlos Ribeiro on 10/31/26.
//

import XCTest

/// End-to-end checks of the main flows. The app runs with an in-memory store
/// (`-ui-testing`) and, on the simulator, the Scan button creates two sample pages.
final class MontaPDFUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Helpers

    @MainActor
    private func launch(signedIn: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if signedIn {
            app.launchArguments.append("-ui-testing-signed-in")
        }
        app.launch()
        return app
    }

    @MainActor
    private func scanOneDocument(in app: XCUIApplication) {
        let scan = app.buttons["emptyStateScanButton"]
        XCTAssertTrue(scan.waitForExistence(timeout: 10), "Empty state with the Scan button")
        scan.tap()
        XCTAssertTrue(app.staticTexts["Document 1"].waitForExistence(timeout: 20), "Scanned document in the list")
    }

    @MainActor
    private func documentRow(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "documentRow").firstMatch
    }

    // MARK: - Tests

    @MainActor
    func testSignedOutShowsLogin() {
        let app = launch(signedIn: false)

        XCTAssertTrue(app.staticTexts["Scan, convert and keep your documents as PDFs."].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["emptyStateScanButton"].exists)
    }

    @MainActor
    func testScanCreatesADocumentWithAllPages() {
        let app = launch(signedIn: true)

        scanOneDocument(in: app)

        XCTAssertTrue(app.staticTexts["2 pages"].exists)
        XCTAssertTrue(app.buttons["scanButton"].exists, "Floating Scan button once the list has documents")
    }

    @MainActor
    func testOpeningADocumentShowsThePDF() {
        let app = launch(signedIn: true)
        scanOneDocument(in: app)

        documentRow(in: app).tap()

        XCTAssertTrue(app.staticTexts["pageIndicator"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Page 1 of 2"].exists)
    }

    @MainActor
    func testRenameKeepsTheNewName() {
        let app = launch(signedIn: true)
        scanOneDocument(in: app)

        documentRow(in: app).swipeLeft()
        app.buttons["Rename"].firstMatch.tap()
        let field = app.alerts.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 20))
        field.typeText("Receipt")
        app.alerts.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Receipt"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Document 1"].exists)
    }

    @MainActor
    func testDeleteAsksFirstAndEmptiesTheList() {
        let app = launch(signedIn: true)
        scanOneDocument(in: app)

        documentRow(in: app).swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        let confirm = app.alerts.buttons["Delete"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "Delete asks for confirmation")
        confirm.tap()

        XCTAssertTrue(app.buttons["emptyStateScanButton"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAccountScreenOffersDeleteAccount() {
        let app = launch(signedIn: true)

        let account = app.buttons["accountButton"]
        XCTAssertTrue(account.waitForExistence(timeout: 10))
        account.tap()

        XCTAssertTrue(app.buttons["deleteAccountButton"].waitForExistence(timeout: 5))
        app.buttons["accountDoneButton"].tap()
        XCTAssertTrue(app.buttons["emptyStateScanButton"].waitForExistence(timeout: 5))
    }
}
