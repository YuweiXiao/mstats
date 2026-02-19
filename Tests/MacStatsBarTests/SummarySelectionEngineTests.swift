import AppKit
import Foundation
import XCTest
@testable import MacStatsBar

final class SummarySelectionEngineTests: XCTestCase {
    func testSelectionLimitsToTwoByDefault() {
        let order: [MetricKind] = [.cpuUsage, .memoryUsage, .networkThroughput]

        let shown = SummarySelectionEngine.visibleMetrics(order: order)

        XCTAssertEqual(shown, [.cpuUsage, .memoryUsage])
    }

    func testSelectionPreservesOrderingWithCustomCap() {
        let order: [MetricKind] = [.networkThroughput, .cpuUsage, .memoryUsage, .diskUsage]

        let shown = SummarySelectionEngine.visibleMetrics(order: order, maxVisible: 3)

        XCTAssertEqual(shown, [.networkThroughput, .cpuUsage, .memoryUsage])
    }
}

final class StatusBarControllerSummaryTests: XCTestCase {
    func testStatusBarControllerConfiguresButtonActionForPopoverToggle() {
        _ = NSApplication.shared
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        defer { NSStatusBar.system.removeStatusItem(statusItem) }

        _ = StatusBarController(statusItem: statusItem)

        XCTAssertNotNil(statusItem.button?.target)
        XCTAssertNotNil(statusItem.button?.action)
    }

    func testPopoverBehaviorMatchesSettingsPinBehavior() {
        XCTAssertEqual(
            StatusBarController.popoverBehavior(for: .autoClose),
            .transient
        )
        XCTAssertEqual(
            StatusBarController.popoverBehavior(for: .pinned),
            .applicationDefined
        )
    }

    func testSummaryTextRendersSelectedMetricsFromSnapshotUsingFormatter() {
        let snapshot = StatsSnapshot(
            timestamp: Date(timeIntervalSince1970: 0),
            metrics: [
                .cpuUsage: MetricValue(primaryValue: 23.2, secondaryValue: nil, unit: .percent),
                .memoryUsage: MetricValue(primaryValue: 14.24, secondaryValue: 31.96, unit: .gigabytes),
                .networkThroughput: MetricValue(primaryValue: 2.14, secondaryValue: 0.36, unit: .megabytesPerSecond)
            ]
        )
        let preferences = UserPreferences(
            summaryMetricOrder: [.networkThroughput, .cpuUsage, .memoryUsage],
            maxVisibleSummaryItems: 99
        )

        let text = StatusBarController.summaryText(snapshot: snapshot, preferences: preferences)

        XCTAssertEqual(text, "2.1↓0.4↑ | 23%")
    }

    func testSummaryTextFallsBackWhenNoVisibleMetricsAreSelected() {
        let preferences = UserPreferences(
            summaryMetricOrder: [.cpuUsage, .memoryUsage],
            maxVisibleSummaryItems: 0
        )

        let text = StatusBarController.summaryText(snapshot: nil, preferences: preferences)

        XCTAssertEqual(text, "--")
    }

    func testSummaryTextUsesPlaceholderForMissingSnapshotMetric() {
        let preferences = UserPreferences(
            summaryMetricOrder: [.cpuUsage],
            maxVisibleSummaryItems: 1
        )

        let text = StatusBarController.summaryText(snapshot: nil, preferences: preferences)

        XCTAssertEqual(text, "--")
    }
}
