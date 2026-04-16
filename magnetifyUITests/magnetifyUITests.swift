import XCTest

final class MagnetifyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunchesSuccessfully() throws {
        let app = XCUIApplication()
        app.launch()
        // Menu bar app should launch without crashing
        XCTAssertTrue(app.exists)
        app.terminate()
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
