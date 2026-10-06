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

    func testMilestonesAccumulateRestoreAndResetForANewFast() {
        let app = launch(extra: ["-DemoData"], active: true)
        XCTAssertTrue(app.buttons["milestone-reserves"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["milestone-fatFuel"].exists)
        XCTAssertFalse(app.buttons["milestone-ketones"].exists)
        XCTAssertFalse(app.buttons["milestone-oneDay"].exists)
        capture("milestones-timer-en")
        app.buttons["milestone-fatFuel"].tap()
        XCTAssertTrue(app.buttons["closeMilestoneGuideButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "does not detect fat burning")).firstMatch.exists)
        capture("milestones-guide-en")
        app.buttons["closeMilestoneGuideButton"].tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["milestone-reserves"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["milestone-fatFuel"].exists)
        app.swipeUp()
        app.buttons["finishFastButton"].tap()
        app.buttons["Finish and Save"].tap()
        XCTAssertTrue(app.buttons["startFastButton"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["milestone-reserves"].exists)
        app.buttons["startFastButton"].tap()
        app.buttons["confirmStartButton"].tap()
        XCTAssertTrue(app.buttons["milestoneGuideButton"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["milestone-reserves"].exists)
    }

    func testAllMultiDayMilestonesAndSpanishDetails() {
        let app = launch(language: "es", extra: ["-DemoData", "-DemoMultiDay"], active: true)
        for id in ["reserves", "fatFuel", "ketones", "oneDay", "twoDays", "threeDays"] {
            XCTAssertTrue(app.buttons["milestone-\(id)"].waitForExistence(timeout: 5))
        }
        capture("milestones-multiday-es")
        app.buttons["milestone-ketones"].tap()
        XCTAssertTrue(app.buttons["closeMilestoneGuideButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "no confirma la cetosis")).firstMatch.exists)
        capture("milestones-ketones-es")
        app.buttons["closeMilestoneGuideButton"].tap()
        XCTAssertTrue(app.buttons["milestone-threeDays"].waitForExistence(timeout: 5))
    }

    func testMilestoneBadgesWithLargestAccessibilityText() {
        let app = launch(extra: ["-DemoData", "-DemoMultiDay", "-UIPreferredContentSizeCategoryName",
                                 "UICTContentSizeCategoryAccessibilityXXXL"], active: true)
        app.swipeUp()
        app.buttons["milestone-ketones"].tap()
        XCTAssertTrue(app.buttons["closeMilestoneGuideButton"].waitForExistence(timeout: 5))
        capture("milestones-guide-large-text")
        app.buttons["closeMilestoneGuideButton"].tap()
        app.swipeUp()
        XCTAssertTrue(app.buttons["milestone-threeDays"].exists)
        capture("milestones-badges-large-text")
    }

    func testLastMealCanBeRecordedAndSurvivesRelaunchWithoutChangingFast() {
        let app = launch()
        XCTAssertEqual(app.tabBars.buttons.count, 3)
        app.tabBars.buttons["Last Meal"].tap()
        XCTAssertTrue(app.staticTexts["emptyMealMessage"].waitForExistence(timeout: 5))
        capture("last-meal-empty-en")
        app.buttons["recordMealNowButton"].tap()
        XCTAssertTrue(app.staticTexts["lastMealDate"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["emptyMealMessage"].exists)
        let savedDate = app.staticTexts["lastMealDate"].label
        capture("last-meal-recorded-en")
        app.terminate()
        app.launch()
        app.tabBars.buttons["Last Meal"].tap()
        XCTAssertTrue(app.staticTexts["lastMealDate"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["lastMealDate"].label, savedDate)
        app.tabBars.buttons["Fast"].tap()
        XCTAssertTrue(app.buttons["startFastButton"].exists)
        app.buttons["startFastButton"].tap()
        app.buttons["confirmStartButton"].tap()
        XCTAssertTrue(app.buttons["finishFastButton"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Last Meal"].tap()
        app.buttons["recordMealNowButton"].tap()
        app.tabBars.buttons["Fast"].tap()
        XCTAssertTrue(app.buttons["finishFastButton"].exists)
    }

    func testLastMealShowsMultiDayElapsedTimeAndCanBeReset() {
        let app = launch(extra: ["-DemoMealData", "-DemoMealMultiDay"])
        app.tabBars.buttons["Last Meal"].tap()
        let elapsed = app.staticTexts["mealElapsedTime"]
        XCTAssertTrue(elapsed.waitForExistence(timeout: 5))
        XCTAssertTrue((elapsed.value as? String ?? "").contains("3 days"))
        capture("last-meal-multiday-en")
        app.terminate()
        app.launch()
        app.tabBars.buttons["Last Meal"].tap()
        XCTAssertTrue(elapsed.waitForExistence(timeout: 10))
        XCTAssertTrue((elapsed.value as? String ?? "").contains("3 days"))
        app.buttons["chooseMealTimeButton"].tap()
        XCTAssertTrue(app.buttons["confirmMealTimeButton"].waitForExistence(timeout: 5))
        capture("last-meal-time-editor-en")
        app.buttons["confirmMealTimeButton"].tap()
        XCTAssertTrue((elapsed.value as? String ?? "").contains("3 days"))
        app.buttons["recordMealNowButton"].tap()
        XCTAssertTrue((elapsed.label).contains("Time since last meal"))
        XCTAssertFalse((elapsed.value as? String ?? "").contains("days"))
    }

    func testLastMealCounterTicksBetweenMeals() {
        let app = launch(extra: ["-DemoMealData"])
        app.tabBars.buttons["Last Meal"].tap()
        let elapsed = app.staticTexts["mealElapsedTime"]
        XCTAssertTrue(elapsed.waitForExistence(timeout: 5))
        let initial = elapsed.value as? String ?? ""
        XCTAssertTrue(initial.contains("12 hours"))
        XCTAssertTrue(initial.contains("43 minutes"))
        let tick = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (elapsed.value as? String ?? "") != initial
        }, object: elapsed)
        XCTAssertEqual(XCTWaiter.wait(for: [tick], timeout: 5), .completed)
        capture("last-meal-en")
        app.buttons["chooseMealTimeButton"].tap()
        XCTAssertTrue(app.buttons["confirmMealTimeButton"].waitForExistence(timeout: 5))
        capture("last-meal-editor-en")
        app.buttons["cancelMealTimeButton"].tap()
    }

    func testLastMealSpanishLabelsAndPastTimeEditor() {
        let app = launch(language: "es", extra: ["-DemoMealData"])
        app.tabBars.buttons["Última comida"].tap()
        XCTAssertTrue(app.buttons["recordMealNowButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["recordMealNowButton"].label.contains("Acabo de comer"))
        capture("last-meal-es")
        app.buttons["chooseMealTimeButton"].tap()
        XCTAssertTrue(app.buttons["confirmMealTimeButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["Hora de la comida"].exists)
        capture("last-meal-time-editor-es")
        app.buttons["cancelMealTimeButton"].tap()
        XCTAssertTrue(app.staticTexts["lastMealDate"].waitForExistence(timeout: 5))
    }

    func testLastMealCounterAndActionsWithLargestAccessibilityText() {
        let app = launch(extra: ["-DemoMealData", "-DemoMealMultiDay", "-UIPreferredContentSizeCategoryName",
                                 "UICTContentSizeCategoryAccessibilityXXXL"])
        app.tabBars.buttons["Last Meal"].tap()
        XCTAssertTrue(app.staticTexts["mealElapsedTime"].waitForExistence(timeout: 5))
        XCTAssertTrue((app.staticTexts["mealElapsedTime"].value as? String ?? "").contains("3 days"))
        capture("last-meal-large-text")
        app.swipeUp()
        app.buttons["chooseMealTimeButton"].tap()
        XCTAssertTrue(app.buttons["confirmMealTimeButton"].waitForExistence(timeout: 5))
        capture("last-meal-editor-large-text")
        app.buttons["cancelMealTimeButton"].tap()
        app.swipeUp()
        app.buttons["recordMealNowButton"].tap()
        XCTAssertTrue(app.staticTexts["lastMealDate"].waitForExistence(timeout: 5))
        XCTAssertFalse((app.staticTexts["mealElapsedTime"].value as? String ?? "").contains("days"))
    }
}
