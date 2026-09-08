import XCTest

/// Drives the real user path with a canned provider: unlock, disclaimer, capture, confirm, ledger.
/// Runs against the simulator only. The app is launched with `--ui-test-mock`, which swaps in
/// `MockProvider`, a throwaway ledger directory, and skips Keychain. No network, no real key.
@MainActor
final class CaptureFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testRambleBecomesConfirmedLedgerRow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-test-mock"]
        app.launch()

        // The lock screen is skipped under --ui-test-mock because LocalAuthentication is system UI.
        let acceptToggle = app.switches["onboarding.accept"]
        XCTAssertTrue(acceptToggle.waitForExistence(timeout: 10), "onboarding did not appear")

        // Disclaimer + BYOK onboarding. Continue is disabled until the toggle is on.
        let continueButton = app.buttons["onboarding.continue"]
        XCTAssertFalse(continueButton.isEnabled, "continue must be disabled before the disclaimer is accepted")
        acceptToggle.switches.firstMatch.exists ? acceptToggle.switches.firstMatch.tap() : acceptToggle.tap()
        XCTAssertTrue(continueButton.waitForEnabled(timeout: 3))
        continueButton.tap()

        // Capture: type a ramble and ask for a proposal.
        let ramble = app.textFields["capture.ramble"]
        XCTAssertTrue(ramble.waitForExistence(timeout: 5), "capture screen did not appear")
        ramble.tap()
        ramble.typeText("uh yeah just did 250 micrograms of BPC in the left abdomen")
        app.buttons["capture.propose"].tap()

        // Proposal card: one doseLogged row plus a gap. Nothing filed yet.
        XCTAssertTrue(app.staticTexts["Proposed rows"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["doseLogged"].exists)
        XCTAssertTrue(app.staticTexts["Gaps"].exists)

        // Confirm.
        app.buttons["capture.commit"].tap()

        // Proposal card is gone once filed.
        XCTAssertTrue(waitForDisappearance(app.staticTexts["Proposed rows"], timeout: 5),
                      "proposal card stayed after filing")

        // Propose drops the keyboard. If it is somehow still up, it would swallow the tab tap.
        XCTAssertEqual(app.keyboards.count, 0, "keyboard should be dismissed after Propose")
        let tabBar = app.tabBars.firstMatch
        if !tabBar.waitForExistence(timeout: 5) {
            attachScreenshot(app, name: "no-tab-bar")
            XCTFail("tab bar not reachable after filing")
        }

        // Ledger tab shows the filed row. List cells merge their children, so match visible text.
        tabBar.buttons["Ledger"].tap()
        if !app.navigationBars["Ledger"].waitForExistence(timeout: 5) {
            attachScreenshot(app, name: "no-ledger-nav")
            XCTFail("Ledger tab did not open")
        }
        let excerpt = app.staticTexts["250 micrograms of BPC in the left abdomen"]
        if !excerpt.waitForExistence(timeout: 5) {
            attachScreenshot(app, name: "no-ledger-row")
            XCTFail("confirmed row did not reach the ledger")
        }
        XCTAssertFalse(app.staticTexts["No rows yet. Capture a ramble and confirm it."].exists)
        attachScreenshot(app, name: "ledger-after-confirm")
    }

    private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func waitForDisappearance(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}

private extension XCUIElement {
    @MainActor
    func waitForEnabled(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "isEnabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
