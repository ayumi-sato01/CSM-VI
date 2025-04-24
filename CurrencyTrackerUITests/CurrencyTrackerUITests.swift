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

        // Check for title and subtitle
        XCTAssertTrue(app.staticTexts["Zenny"].exists)
        XCTAssertTrue(app.staticTexts["Currency Tracker"].exists)

        // Check live exchange rate label
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "1")).firstMatch.exists)

        // Check for existence of a chart container
        XCTAssertTrue(app.otherElements.containing(.other, identifier: "Chart").firstMatch.exists)

        // Bottom navigation buttons
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
