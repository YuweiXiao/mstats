import Combine
import Foundation
import XCTest
@testable import MacStatsBar

final class StatsStoreTests: XCTestCase {
    @MainActor
    func testRefreshOncePublishesSnapshot() async {
        let expected = makeSnapshot(cpu: 12)
        let collector = SequencedStatsCollector(outputs: [.snapshot(expected)])
        let store = StatsStore(collector: collector, refreshInterval: 5)
        var published: [StatsSnapshot?] = []
        let cancellable = store.$currentSnapshot.sink { published.append($0) }

        await store.refreshOnce()

        XCTAssertEqual(store.currentSnapshot, expected)
        XCTAssertEqual(published, [nil, expected])
        _ = cancellable
    }

    @MainActor
    func testRefreshOnceOnCollectorErrorPreservesLastSnapshot() async {
        let first = makeSnapshot(cpu: 18)
        let collector = SequencedStatsCollector(outputs: [
            .snapshot(first),
            .failure(TestCollectorError.expected)
        ])
        let store = StatsStore(collector: collector, refreshInterval: 5)

        await store.refreshOnce()
        XCTAssertEqual(store.currentSnapshot, first)

        await store.refreshOnce()
        XCTAssertEqual(store.currentSnapshot, first)
    }

    @MainActor
    func testStartAndStopPollingToggleIsPolling() {
        let collector = SequencedStatsCollector(outputs: [.snapshot(makeSnapshot(cpu: 5))])
        let store = StatsStore(collector: collector, refreshInterval: 60)

        XCTAssertFalse(store.isPolling)

        store.startPolling()
        XCTAssertTrue(store.isPolling)

        store.stopPolling()
        XCTAssertFalse(store.isPolling)
    }

    private func makeSnapshot(cpu: Double) -> StatsSnapshot {
        StatsSnapshot(
            timestamp: Date(timeIntervalSince1970: 1_706_000_000),
            metrics: [
                .cpuUsage: MetricValue(primaryValue: cpu, secondaryValue: nil, unit: .percent)
            ]
        )
    }
}

private actor SequencedStatsCollector: StatsCollecting {
    enum Output {
        case snapshot(StatsSnapshot)
        case failure(any Error)
    }

    private var outputs: [Output]

    init(outputs: [Output]) {
        self.outputs = outputs
    }

    func collect() async throws -> StatsSnapshot {
        guard !outputs.isEmpty else {
            throw TestCollectorError.exhausted
        }

        let output = outputs.removeFirst()
        switch output {
        case let .snapshot(snapshot):
            return snapshot
        case let .failure(error):
            throw error
        }
    }
}

private enum TestCollectorError: Error {
    case expected
    case exhausted
}
