public struct FakeStatsCollector: StatsCollecting {
    private enum Output {
        case snapshot(StatsSnapshot)
        case error(any Error)
    }

    private let output: Output

    public init(snapshot: StatsSnapshot) {
        output = .snapshot(snapshot)
    }

    public init(error: any Error) {
        output = .error(error)
    }

    public func collect() async throws -> StatsSnapshot {
        switch output {
        case let .snapshot(snapshot):
            return snapshot
        case let .error(error):
            throw error
        }
    }
}
