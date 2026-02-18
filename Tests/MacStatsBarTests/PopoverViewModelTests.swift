import Foundation
import SwiftUI
import XCTest
@testable import MacStatsBar

final class PopoverViewModelTests: XCTestCase {
    func testBuildsAllCoreCardsInStableOrderAndMappedTexts() {
        let snapshot = StatsSnapshot(
            timestamp: Date(timeIntervalSince1970: 1_706_000_000),
            metrics: [
                .cpuUsage: MetricValue(primaryValue: 23.5, secondaryValue: nil, unit: .percent),
                .memoryUsage: MetricValue(primaryValue: 14.24, secondaryValue: 31.96, unit: .gigabytes),
                .networkThroughput: MetricValue(primaryValue: 12.34, secondaryValue: 0.05, unit: .megabytesPerSecond),
                .batteryStatus: MetricValue(primaryValue: 87.2, secondaryValue: nil, unit: .percent),
                .diskUsage: MetricValue(primaryValue: 256.1, secondaryValue: 512, unit: .gigabytes)
            ]
        )

        let viewModel = PopoverViewModel(snapshot: snapshot)

        XCTAssertEqual(viewModel.cards.count, 5)
        XCTAssertEqual(
            viewModel.cards.map(\.kind),
            [.cpuUsage, .memoryUsage, .networkThroughput, .batteryStatus, .diskUsage]
        )
        XCTAssertEqual(
            viewModel.cards.map(\.text),
            [
                "CPU 24%",
                "MEM 14.2/32 GB",
                "NET 12.3↓ 0.1↑ MB/s",
                "BAT 87%",
                "DSK 256.1/512 GB"
            ]
        )
    }

    func testBuildUsesPlaceholderTextWhenSnapshotIsNil() {
        let viewModel = PopoverViewModel(snapshot: nil)

        XCTAssertEqual(viewModel.cards.count, 5)
        XCTAssertEqual(
            viewModel.cards.map(\.text),
            [
                "CPU --",
                "MEM --/-- GB",
                "NET --↓ --↑ MB/s",
                "BAT --",
                "DSK --/-- GB"
            ]
        )
    }

    func testBuildUsesPlaceholderTextWhenMetricsAreMissing() {
        let snapshot = StatsSnapshot(
            timestamp: Date(timeIntervalSince1970: 1_706_000_000),
            metrics: [:]
        )

        let viewModel = PopoverViewModel(snapshot: snapshot)

        XCTAssertEqual(viewModel.cards.count, 5)
        XCTAssertEqual(
            viewModel.cards.map(\.text),
            [
                "CPU --",
                "MEM --/-- GB",
                "NET --↓ --↑ MB/s",
                "BAT --",
                "DSK --/-- GB"
            ]
        )
    }

    func testSettingsStateUpdateSummaryMetricSwapsDuplicateSelectionToPreserveUniqueOrder() {
        var settings = SettingsState.defaultValue

        settings.updateSummaryMetric(at: 0, to: .memoryUsage)

        XCTAssertEqual(
            settings.summaryMetricOrder,
            [.memoryUsage, .cpuUsage, .networkThroughput, .batteryStatus, .diskUsage]
        )
    }

    func testPopoverRootViewAcceptsExternalSettingsBinding() {
        let rootView = PopoverRootView(snapshot: nil, settings: .constant(.defaultValue))

        XCTAssertNotNil(rootView)
    }
}
