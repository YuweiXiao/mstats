public struct FakeStatsCollector: StatsCollecting {
    private let snapshot: StatsSnapshot
    private let error: (any Error)?

    public init(snapshot: StatsSnapshot, error: (any Error)? = nil) {
        self.snapshot = snapshot
        self.error = error
    }

    public func collect() async throws -> StatsSnapshot {
        if let error {
            throw error
        }

        return snapshot
    }
}
