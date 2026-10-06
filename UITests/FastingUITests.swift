import XCTest

@MainActor
final class FastingUITests: XCTestCase {
    private func launch(language: String = "en", extra: [String] = []) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-UITestStore", UUID().uuidString, "-AppleLanguages", "(\(language))", "-AppleLocale", language == "es" ? "es_ES" : "en_GB"] + extra
        app.launch()
        XCTAssertTrue(app.buttons["startFastButton"].waitForExistence(timeout: 10))
        return app
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testStartRelaunchFinishAndHistory() {
        let app = launch()
        capture("timer-ready-en")
        app.buttons["startFastButton"].tap()
        app.buttons["confirmStartButton"].tap()
        XCTAssertTrue(app.buttons["finishFastButton"].waitForExistence(timeout: 5))
        capture("timer-running-en")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["finishFastButton"].waitForExistence(timeout: 10))
        app.buttons["finishFastButton"].tap()
        app.buttons["Finish and Save"].tap()
        XCTAssertTrue(app.buttons["startFastButton"].waitForExistence(timeout: 5))
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.buttons["historySessionRow"].waitForExistence(timeout: 5))
        capture("history-en")
    }

    func testAddEditAndDeletePastFast() {
        let app = launch()
        app.tabBars.buttons["History"].tap()
        app.buttons["addPastFastButton"].tap()
        app.buttons["saveSessionButton"].tap()
        let row = app.buttons["historySessionRow"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("16 h"))
        row.tap()
        XCTAssertTrue(app.buttons["saveSessionButton"].waitForExistence(timeout: 5))
        app.buttons["saveSessionButton"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        app.buttons["deleteFastButton"].tap()
        app.buttons.matching(identifier: "Delete Fast").firstMatch.tap()
        XCTAssertTrue(app.buttons["emptyAddFastButton"].waitForExistence(timeout: 5))
    }

    func testSpanishInterfaceAndSettings() {
        let app = launch(language: "es")
        XCTAssertTrue(app.buttons["startFastButton"].label.contains("Empezar"))
        capture("timer-ready-es")
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.staticTexts["Sin anuncios ni analítica"].waitForExistence(timeout: 5))
        capture("settings-es")
    }

    func testLargeTextCanStartAndFinish() {
        let app = launch(extra: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        app.swipeUp()
        app.buttons["startFastButton"].tap()
        app.buttons["confirmStartButton"].tap()
        XCTAssertTrue(app.buttons["finishFastButton"].waitForExistence(timeout: 5))
        capture("timer-large-text")
    }
}
