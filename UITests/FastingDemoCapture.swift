import XCTest
import Darwin

/// A developer recording, skipped by the normal scheme. Uses its own SwiftData store.
@MainActor
final class FastingDemoCapture: XCTestCase {
    func testCaptureDemo() throws {
        try captureDemo(language: "es")
    }

    func testCaptureEnglishDemo() throws {
        try captureDemo(language: "en")
    }

    private func captureDemo(language: String) throws {
        guard ProcessInfo.processInfo.environment["FASTING_RECORD_DEMO"] == "1" else {
            throw XCTSkip("Use the FastingDemo scheme and scripts/record_demo.py to record the walkthrough.")
        }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = arguments(language: language)
        app.launch()
        XCTAssertTrue(app.buttons["finishFastButton"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["milestone-reserves"].exists)
        signal("READY")
        frame("timer", language: language)
        pause(5)

        app.buttons["milestone-fatFuel"].tap()
        XCTAssertTrue(app.buttons["closeMilestoneGuideButton"].waitForExistence(timeout: 5))
        frame("guide", language: language)
        pause(4)
        app.buttons["closeMilestoneGuideButton"].tap()
        pause(2)
        app.buttons["goalButton"].tap()
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: 5))
        pause(2)
        app.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: "18 h")
        pause(2)
        app.buttons["confirmGoalButton"].tap()
        pause(3)

        app.buttons["finishFastButton"].tap()
        pause(2)
        app.buttons[language == "en" ? "Finish and Save" : "Finalizar y guardar"].tap()
        XCTAssertTrue(app.buttons["startFastButton"].waitForExistence(timeout: 5))
        pause(2)

        app.tabBars.buttons[language == "en" ? "History" : "Historial"].tap()
        XCTAssertTrue(app.buttons["historySessionRow"].firstMatch.waitForExistence(timeout: 5))
        frame("history", language: language)
        pause(4)
        app.buttons["historySessionRow"].firstMatch.tap()
        XCTAssertTrue(app.buttons["saveSessionButton"].waitForExistence(timeout: 5))
        frame("editor", language: language)
        pause(4)
        app.buttons[language == "en" ? "Cancel" : "Cancelar"].tap()
        pause(2)

        app.buttons["addPastFastButton"].tap()
        XCTAssertTrue(app.buttons["saveSessionButton"].waitForExistence(timeout: 5))
        pause(3)
        app.buttons["saveSessionButton"].tap()
        pause(3)

        app.tabBars.buttons[language == "en" ? "Fast" : "Ayuno"].tap()
        app.buttons["startFastButton"].tap()
        XCTAssertTrue(app.buttons["confirmStartButton"].waitForExistence(timeout: 5))
        pause(3)
        app.buttons["confirmStartButton"].tap()
        XCTAssertTrue(app.buttons["finishFastButton"].waitForExistence(timeout: 5))
        pause(4)

        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.staticTexts[language == "en" ? "No ads or analytics" : "Sin anuncios ni analítica"].waitForExistence(timeout: 5))
        frame("settings", language: language)
        pause(5)
        app.buttons["closeSettingsButton"].tap()
        pause(2)

        // Show multi-day badges using another isolated example database.
        app.terminate()
        app.launchArguments = arguments(language: language, multiDay: true)
        app.launch()
        XCTAssertTrue(app.buttons["milestone-threeDays"].waitForExistence(timeout: 15))
        frame("multiday", language: language)
        pause(4)
        app.buttons["milestone-ketones"].tap()
        XCTAssertTrue(app.buttons["closeMilestoneGuideButton"].waitForExistence(timeout: 5))
        frame("ketones", language: language)
        pause(4)
        app.buttons["closeMilestoneGuideButton"].tap()
        app.buttons["goalButton"].tap()
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: 5))
        frame("goal", language: language)
        pause(3)
        app.buttons["cancelGoalButton"].tap()
        app.swipeUp()
        app.buttons["finishFastButton"].tap()
        app.buttons[language == "en" ? "Finish and Save" : "Finalizar y guardar"].tap()
        app.tabBars.buttons[language == "en" ? "History" : "Historial"].tap()
        XCTAssertTrue(app.buttons["historySessionRow"].firstMatch.waitForExistence(timeout: 5))
        frame("multiday-history", language: language)
        pause(4)

        app.terminate()
        app.launchArguments = arguments(language: language, multiDay: true)
        app.launch()
        XCTAssertTrue(app.buttons["milestone-threeDays"].waitForExistence(timeout: 15))
        signal("DARK")
        pause(6)
        frame("dark", language: language)
        pause(4)
        signal("DONE")
    }

    private func arguments(language: String, multiDay: Bool = false) -> [String] {
        ["-UITestStore", UUID().uuidString, "-DemoData",
         "-AppleLanguages", "(\(language))", "-AppleLocale", language == "en" ? "en_GB" : "es_ES",
         "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL"] + (multiDay ? ["-DemoMultiDay"] : [])
    }

    private func frame(_ name: String, language: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "readme-\(name)-\(language)"
        attachment.lifetime = .keepAlways
        add(attachment)
        signal("FRAME_\(name.uppercased())")
    }

    private func pause(_ seconds: TimeInterval) { Thread.sleep(forTimeInterval: seconds) }

    private func signal(_ stage: String) {
        print("FASTING_DEMO_\(stage)")
        fflush(stdout)
    }
}
