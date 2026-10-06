import XCTest
import Darwin

/// A developer recording, skipped by the normal scheme. Uses its own SwiftData store.
@MainActor
final class FastingDemoCapture: XCTestCase {
    func testCaptureDemo() throws {
        guard ProcessInfo.processInfo.environment["FASTING_RECORD_DEMO"] == "1" else {
            throw XCTSkip("Use the FastingDemo scheme and scripts/record_demo.py to record the walkthrough.")
        }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = [
            "-UITestStore", UUID().uuidString, "-DemoData",
            "-AppleLanguages", "(es)", "-AppleLocale", "es_ES",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL"
        ]
        app.launch()
        XCTAssertTrue(app.buttons["finishFastButton"].waitForExistence(timeout: 15))
        signal("READY")
        pause(5)

        app.buttons["goalButton"].tap()
        XCTAssertTrue(app.pickerWheels.firstMatch.waitForExistence(timeout: 5))
        pause(2)
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "18 h")
        pause(2)
        app.buttons["Listo"].tap()
        pause(3)

        app.buttons["finishFastButton"].tap()
        pause(2)
        app.buttons["Finalizar y guardar"].tap()
        XCTAssertTrue(app.buttons["startFastButton"].waitForExistence(timeout: 5))
        pause(2)

        app.tabBars.buttons["Historial"].tap()
        XCTAssertTrue(app.buttons["historySessionRow"].firstMatch.waitForExistence(timeout: 5))
        pause(4)
        app.buttons["historySessionRow"].firstMatch.tap()
        XCTAssertTrue(app.buttons["saveSessionButton"].waitForExistence(timeout: 5))
        pause(4)
        app.buttons["Cancelar"].tap()
        pause(2)

        app.buttons["addPastFastButton"].tap()
        XCTAssertTrue(app.buttons["saveSessionButton"].waitForExistence(timeout: 5))
        pause(3)
        app.buttons["saveSessionButton"].tap()
        pause(3)

        app.tabBars.buttons["Ayuno"].tap()
        app.buttons["startFastButton"].tap()
        XCTAssertTrue(app.buttons["confirmStartButton"].waitForExistence(timeout: 5))
        pause(3)
        app.buttons["confirmStartButton"].tap()
        XCTAssertTrue(app.buttons["finishFastButton"].waitForExistence(timeout: 5))
        pause(4)

        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.staticTexts["Sin anuncios ni analítica"].waitForExistence(timeout: 5))
        pause(5)
        app.buttons["Listo"].tap()
        pause(2)
        signal("DARK")
        pause(6)
        app.buttons["goalButton"].tap()
        pause(3)
        app.buttons["Cancelar"].tap()
        pause(4)
        signal("DONE")
    }

    private func pause(_ seconds: TimeInterval) { Thread.sleep(forTimeInterval: seconds) }

    private func signal(_ stage: String) {
        print("FASTING_DEMO_\(stage)")
        fflush(stdout)
    }
}
