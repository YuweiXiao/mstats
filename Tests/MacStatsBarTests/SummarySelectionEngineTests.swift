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
    func testHandleExitRequestedTerminatesApplication() {
        _ = NSApplication.shared
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        defer { NSStatusBar.system.removeStatusItem(statusItem) }

        let terminator = TestApplicationTerminator()
        let controller = StatusBarController(statusItem: statusItem, appTerminator: terminator)

        controller.handleExitRequested()

        XCTAssertEqual(terminator.terminateCallCount, 1)
    }

    func testStatusBarControllerConfiguresButtonActionForPopoverToggle() {
        _ = NSApplication.shared
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        defer { NSStatusBar.system.removeStatusItem(statusItem) }

        _ = StatusBarController(statusItem: statusItem)

        XCTAssertNotNil(statusItem.button?.target)
        XCTAssertNotNil(statusItem.button?.action)
    }

    func testStatusBarControllerUsesFixedLengthForOneAndTwoMetricLayouts() {
        _ = NSApplication.shared
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        defer { NSStatusBar.system.removeStatusItem(statusItem) }

        let controller = StatusBarController(statusItem: statusItem)

        let oneMetric = UserPreferences(summaryMetricOrder: [.cpuUsage], maxVisibleSummaryItems: 1)
        controller.renderSummary(snapshot: nil, preferences: oneMetric)
        let oneMetricLength = statusItem.length

        let twoMetric = UserPreferences(summaryMetricOrder: [.cpuUsage, .networkThroughput], maxVisibleSummaryItems: 2)
        controller.renderSummary(snapshot: nil, preferences: twoMetric)
        let twoMetricLength = statusItem.length

        XCTAssertGreaterThan(twoMetricLength, oneMetricLength)
        XCTAssertGreaterThan(oneMetricLength, 0)
        XCTAssertLessThanOrEqual(oneMetricLength, 52)
        XCTAssertLessThanOrEqual(twoMetricLength, 108)
    }

    func testStatusBarControllerUsesCompactWidthForCpuAndNetworkCombination() {
        _ = NSApplication.shared
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        defer { NSStatusBar.system.removeStatusItem(statusItem) }

        let controller = StatusBarController(statusItem: statusItem)
        let snapshot = StatsSnapshot(
            timestamp: Date(timeIntervalSince1970: 0),
            metrics: [
                .cpuUsage: MetricValue(primaryValue: 23.2, secondaryValue: nil, unit: .percent),
                .networkThroughput: MetricValue(primaryValue: 2.14, secondaryValue: 0.36, unit: .megabytesPerSecond)
            ]
        )
        let preferences = UserPreferences(
            summaryMetricOrder: [.cpuUsage, .networkThroughput],
            maxVisibleSummaryItems: 2
        )

        controller.renderSummary(snapshot: snapshot, preferences: preferences)

        XCTAssertLessThan(statusItem.length, 88)
    }

    func testStatusBarControllerAppliesSingleLineTruncationAttributes() {
        _ = NSApplication.shared
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        defer { NSStatusBar.system.removeStatusItem(statusItem) }

        let controller = StatusBarController(statusItem: statusItem)
        let twoMetric = UserPreferences(summaryMetricOrder: [.cpuUsage, .memoryUsage], maxVisibleSummaryItems: 2)

        controller.renderSummary(snapshot: nil, preferences: twoMetric)

        let paragraphStyle = statusItem.button?.attributedTitle.attribute(
            .paragraphStyle,
            at: 0,
            effectiveRange: nil
        ) as? NSParagraphStyle
        XCTAssertEqual(paragraphStyle?.lineBreakMode, .byTruncatingTail)
        XCTAssertEqual(paragraphStyle?.alignment, .center)

        let cell = statusItem.button?.cell as? NSButtonCell
        XCTAssertEqual(cell?.lineBreakMode, .byTruncatingTail)
        XCTAssertEqual(cell?.alignment, .center)
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

        XCTAssertEqual(text, "2.1↓|23%\n0.4↑MB/s")
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

    func testSummaryTextUsesTwoLinesForNetworkWhenItIsOnlyVisibleMetric() {
        let snapshot = StatsSnapshot(
            timestamp: Date(timeIntervalSince1970: 0),
            metrics: [
                .networkThroughput: MetricValue(primaryValue: 2.14, secondaryValue: 0.36, unit: .megabytesPerSecond)
            ]
        )
        let preferences = UserPreferences(
            summaryMetricOrder: [.networkThroughput],
            maxVisibleSummaryItems: 1
        )

        let text = StatusBarController.summaryText(snapshot: snapshot, preferences: preferences)

        XCTAssertEqual(text, "2.1↓\n0.4↑MB/s")
    }

    func testRenderSummaryUsesCustomMultilineViewForNetworkOnlyMetric() {
        _ = NSApplication.shared
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        defer { NSStatusBar.system.removeStatusItem(statusItem) }

        let controller = StatusBarController(statusItem: statusItem)
        let snapshot = StatsSnapshot(
            timestamp: Date(timeIntervalSince1970: 0),
            metrics: [
                .networkThroughput: MetricValue(primaryValue: 2.14, secondaryValue: 0.36, unit: .megabytesPerSecond)
            ]
        )
        let preferences = UserPreferences(
            summaryMetricOrder: [.networkThroughput],
            maxVisibleSummaryItems: 1
        )

        controller.renderSummary(snapshot: snapshot, preferences: preferences)

        let customView = statusItem.view as? NetworkMultilineStatusItemView
        XCTAssertNotNil(customView)
        XCTAssertNil(customView?.leadingMetricText)
        XCTAssertEqual(customView?.topLineText, "2.1↓")
        XCTAssertEqual(customView?.bottomLineText, "0.4↑MB/s")
        XCTAssertEqual(customView?.isCenterAligned, true)
    }

    func testRenderSummaryUsesCustomMultilineViewForCpuPlusNetwork() {
        _ = NSApplication.shared
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        defer { NSStatusBar.system.removeStatusItem(statusItem) }

        let controller = StatusBarController(statusItem: statusItem)
        let snapshot = StatsSnapshot(
            timestamp: Date(timeIntervalSince1970: 0),
            metrics: [
                .cpuUsage: MetricValue(primaryValue: 23.2, secondaryValue: nil, unit: .percent),
                .networkThroughput: MetricValue(primaryValue: 2.14, secondaryValue: 0.36, unit: .megabytesPerSecond)
            ]
        )
        let preferences = UserPreferences(
            summaryMetricOrder: [.cpuUsage, .networkThroughput],
            maxVisibleSummaryItems: 2
        )

        controller.renderSummary(snapshot: snapshot, preferences: preferences)

        let customView = statusItem.view as? NetworkMultilineStatusItemView
        XCTAssertNotNil(customView)
        XCTAssertEqual(customView?.leadingMetricText, "23%")
        XCTAssertEqual(customView?.topLineText, "2.1↓")
        XCTAssertEqual(customView?.bottomLineText, "0.4↑MB/s")
    }

    func testSwitchingFromMultilineToCpuOnlyRestoresClickableStatusButton() {
        _ = NSApplication.shared
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        defer { NSStatusBar.system.removeStatusItem(statusItem) }

        let controller = StatusBarController(statusItem: statusItem)
        let networkSnapshot = StatsSnapshot(
            timestamp: Date(timeIntervalSince1970: 0),
            metrics: [
                .networkThroughput: MetricValue(primaryValue: 2.14, secondaryValue: 0.36, unit: .megabytesPerSecond)
            ]
        )
        let networkOnly = UserPreferences(
            summaryMetricOrder: [.networkThroughput],
            maxVisibleSummaryItems: 1
        )
        controller.renderSummary(snapshot: networkSnapshot, preferences: networkOnly)
        XCTAssertNotNil(statusItem.view)

        let cpuSnapshot = StatsSnapshot(
            timestamp: Date(timeIntervalSince1970: 1),
            metrics: [
                .cpuUsage: MetricValue(primaryValue: 23.2, secondaryValue: nil, unit: .percent)
            ]
        )
        let cpuOnly = UserPreferences(
            summaryMetricOrder: [.cpuUsage],
            maxVisibleSummaryItems: 1
        )
        controller.renderSummary(snapshot: cpuSnapshot, preferences: cpuOnly)

        XCTAssertNil(statusItem.view)
        XCTAssertNotNil(statusItem.button)
        XCTAssertNotNil(statusItem.button?.target)
        XCTAssertNotNil(statusItem.button?.action)
    }
}

private final class TestApplicationTerminator: ApplicationTerminating {
    private(set) var terminateCallCount = 0

    func terminate(_ sender: Any?) {
        terminateCallCount += 1
    }
}
