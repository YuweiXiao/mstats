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


    func testBuildMapsHistoryIntoTrendSeries() throws {
        let snapshot = StatsSnapshot(
            timestamp: Date(timeIntervalSince1970: 1_706_000_000),
            metrics: [
                .cpuUsage: MetricValue(primaryValue: 23.5, secondaryValue: nil, unit: .percent),
                .networkThroughput: MetricValue(primaryValue: 12.34, secondaryValue: 0.05, unit: .megabytesPerSecond)
            ]
        )

        let history: [MetricKind: [MetricHistorySample]] = [
            .cpuUsage: [
                MetricHistorySample(primary: 20, secondary: nil),
                MetricHistorySample(primary: 30, secondary: nil)
            ],
            .networkThroughput: [
                MetricHistorySample(primary: 1.2, secondary: 0.2),
                MetricHistorySample(primary: 1.6, secondary: 0.4)
            ]
        ]

        let viewModel = PopoverViewModel(snapshot: snapshot, history: history)

        let cpuCard = try XCTUnwrap(viewModel.cards.first(where: { $0.kind == .cpuUsage }))
        XCTAssertEqual(cpuCard.trendSeries.map(\.label), ["Usage"])
        XCTAssertEqual(cpuCard.trendSeries.first?.points, [20, 30])

        let networkCard = try XCTUnwrap(viewModel.cards.first(where: { $0.kind == .networkThroughput }))
        XCTAssertEqual(networkCard.trendSeries.map(\.label), ["Down", "Up"])
        XCTAssertEqual(networkCard.trendSeries[0].points, [1.2, 1.6])
        XCTAssertEqual(networkCard.trendSeries[1].points, [0.2, 0.4])
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

    func testSettingsStateSecondaryMetricCanBeDisabled() {
        var settings = SettingsState.defaultValue

        settings.secondaryStatusMetric = nil

        XCTAssertNil(settings.secondaryStatusMetric)
        XCTAssertFalse(settings.showSecondaryMetric)
    }

    func testSettingsStateSecondaryMetricReenableUsesSelectedMetric() {
        var settings = SettingsState.defaultValue
        settings.secondaryStatusMetric = nil

        settings.secondaryStatusMetric = .diskUsage

        XCTAssertEqual(settings.secondaryStatusMetric, .diskUsage)
        XCTAssertTrue(settings.showSecondaryMetric)
    }

    func testPopoverRootViewAcceptsExternalSettingsBinding() {
        let rootView = PopoverRootView(snapshot: nil, settings: .constant(.defaultValue))

        XCTAssertNotNil(rootView)
    }
}
