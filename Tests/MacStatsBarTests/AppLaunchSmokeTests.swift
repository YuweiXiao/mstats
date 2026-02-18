import AppKit
import XCTest
@testable import MacStatsBar

final class AppLaunchSmokeTests: XCTestCase {
    func testStatusBarControllerConstructs() {
        _ = NSApplication.shared
        let controller = StatusBarController()
        XCTAssertNotNil(controller)
    }
}
