import XCTest

final class CurrencyTrackerUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Add teardown logic if needed later
    }

    @MainActor
    func testDashboardLoadsElements() throws {
        let app = XCUIApplication()
        app.launch()

        // Check for title "Zenny"
        XCTAssertTrue(app.staticTexts["Zenny"].exists)

        // Check for subtitle
        XCTAssertTrue(app.staticTexts["Currency Tracker"].exists)

        // Check that the exchange rate placeholder exists
        XCTAssertTrue(app.staticTexts["Rate: 153.22"].exists)

        // Check graph placeholder text
        XCTAssertTrue(app.staticTexts["5-Day Trend Graph"].exists)

        // Check bottom nav buttons
        XCTAssertTrue(app.staticTexts["Log"].exists)
        XCTAssertTrue(app.staticTexts["Graph"].exists)
        XCTAssertTrue(app.staticTexts["Favorite"].exists)
        XCTAssertTrue(app.staticTexts["Settings"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
