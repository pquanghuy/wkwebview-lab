import XCTest

final class LabUITests: XCTestCase {
    @MainActor
    func testBridgeAndNavigation() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["Open lab"].tap()
        XCTAssertTrue(app.staticTexts["Ready"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Bridge rejected: untrusted frame"].waitForExistence(timeout: 5))
        let echo = app.webViews.buttons["Send & await reply"]
        let tappable = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: echo)
        XCTAssertEqual(XCTWaiter.wait(for: [tappable], timeout: 5), .completed)
        echo.press(forDuration: 0.1)
        XCTAssertTrue(app.staticTexts["Web → native echo accepted"].waitForExistence(timeout: 5))
        let initial = XCTAttachment(screenshot: app.screenshot())
        initial.name = "Echo reply"
        initial.lifetime = .keepAlways
        add(initial)
        app.webViews.buttons["Try invalid message"].tap()
        XCTAssertTrue(app.staticTexts["Bridge rejected: invalid message"].waitForExistence(timeout: 5))
        app.buttons["Send to web"].tap()
        XCTAssertTrue(app.staticTexts["Native → web delivered"].waitForExistence(timeout: 5))
        app.webViews.links["Try external navigation (blocked)"].tap()
        XCTAssertTrue(app.staticTexts["Navigation blocked: https"].waitForExistence(timeout: 5))
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Bridge lab after interaction"
        shot.lifetime = .keepAlways
        add(shot)
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["Open lab"].waitForExistence(timeout: 5))
        app.buttons["Open lab"].tap()
        XCTAssertTrue(app.staticTexts["Ready"].waitForExistence(timeout: 10))
    }
}
