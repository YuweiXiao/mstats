import Foundation

public struct StatsSnapshot: Codable, Equatable {
    public let timestamp: Date
    public let metrics: [MetricKind: MetricValue]

    public init(timestamp: Date, metrics: [MetricKind: MetricValue]) {
        self.timestamp = timestamp
        self.metrics = metrics
    }
}
