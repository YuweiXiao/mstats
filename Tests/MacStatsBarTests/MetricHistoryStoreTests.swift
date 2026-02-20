import Foundation
import XCTest
@testable import MacStatsBar

final class MetricHistoryStoreTests: XCTestCase {
    func testAppendSnapshotKeepsOnlyLatestSamplesWithinCapacity() {
        var store = MetricHistoryStore(maxSamples: 2)

        store.append(snapshot: StatsSnapshot(
            timestamp: Date(timeIntervalSince1970: 1),
            metrics: [.cpuUsage: MetricValue(primaryValue: 10, secondaryValue: nil, unit: .percent)]
        ))
        store.append(snapshot: StatsSnapshot(
            timestamp: Date(timeIntervalSince1970: 2),
            metrics: [.cpuUsage: MetricValue(primaryValue: 20, secondaryValue: nil, unit: .percent)]
        ))
        store.append(snapshot: StatsSnapshot(
            timestamp: Date(timeIntervalSince1970: 3),
            metrics: [.cpuUsage: MetricValue(primaryValue: 30, secondaryValue: nil, unit: .percent)]
        ))

        let cpuSamples = store.history[.cpuUsage]
        XCTAssertEqual(cpuSamples?.count, 2)
        XCTAssertEqual(cpuSamples?.map(\.primary), [20, 30])
    }

    func testAppendSnapshotTracksPrimaryAndSecondaryValues() {
        var store = MetricHistoryStore(maxSamples: 5)

        store.append(snapshot: StatsSnapshot(
            timestamp: Date(timeIntervalSince1970: 1),
            metrics: [.networkThroughput: MetricValue(primaryValue: 1.5, secondaryValue: 0.4, unit: .megabytesPerSecond)]
        ))

        let sample = store.history[.networkThroughput]?.first
        XCTAssertEqual(sample?.primary, 1.5)
        XCTAssertEqual(sample?.secondary, 0.4)
    }
}
