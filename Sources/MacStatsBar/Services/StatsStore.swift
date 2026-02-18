import Combine
import Foundation

@MainActor
public final class StatsStore: ObservableObject {
    @Published public private(set) var currentSnapshot: StatsSnapshot?
    @Published public private(set) var isPolling = false

    private static let minimumRefreshInterval: TimeInterval = 0.05

    private let collector: any StatsCollecting
    private let refreshInterval: TimeInterval
    private var pollingTask: Task<Void, Never>?
    private var pollingSessionID = UUID()
    private var isRefreshing = false

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
            currentSnapshot = snapshot
        } catch {
            // Keep currentSnapshot unchanged when collection fails.
        }
    }

    public func startPolling() {
        guard !isPolling else {
            return
        }

        isPolling = true
        let sessionID = UUID()
        pollingSessionID = sessionID
        pollingTask = Task { [weak self] in
            await self?.pollLoop(sessionID: sessionID)
        }
    }

    public func stopPolling() {
        isPolling = false
        pollingSessionID = UUID()
        pollingTask?.cancel()
        pollingTask = nil
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
}
