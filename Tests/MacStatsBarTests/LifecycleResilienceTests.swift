import Foundation
import XCTest
@testable import MacStatsBar

final class LifecycleResilienceTests: XCTestCase {
    @MainActor
    func testHandleWillSleepStopsPollingAndDidWakeResumesWhenPreviouslyPolling() {
        let collector = LifecycleNoopCollector()
        let store = StatsStore(collector: collector, refreshInterval: 60)

        store.startPolling()
        XCTAssertTrue(store.isPolling)

        store.handleWillSleep()
        XCTAssertFalse(store.isPolling)

        store.handleDidWake()
        XCTAssertTrue(store.isPolling)

        store.stopPolling()
    }

    @MainActor
    func testHandleDidWakeDoesNotStartPollingWhenStoreWasNotPollingBeforeSleep() {
        let collector = LifecycleNoopCollector()
        let store = StatsStore(collector: collector, refreshInterval: 60)

        XCTAssertFalse(store.isPolling)

        store.handleWillSleep()
        store.handleDidWake()

        XCTAssertFalse(store.isPolling)
    }
}

private actor LifecycleNoopCollector: StatsCollecting {
    func collect() async throws -> StatsSnapshot {
        StatsSnapshot(
            timestamp: Date(timeIntervalSince1970: 1_706_000_000),
            metrics: [
                .cpuUsage: MetricValue(primaryValue: 1, secondaryValue: nil, unit: .percent)
            ]
        )
    }
}
