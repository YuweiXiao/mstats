import Foundation

public struct MetricHistorySample: Equatable {
    public let timestamp: Date
    public let primary: Double?
    public let secondary: Double?

    public init(timestamp: Date = Date(), primary: Double?, secondary: Double?) {
        self.timestamp = timestamp
        self.primary = primary
        self.secondary = secondary
    }
}

public struct MetricHistoryStore {
    public static let defaultRetentionWindow: TimeInterval = 15 * 60

    public private(set) var history: [MetricKind: [MetricHistorySample]] = [:]
    private let maxSamples: Int
    private let retentionWindow: TimeInterval

    public init(
        maxSamples: Int = .max,
        retentionWindow: TimeInterval = MetricHistoryStore.defaultRetentionWindow
    ) {
        self.maxSamples = max(1, maxSamples)
        self.retentionWindow = max(0, retentionWindow)
    }

    public mutating func append(snapshot: StatsSnapshot?) {
        guard let snapshot else {
            return
        }

        for (kind, metric) in snapshot.metrics {
            append(
                kind: kind,
                primary: metric.primaryValue,
                secondary: metric.secondaryValue,
                timestamp: snapshot.timestamp
            )
        }
    }

    public mutating func append(
        kind: MetricKind,
        primary: Double?,
        secondary: Double?,
        timestamp: Date = Date()
    ) {
        let sample = MetricHistorySample(
            timestamp: timestamp,
            primary: Self.normalized(primary),
            secondary: Self.normalized(secondary)
        )
        var samples = history[kind] ?? []
        samples.append(sample)
        pruneStaleSamples(&samples)

        if samples.count > maxSamples {
            samples.removeFirst(samples.count - maxSamples)
        }

        history[kind] = samples
    }

    private static func normalized(_ value: Double?) -> Double? {
        guard let value, value.isFinite else {
            return nil
        }
        return value
    }

    private func pruneStaleSamples(_ samples: inout [MetricHistorySample]) {
        guard samples.count > 1 else {
            return
        }

        let newestTimestamp = samples.map(\.timestamp).max() ?? Date()
        let cutoff = newestTimestamp.addingTimeInterval(-retentionWindow)
        samples.removeAll { $0.timestamp < cutoff }
    }
}
