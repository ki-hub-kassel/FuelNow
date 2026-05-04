import XCTest

@MainActor
final class TankRadarUITests: XCTestCase {
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launch()
        XCTAssertTrue(app.staticTexts["TankRadar"].waitForExistence(timeout: 5))
    }
}
