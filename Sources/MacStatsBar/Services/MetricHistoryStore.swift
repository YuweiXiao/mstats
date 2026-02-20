import Foundation

public struct MetricHistorySample: Equatable {
    public let primary: Double?
    public let secondary: Double?

    public init(primary: Double?, secondary: Double?) {
        self.primary = primary
        self.secondary = secondary
    }
}

public struct MetricHistoryStore {
    public private(set) var history: [MetricKind: [MetricHistorySample]] = [:]
    private let maxSamples: Int

    public init(maxSamples: Int = 60) {
        self.maxSamples = max(1, maxSamples)
    }

    public mutating func append(snapshot: StatsSnapshot?) {
        guard let snapshot else {
            return
        }

        for (kind, metric) in snapshot.metrics {
            append(
                kind: kind,
                primary: metric.primaryValue,
                secondary: metric.secondaryValue
            )
        }
    }

    public mutating func append(kind: MetricKind, primary: Double?, secondary: Double?) {
        let sample = MetricHistorySample(
            primary: Self.normalized(primary),
            secondary: Self.normalized(secondary)
        )
        var samples = history[kind] ?? []
        samples.append(sample)

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
}
