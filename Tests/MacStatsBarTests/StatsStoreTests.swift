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
    func testRefreshOnceOnCollectorErrorWithNoExistingSnapshotKeepsNil() async {
        let collector = SequencedStatsCollector(outputs: [.failure(TestCollectorError.expected)])
        let store = StatsStore(collector: collector, refreshInterval: 5)

        await store.refreshOnce()

        XCTAssertNil(store.currentSnapshot)
    }

    @MainActor
    func testRefreshOnceDerivesNetworkThroughputFromConsecutiveSnapshots() async {
        let first = makeNetworkCounterSnapshot(
            timestamp: Date(timeIntervalSince1970: 1_706_000_000),
            downloadCounter: 100,
            uploadCounter: 40
        )
        let second = makeNetworkCounterSnapshot(
            timestamp: Date(timeIntervalSince1970: 1_706_000_002),
            downloadCounter: 106,
            uploadCounter: 44
        )

        let collector = SequencedStatsCollector(outputs: [.snapshot(first), .snapshot(second)])
        let store = StatsStore(collector: collector, refreshInterval: 5)

        await store.refreshOnce()
        await store.refreshOnce()

        let networkMetric = store.currentSnapshot?.metrics[.networkThroughput]
        XCTAssertNotNil(networkMetric)
        XCTAssertNotNil(networkMetric?.secondaryValue)
        XCTAssertEqual(networkMetric?.primaryValue ?? .nan, 3, accuracy: 0.0001)
        XCTAssertEqual(networkMetric?.secondaryValue ?? .nan, 2, accuracy: 0.0001)
        XCTAssertEqual(networkMetric?.unit, .megabytesPerSecond)
    }

    @MainActor
    func testRefreshOnceDerivesStableNetworkRateAcrossThreeCounterSamples() async {
        let first = makeNetworkCounterSnapshot(
            timestamp: Date(timeIntervalSince1970: 1_706_000_000),
            downloadCounter: 100,
            uploadCounter: 40
        )
        let second = makeNetworkCounterSnapshot(
            timestamp: Date(timeIntervalSince1970: 1_706_000_002),
            downloadCounter: 106,
            uploadCounter: 44
        )
        let third = makeNetworkCounterSnapshot(
            timestamp: Date(timeIntervalSince1970: 1_706_000_004),
            downloadCounter: 112,
            uploadCounter: 48
        )

        let collector = SequencedStatsCollector(outputs: [.snapshot(first), .snapshot(second), .snapshot(third)])
        let store = StatsStore(collector: collector, refreshInterval: 5)

        await store.refreshOnce()
        await store.refreshOnce()
        let secondNetwork = store.currentSnapshot?.metrics[.networkThroughput]
        await store.refreshOnce()
        let thirdNetwork = store.currentSnapshot?.metrics[.networkThroughput]

        XCTAssertEqual(secondNetwork?.primaryValue ?? .nan, 3, accuracy: 0.0001)
        XCTAssertEqual(secondNetwork?.secondaryValue ?? .nan, 2, accuracy: 0.0001)
        XCTAssertEqual(thirdNetwork?.primaryValue ?? .nan, 3, accuracy: 0.0001)
        XCTAssertEqual(thirdNetwork?.secondaryValue ?? .nan, 2, accuracy: 0.0001)
    }

    @MainActor
    func testRefreshOnceDerivesNetworkRateFromCounterDeltaNotRawCounterValue() async {
        let first = makeNetworkCounterSnapshot(
            timestamp: Date(timeIntervalSince1970: 1_706_000_000),
            downloadCounter: 10_000,
            uploadCounter: 5_000
        )
        let second = makeNetworkCounterSnapshot(
            timestamp: Date(timeIntervalSince1970: 1_706_000_005),
            downloadCounter: 10_010,
            uploadCounter: 5_015
        )

        let collector = SequencedStatsCollector(outputs: [.snapshot(first), .snapshot(second)])
        let store = StatsStore(collector: collector, refreshInterval: 5)

        await store.refreshOnce()
        await store.refreshOnce()

        let networkMetric = store.currentSnapshot?.metrics[.networkThroughput]
        XCTAssertNotNil(networkMetric)
        XCTAssertEqual(networkMetric?.primaryValue ?? .nan, 2, accuracy: 0.0001)
        XCTAssertEqual(networkMetric?.secondaryValue ?? .nan, 3, accuracy: 0.0001)
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

    @MainActor
    func testStartPollingRefreshesRepeatedlyWhileRunning() async {
        let collector = CountingStatsCollector()
        let store = StatsStore(collector: collector, refreshInterval: 0.05)

        store.startPolling()
        let reachedThreeCalls = await eventually(timeoutNanoseconds: 1_000_000_000) {
            await collector.readCallCount() >= 3
        }
        store.stopPolling()
        let finalCount = await collector.readCallCount()

        XCTAssertTrue(reachedThreeCalls)
        XCTAssertGreaterThanOrEqual(finalCount, 3)
    }

    @MainActor
    func testStopPollingPreventsLatePublishFromInFlightCollect() async {
        let collectStarted = expectation(description: "collect started")
        let snapshot = makeSnapshot(cpu: 73)
        let collector = BlockingFirstCollectStatsCollector(
            snapshot: snapshot,
            onFirstCollectStart: { collectStarted.fulfill() }
        )
        let store = StatsStore(collector: collector, refreshInterval: 1)

        store.startPolling()
        await fulfillment(of: [collectStarted], timeout: 1)
        store.stopPolling()
        await collector.unblockFirstCollect()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNil(store.currentSnapshot)
    }

    @MainActor
    func testNonPositiveIntervalUsesMinimumDelayAndAvoidsTightSpin() async {
        let collector = CountingStatsCollector()
        let store = StatsStore(collector: collector, refreshInterval: 0)

        store.startPolling()
        try? await Task.sleep(nanoseconds: 120_000_000)
        store.stopPolling()

        let callCount = await collector.readCallCount()
        XCTAssertGreaterThanOrEqual(callCount, 1)
        XCTAssertLessThanOrEqual(callCount, 4)
    }

    @MainActor
    func testRefreshOnceDoesNotStartSecondCollectWhileCollectInFlight() async {
        let collectStarted = expectation(description: "first collect started")
        let collector = BlockingFirstCollectStatsCollector(
            snapshot: makeSnapshot(cpu: 33),
            onFirstCollectStart: { collectStarted.fulfill() }
        )
        let store = StatsStore(collector: collector, refreshInterval: 60)

        let firstRefresh = Task { await store.refreshOnce() }
        await fulfillment(of: [collectStarted], timeout: 1)

        let secondRefresh = Task { await store.refreshOnce() }
        try? await Task.sleep(nanoseconds: 50_000_000)
        let countWhileBlocked = await collector.readCallCount()

        XCTAssertEqual(countWhileBlocked, 1)
        await collector.unblockFirstCollect()
        await firstRefresh.value
        await secondRefresh.value
        let finalCount = await collector.readCallCount()
        XCTAssertEqual(finalCount, 1)
    }

    private func makeSnapshot(cpu: Double) -> StatsSnapshot {
        StatsSnapshot(
            timestamp: Date(timeIntervalSince1970: 1_706_000_000),
            metrics: [
                .cpuUsage: MetricValue(primaryValue: cpu, secondaryValue: nil, unit: .percent)
            ]
        )
    }

    private func makeNetworkCounterSnapshot(
        timestamp: Date,
        downloadCounter: Double,
        uploadCounter: Double
    ) -> StatsSnapshot {
        StatsSnapshot(
            timestamp: timestamp,
            metrics: [
                .networkThroughput: MetricValue(
                    primaryValue: downloadCounter,
                    secondaryValue: uploadCounter,
                    unit: .megabytesPerSecond
                )
            ]
        )
    }

    private func eventually(
        timeoutNanoseconds: UInt64,
        pollNanoseconds: UInt64 = 10_000_000,
        condition: @escaping @Sendable () async -> Bool
    ) async -> Bool {
        let started = ContinuousClock.now
        while started.duration(to: ContinuousClock.now) < .nanoseconds(Int64(timeoutNanoseconds)) {
            if await condition() {
                return true
            }
            try? await Task.sleep(nanoseconds: pollNanoseconds)
        }
        return false
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

private actor CountingStatsCollector: StatsCollecting {
    private var callCount = 0

    func collect() async throws -> StatsSnapshot {
        callCount += 1
        return StatsSnapshot(
            timestamp: Date(timeIntervalSince1970: 1_706_000_000 + TimeInterval(callCount)),
            metrics: [
                .cpuUsage: MetricValue(primaryValue: Double(callCount), secondaryValue: nil, unit: .percent)
            ]
        )
    }

    func readCallCount() -> Int {
        callCount
    }
}

private actor BlockingFirstCollectStatsCollector: StatsCollecting {
    private let snapshot: StatsSnapshot
    private let onFirstCollectStart: @Sendable () -> Void

    private var callCount = 0
    private var isFirstCollectReleased = false
    private var firstCollectContinuation: CheckedContinuation<Void, Never>?

    init(snapshot: StatsSnapshot, onFirstCollectStart: @escaping @Sendable () -> Void) {
        self.snapshot = snapshot
        self.onFirstCollectStart = onFirstCollectStart
    }

    func collect() async throws -> StatsSnapshot {
        callCount += 1
        if callCount == 1 {
            onFirstCollectStart()
            if !isFirstCollectReleased {
                await withCheckedContinuation { continuation in
                    firstCollectContinuation = continuation
                }
            }
        }
        return snapshot
    }

    func unblockFirstCollect() {
        isFirstCollectReleased = true
        firstCollectContinuation?.resume()
        firstCollectContinuation = nil
    }

    func readCallCount() -> Int {
        callCount
    }
}
