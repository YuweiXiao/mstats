import Combine
import Foundation

@MainActor
public final class StatsStore: ObservableObject {
    @Published public private(set) var currentSnapshot: StatsSnapshot?
    @Published public private(set) var isPolling = false

    private let collector: any StatsCollecting
    private let refreshInterval: TimeInterval
    private var pollingTask: Task<Void, Never>?

    public init(
        collector: any StatsCollecting,
        refreshInterval: TimeInterval
    ) {
        self.collector = collector
        self.refreshInterval = refreshInterval
    }

    public func refreshOnce() async {
        do {
            let snapshot = try await collector.collect()
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
        pollingTask = Task { [weak self] in
            await self?.pollLoop()
        }
    }

    public func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        isPolling = false
    }

    deinit {
        pollingTask?.cancel()
    }

    private func pollLoop() async {
        while !Task.isCancelled {
            await refreshOnce()

            if Task.isCancelled {
                break
            }

            await sleepForRefreshInterval()
        }
    }

    private func sleepForRefreshInterval() async {
        let positiveInterval = max(refreshInterval, 0)
        guard positiveInterval > 0 else {
            await Task.yield()
            return
        }

        let nanoseconds = UInt64(positiveInterval * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
    }
}
