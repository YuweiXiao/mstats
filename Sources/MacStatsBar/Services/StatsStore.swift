import Combine
import Foundation

@MainActor
public final class StatsStore: ObservableObject {
    @Published public private(set) var currentSnapshot: StatsSnapshot?
    @Published public private(set) var isPolling = false

    private static let minimumRefreshInterval: TimeInterval = 0.05

    private let collector: any StatsCollecting
    private var refreshInterval: TimeInterval
    private var pollingTask: Task<Void, Never>?
    private var pollingSessionID = UUID()
    private var isRefreshing = false
    private var rawNetworkBaseline: RawNetworkSample?
    private var shouldResumePollingAfterWake = false

    public init(
        collector: any StatsCollecting,
        refreshInterval: TimeInterval
    ) {
        self.collector = collector
        self.refreshInterval = refreshInterval
    }

    public func refreshOnce() async {
        await refreshOnceIfNeeded(shouldPublish: { true })
    }

    private func refreshOnceIfNeeded(shouldPublish: @escaping @MainActor () -> Bool) async {
        guard !isRefreshing else {
            return
        }

        isRefreshing = true
        defer {
            isRefreshing = false
        }

        do {
            let snapshot = try await collector.collect()
            guard shouldPublish() else {
                return
            }
            let snapshotWithDerivedNetwork = snapshotByDerivingNetworkThroughput(from: snapshot)
            currentSnapshot = snapshotWithDerivedNetwork
        } catch {
            // Keep currentSnapshot unchanged when collection fails.
        }
    }

    public func startPolling() {
        guard !isPolling else {
            return
        }

        isPolling = true
        startNewPollingSession()
    }

    public func updateRefreshInterval(_ refreshInterval: TimeInterval) {
        self.refreshInterval = refreshInterval
        guard isPolling else {
            return
        }
        startNewPollingSession()
    }

    private func startNewPollingSession() {
        pollingTask?.cancel()
        let sessionID = UUID()
        pollingSessionID = sessionID
        pollingTask = Task { [weak self] in
            await self?.pollLoop(sessionID: sessionID)
        }
    }

    public func stopPolling() {
        stopPolling(clearWakeResumeIntent: true)
    }

    private func stopPollingForSleepTransition() {
        stopPolling(clearWakeResumeIntent: false)
    }

    private func stopPolling(clearWakeResumeIntent: Bool) {
        isPolling = false
        if clearWakeResumeIntent {
            shouldResumePollingAfterWake = false
        }
        pollingSessionID = UUID()
        pollingTask?.cancel()
        pollingTask = nil
    }

    public func handleWillSleep() {
        shouldResumePollingAfterWake = isPolling
        stopPollingForSleepTransition()
    }

    public func handleDidWake() {
        guard shouldResumePollingAfterWake else {
            return
        }

        shouldResumePollingAfterWake = false
        startPolling()
    }

    deinit {
        pollingTask?.cancel()
    }

    private func pollLoop(sessionID: UUID) async {
        while !Task.isCancelled && isPollingSessionActive(sessionID) {
            await refreshOnceIfNeeded(shouldPublish: { [sessionID] in
                !Task.isCancelled && self.isPollingSessionActive(sessionID)
            })

            if Task.isCancelled || !isPollingSessionActive(sessionID) {
                break
            }

            await sleepForRefreshInterval()
        }
    }

    private func sleepForRefreshInterval() async {
        let normalizedInterval = max(refreshInterval, Self.minimumRefreshInterval)
        let nanoseconds = UInt64((normalizedInterval * 1_000_000_000).rounded())
        try? await Task.sleep(nanoseconds: nanoseconds)
    }

    private func isPollingSessionActive(_ sessionID: UUID) -> Bool {
        isPolling && pollingSessionID == sessionID
    }

    private func snapshotByDerivingNetworkThroughput(from incoming: StatsSnapshot) -> StatsSnapshot {
        guard let incomingSample = rawNetworkSample(from: incoming) else {
            rawNetworkBaseline = nil
            return incoming
        }

        defer {
            rawNetworkBaseline = incomingSample
        }

        guard
            let previousSample = rawNetworkBaseline,
            previousSample.unit == incomingSample.unit
        else {
            return replacingNetworkMetric(
                in: incoming,
                download: 0,
                upload: 0,
                unit: incomingSample.unit
            )
        }

        let elapsedSeconds = incomingSample.timestamp.timeIntervalSince(previousSample.timestamp)
        guard elapsedSeconds.isFinite, elapsedSeconds > 0 else {
            return replacingNetworkMetric(
                in: incoming,
                download: 0,
                upload: 0,
                unit: incomingSample.unit
            )
        }

        let downloadDelta = incomingSample.downloadCounter - previousSample.downloadCounter
        let uploadDelta = incomingSample.uploadCounter - previousSample.uploadCounter
        guard
            downloadDelta.isFinite,
            uploadDelta.isFinite,
            downloadDelta >= 0,
            uploadDelta >= 0
        else {
            return replacingNetworkMetric(
                in: incoming,
                download: 0,
                upload: 0,
                unit: incomingSample.unit
            )
        }

        let downloadRate = downloadDelta / elapsedSeconds
        let uploadRate = uploadDelta / elapsedSeconds
        guard downloadRate.isFinite, uploadRate.isFinite else {
            return replacingNetworkMetric(
                in: incoming,
                download: 0,
                upload: 0,
                unit: incomingSample.unit
            )
        }

        return replacingNetworkMetric(
            in: incoming,
            download: downloadRate,
            upload: uploadRate,
            unit: incomingSample.unit
        )
    }

    private func rawNetworkSample(from snapshot: StatsSnapshot) -> RawNetworkSample? {
        guard
            let networkMetric = snapshot.metrics[.networkThroughput],
            let uploadCounter = networkMetric.secondaryValue,
            networkMetric.primaryValue.isFinite,
            uploadCounter.isFinite,
            networkMetric.primaryValue >= 0,
            uploadCounter >= 0
        else {
            return nil
        }

        return RawNetworkSample(
            timestamp: snapshot.timestamp,
            downloadCounter: networkMetric.primaryValue,
            uploadCounter: uploadCounter,
            unit: networkMetric.unit
        )
    }

    private func replacingNetworkMetric(
        in snapshot: StatsSnapshot,
        download: Double,
        upload: Double,
        unit: MetricValue.Unit
    ) -> StatsSnapshot {
        var metrics = snapshot.metrics
        metrics[.networkThroughput] = MetricValue(
            primaryValue: download,
            secondaryValue: upload,
            unit: unit
        )
        return StatsSnapshot(
            timestamp: snapshot.timestamp,
            metrics: metrics,
            processCPUUsages: snapshot.processCPUUsages
        )
    }
}

private struct RawNetworkSample {
    let timestamp: Date
    let downloadCounter: Double
    let uploadCounter: Double
    let unit: MetricValue.Unit
}
