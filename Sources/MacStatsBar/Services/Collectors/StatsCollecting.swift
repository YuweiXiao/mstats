public protocol StatsCollecting {
    func collect() async throws -> StatsSnapshot
}
