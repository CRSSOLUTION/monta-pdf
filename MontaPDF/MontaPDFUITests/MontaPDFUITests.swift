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

    /// The app opens on the Packets tab; documents live on the second tab.
    @MainActor
    private func openDocumentsTab(in app: XCUIApplication) {
        let tab = app.tabBars.buttons["Documents"]
        XCTAssertTrue(tab.waitForExistence(timeout: 30), "Documents tab")
        tab.tap()
    }

    @MainActor
    private func scanOneDocument(in app: XCUIApplication) {
        openDocumentsTab(in: app)
        let scan = app.buttons["emptyStateScanButton"]
        XCTAssertTrue(scan.waitForExistence(timeout: 30), "Empty state with the Scan button")
        scan.tap()
        XCTAssertTrue(app.staticTexts["Document 1"].waitForExistence(timeout: 45), "Scanned document in the list")
    }

    @MainActor
    private func element(in app: XCUIApplication, labelContaining text: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    @MainActor
    private func documentRow(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "documentRow").firstMatch
    }

    // MARK: - Tests

    @MainActor
    func testSignedOutShowsLogin() {
        let app = launch(signedIn: false)

        XCTAssertTrue(app.staticTexts["Scan, convert and keep your documents as PDFs."].waitForExistence(timeout: 30))
        XCTAssertFalse(app.buttons["emptyStateScanButton"].exists)
        XCTAssertFalse(app.buttons["newDossierButton"].exists)
    }

    @MainActor
    func testOpensOnThePacketsTabExplainingTheIdea() {
        let app = launch(signedIn: true)

        XCTAssertTrue(app.staticTexts["Gather everything they asked for in one PDF"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.buttons["newDossierButton"].exists)
    }

    @MainActor
    private func createRentalPacket(in app: XCUIApplication, named name: String) {
        let newPacket = app.buttons["newDossierButton"]
        XCTAssertTrue(newPacket.waitForExistence(timeout: 30))
        newPacket.tap()
        let rental = app.descendants(matching: .any).matching(identifier: "templateRow_rental").firstMatch
        XCTAssertTrue(rental.waitForExistence(timeout: 15), "Template list")
        rental.tap()
        let field = app.textFields["dossierNameField"]
        XCTAssertTrue(field.waitForExistence(timeout: 15))
        field.tap()
        field.typeText(name)
        app.buttons["createDossierButton"].tap()
        XCTAssertTrue(app.staticTexts["dossierProgress"].waitForExistence(timeout: 15), "Checklist of the new packet")
    }

    @MainActor
    func testScanningFillsAnItemAndMarkingTheRestAsNotApplicableCompletesThePacket() {
        let app = launch(signedIn: true)
        createRentalPacket(in: app, named: "Flower Street")

        app.buttons.matching(identifier: "addDocumentButton").firstMatch.tap()
        let scan = app.buttons["Scan document"]
        XCTAssertTrue(scan.waitForExistence(timeout: 15), "Options to fill the item")
        scan.tap()
        XCTAssertTrue(
            app.staticTexts["1 of 4 required"].waitForExistence(timeout: 45),
            "The sample scan fills the first item"
        )

        for _ in 0..<3 {
            app.buttons.matching(identifier: "addDocumentButton").firstMatch.tap()
            let notApplicable = app.buttons["Doesn't apply"]
            XCTAssertTrue(notApplicable.waitForExistence(timeout: 15))
            notApplicable.tap()
        }

        XCTAssertTrue(app.staticTexts["1 of 1 required"].waitForExistence(timeout: 15))

        // Cover + summary + the two sample pages.
        app.buttons["assemblePDFButton"].tap()
        let pageCount = app.staticTexts["assembledPageCount"]
        XCTAssertTrue(pageCount.waitForExistence(timeout: 30), "Assembled PDF")
        XCTAssertEqual(pageCount.label, "4 pages")
        XCTAssertTrue(app.buttons["sharePDFButton"].isEnabled)

        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let row = app.descendants(matching: .any).matching(identifier: "dossierRow").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 15))
        XCTAssertTrue(row.label.contains("Ready to send"))
    }

    @MainActor
    func testCreatingAPacketOpensItsChecklist() {
        let app = launch(signedIn: true)
        let newPacket = app.buttons["newDossierButton"]
        XCTAssertTrue(newPacket.waitForExistence(timeout: 30))
        newPacket.tap()

        let rental = app.descendants(matching: .any).matching(identifier: "templateRow_rental").firstMatch
        XCTAssertTrue(rental.waitForExistence(timeout: 15), "Template list")
        rental.tap()
        let name = app.textFields["dossierNameField"]
        XCTAssertTrue(name.waitForExistence(timeout: 15))
        name.tap()
        name.typeText("Flower Street")
        app.buttons["createDossierButton"].tap()

        let progress = app.staticTexts["dossierProgress"]
        XCTAssertTrue(progress.waitForExistence(timeout: 15), "Checklist of the new packet")
        XCTAssertEqual(progress.label, "0 of 4 required")
        XCTAssertTrue(element(in: app, labelContaining: "Identity document").exists)

        app.navigationBars.buttons.element(boundBy: 0).tap()
        let row = app.descendants(matching: .any).matching(identifier: "dossierRow").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 15), "Packet in the list")
        XCTAssertTrue(row.label.contains("Flower Street"))
        XCTAssertTrue(row.label.contains("4 missing"))
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

        XCTAssertTrue(app.staticTexts["pageIndicator"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.staticTexts["Page 1 of 2"].exists)
    }

    @MainActor
    func testRenameKeepsTheNewName() {
        let app = launch(signedIn: true)
        scanOneDocument(in: app)

        documentRow(in: app).swipeLeft()
        let rename = app.buttons["Rename"].firstMatch
        XCTAssertTrue(rename.waitForExistence(timeout: 15), "Swipe actions")
        rename.tap()
        let field = app.alerts.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 15))
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 20))
        field.typeText("Receipt")
        app.alerts.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Receipt"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.staticTexts["Document 1"].exists)
    }

    @MainActor
    func testDeleteAsksFirstAndEmptiesTheList() {
        let app = launch(signedIn: true)
        scanOneDocument(in: app)

        documentRow(in: app).swipeLeft()
        let delete = app.buttons["Delete"].firstMatch
        XCTAssertTrue(delete.waitForExistence(timeout: 15), "Swipe actions")
        delete.tap()
        let confirm = app.alerts.buttons["Delete"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 15), "Delete asks for confirmation")
        confirm.tap()

        XCTAssertTrue(app.buttons["emptyStateScanButton"].waitForExistence(timeout: 15))
    }

    @MainActor
    func testAccountScreenOffersDeleteAccount() {
        let app = launch(signedIn: true)

        let account = app.buttons["accountButton"]
        XCTAssertTrue(account.waitForExistence(timeout: 30))
        account.tap()

        XCTAssertTrue(app.buttons["deleteAccountButton"].waitForExistence(timeout: 15))
        app.buttons["accountDoneButton"].tap()
        XCTAssertTrue(app.buttons["newDossierButton"].waitForExistence(timeout: 15))
    }
}
