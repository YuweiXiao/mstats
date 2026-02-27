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
                "24%",
                "14.2/32 GB",
                "12↓ 0.1↑ MB/s",
                "87%",
                "256.1/512 GB"
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
                "--",
                "--/-- GB",
                "--↓ --↑ MB/s",
                "--",
                "--/-- GB"
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
                "--",
                "--/-- GB",
                "--↓ --↑ MB/s",
                "--",
                "--/-- GB"
            ]
        )
    }

    func testBuildShowsTopProcessesSortedByCPUWithOnePercentMinimumAndLimitTen() throws {
        let snapshot = StatsSnapshot(
            timestamp: Date(timeIntervalSince1970: 1_706_000_000),
            metrics: [
                .cpuUsage: MetricValue(primaryValue: 42, secondaryValue: nil, unit: .percent)
            ],
            processCPUUsages: [
                ProcessCPUUsage(processName: "Finder", cpuUsagePercent: 0.9),
                ProcessCPUUsage(processName: "Chrome Helper", cpuUsagePercent: 12.8),
                ProcessCPUUsage(processName: "WindowServer", cpuUsagePercent: 7.2),
                ProcessCPUUsage(processName: "Xcode", cpuUsagePercent: 41.3),
                ProcessCPUUsage(processName: "mds", cpuUsagePercent: 1.0),
                ProcessCPUUsage(processName: "node", cpuUsagePercent: 1.4),
                ProcessCPUUsage(processName: "Slack", cpuUsagePercent: 4.4),
                ProcessCPUUsage(processName: "Safari", cpuUsagePercent: 5.0),
                ProcessCPUUsage(processName: "kernel_task", cpuUsagePercent: 9.7),
                ProcessCPUUsage(processName: "Spotify", cpuUsagePercent: 3.1),
                ProcessCPUUsage(processName: "Code", cpuUsagePercent: 2.2),
                ProcessCPUUsage(processName: "Photos", cpuUsagePercent: 1.9),
                ProcessCPUUsage(processName: "backupd", cpuUsagePercent: 0.4)
            ]
        )

        let viewModel = PopoverViewModel(snapshot: snapshot)

        XCTAssertEqual(viewModel.topCPUProcesses.count, 10)
        XCTAssertEqual(
            viewModel.topCPUProcesses.map(\.name),
            [
                "Xcode",
                "Chrome Helper",
                "kernel_task",
                "WindowServer",
                "Safari",
                "Slack",
                "Spotify",
                "Code",
                "Photos",
                "node"
            ]
        )
        let lastCPU = try XCTUnwrap(viewModel.topCPUProcesses.last?.cpuUsagePercent)
        XCTAssertEqual(lastCPU, 1.4, accuracy: 0.0001)
        XCTAssertTrue(viewModel.topCPUProcesses.allSatisfy { $0.cpuUsagePercent >= 1.0 })
    }

    func testBuildAssignsUniqueTopProcessIDsWhenNamesRepeat() {
        let snapshot = StatsSnapshot(
            timestamp: Date(timeIntervalSince1970: 1_706_000_000),
            metrics: [
                .cpuUsage: MetricValue(primaryValue: 42, secondaryValue: nil, unit: .percent)
            ],
            processCPUUsages: [
                ProcessCPUUsage(processName: "Chrome Helper", cpuUsagePercent: 5.0),
                ProcessCPUUsage(processName: "Chrome Helper", cpuUsagePercent: 5.0),
                ProcessCPUUsage(processName: "WindowServer", cpuUsagePercent: 4.0),
                ProcessCPUUsage(processName: "Finder", cpuUsagePercent: 0.5)
            ]
        )

        let viewModel = PopoverViewModel(snapshot: snapshot)

        XCTAssertEqual(viewModel.topCPUProcesses.map(\.name), ["Chrome Helper", "Chrome Helper", "WindowServer"])
        XCTAssertEqual(viewModel.topCPUProcesses.count, 3)
        XCTAssertEqual(Set(viewModel.topCPUProcesses.map(\.id)).count, 3)
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

    func testCPUCompositeCardViewCanBeInstantiatedWithEmptyProcessList() {
        let card = PopoverMetricCard(kind: .cpuUsage, title: "CPU", text: "CPU --")
        let view = CPUCompositeCardView(card: card, topProcesses: [])

        XCTAssertNotNil(view)
    }

    func testCPUCompositeCardLayoutKeepsCPUAndProcessPanelsSameHeight() {
        XCTAssertEqual(CPUCompositeCardLayout.cpuPanelHeight, CPUCompositeCardLayout.processPanelHeight)
    }

    func testCPUCompositeCardLayoutProcessPanelHeightFitsTenRows() {
        XCTAssertEqual(CPUCompositeCardLayout.maxProcessRows, 10)
        XCTAssertEqual(CPUCompositeCardLayout.processPanelHeight, CPUCompositeCardLayout.requiredProcessPanelHeight)
    }
}
