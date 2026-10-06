import XCTest

@MainActor
final class FastingUITests: XCTestCase {
    private func launch(language: String = "en", extra: [String] = [], active: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-UITestStore", UUID().uuidString, "-AppleLanguages", "(\(language))", "-AppleLocale", language == "es" ? "es_ES" : "en_GB"] + extra
        app.launch()
        XCTAssertTrue(app.buttons[active ? "finishFastButton" : "startFastButton"].waitForExistence(timeout: 10))
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
        app.buttons["goalButton"].tap()
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: 5))
        app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "3 d")
        app.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: "0 h")
        XCTAssertEqual(app.pickerWheels.element(boundBy: 1).value as? String, "0 h")
        capture("goal-three-days-large-text")
        app.buttons["confirmGoalButton"].tap()
        XCTAssertFalse(app.buttons["goalButton"].label.contains(" h"))
        app.swipeUp()
        app.buttons["startFastButton"].tap()
        app.buttons["confirmStartButton"].tap()
        XCTAssertTrue(app.buttons["finishFastButton"].waitForExistence(timeout: 5))
        capture("timer-large-text")
    }

    func testMultiDayGoalsInSettingsTimerAndHistoryEditor() {
        let app = launch()
        app.buttons["settingsButton"].tap()
        app.buttons["defaultGoalRow"].tap()
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: 5))
        app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "3 d")
        app.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: "0 h")
        XCTAssertEqual(app.pickerWheels.element(boundBy: 1).value as? String, "0 h")
        capture("goal-three-days-en")
        app.buttons["confirmGoalButton"].tap()
        app.buttons["closeSettingsButton"].tap()
        XCTAssertTrue(app.buttons["goalButton"].label.contains("3 d"))
        app.buttons["startFastButton"].tap()
        app.buttons["confirmStartButton"].tap()
        XCTAssertTrue(app.buttons["finishFastButton"].waitForExistence(timeout: 5))
        app.buttons["goalButton"].tap()
        app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "15 d")
        app.buttons["confirmGoalButton"].tap()
        XCTAssertTrue(app.buttons["goalButton"].label.contains("15 d"))
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["finishFastButton"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["goalButton"].label.contains("15 d"))
        app.buttons["finishFastButton"].tap()
        app.buttons["Finish and Save"].tap()
        app.tabBars.buttons["History"].tap()
        let row = app.buttons["historySessionRow"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("15 d"))
        row.tap()
        app.buttons["sessionGoalRow"].tap()
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: 5))
        app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "3 d")
        app.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: "1 h")
        XCTAssertEqual(app.pickerWheels.element(boundBy: 1).value as? String, "1 h")
        app.buttons["confirmGoalButton"].tap()
        app.buttons["saveSessionButton"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("3 d 1 h"))
    }

    func testMultiDayTimerSurvivesRelaunchAndSavesItsFullDuration() {
        let app = launch(extra: ["-DemoData", "-DemoMultiDay"], active: true)
        let elapsed = app.staticTexts["elapsedTime"]
        XCTAssertTrue((elapsed.value as? String ?? "").contains("3 days"))
        XCTAssertTrue(app.buttons["goalButton"].label.contains("3 d"))
        capture("timer-multiday-en")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["finishFastButton"].waitForExistence(timeout: 10))
        XCTAssertTrue((elapsed.value as? String ?? "").contains("3 days"))
        app.buttons["finishFastButton"].tap()
        app.buttons["Finish and Save"].tap()
        app.tabBars.buttons["History"].tap()
        let row = app.buttons.matching(identifier: "historySessionRow")
            .matching(NSPredicate(format: "label CONTAINS %@", "3 d 4 h")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        capture("history-multiday-en")
    }
}
