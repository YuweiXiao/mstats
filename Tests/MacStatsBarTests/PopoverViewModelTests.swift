import Foundation
import XCTest
@testable import MacStatsBar

final class PopoverViewModelTests: XCTestCase {
    func testBuildsAllCoreCardsInStableOrder() {
        let snapshot = StatsSnapshot(
            timestamp: Date(timeIntervalSince1970: 1_706_000_000),
            metrics: [
                .cpuUsage: MetricValue(primaryValue: 20, secondaryValue: nil, unit: .percent),
                .memoryUsage: MetricValue(primaryValue: 8, secondaryValue: 16, unit: .gigabytes),
                .networkThroughput: MetricValue(primaryValue: 3, secondaryValue: 1, unit: .megabytesPerSecond),
                .batteryStatus: MetricValue(primaryValue: 85, secondaryValue: nil, unit: .percent),
                .diskUsage: MetricValue(primaryValue: 128, secondaryValue: 256, unit: .gigabytes)
            ]
        )

        let viewModel = PopoverViewModel(snapshot: snapshot)

        XCTAssertEqual(viewModel.cards.count, 5)
        XCTAssertEqual(
            viewModel.cards.map(\.kind),
            [.cpuUsage, .memoryUsage, .networkThroughput, .batteryStatus, .diskUsage]
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
}
