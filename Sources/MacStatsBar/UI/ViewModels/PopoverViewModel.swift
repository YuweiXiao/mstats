import Foundation

public struct PopoverTrendSeries: Equatable {
    public let label: String
    public let points: [Double]

    public init(label: String, points: [Double]) {
        self.label = label
        self.points = points
    }
}

public struct PopoverMetricCard: Identifiable, Equatable {
    public let kind: MetricKind
    public let title: String
    public let text: String
    public let trendSeries: [PopoverTrendSeries]

    public var id: MetricKind { kind }

    public init(kind: MetricKind, title: String, text: String, trendSeries: [PopoverTrendSeries] = []) {
        self.kind = kind
        self.title = title
        self.text = text
        self.trendSeries = trendSeries
    }
}

public struct PopoverViewModel: Equatable {
    public let cards: [PopoverMetricCard]

    private static let orderedKinds: [MetricKind] = [
        .cpuUsage,
        .memoryUsage,
        .networkThroughput,
        .batteryStatus,
        .diskUsage
    ]

    public init(snapshot: StatsSnapshot?, history: [MetricKind: [MetricHistorySample]] = [:]) {
        cards = Self.orderedKinds.map { kind in
            Self.makeCard(
                for: kind,
                snapshot: snapshot,
                history: history[kind] ?? []
            )
        }
    }

    private static func makeCard(
        for kind: MetricKind,
        snapshot: StatsSnapshot?,
        history: [MetricHistorySample]
    ) -> PopoverMetricCard {
        let metric = snapshot?.metrics[kind]

        switch kind {
        case .cpuUsage:
            return PopoverMetricCard(
                kind: .cpuUsage,
                title: "CPU",
                text: SummaryFormatter.formatCPU(metric?.primaryValue),
                trendSeries: singleTrendSeries(
                    label: "Usage",
                    samples: history,
                    keyPath: \.primary
                )
            )
        case .memoryUsage:
            return PopoverMetricCard(
                kind: .memoryUsage,
                title: "Memory",
                text: SummaryFormatter.formatMemory(
                    usedGB: metric?.primaryValue,
                    totalGB: metric?.secondaryValue
                ),
                trendSeries: singleTrendSeries(
                    label: "Used",
                    samples: history,
                    keyPath: \.primary
                )
            )
        case .networkThroughput:
            return PopoverMetricCard(
                kind: .networkThroughput,
                title: "Network",
                text: SummaryFormatter.formatNetwork(
                    downloadMBps: metric?.primaryValue,
                    uploadMBps: metric?.secondaryValue
                ),
                trendSeries: dualTrendSeries(samples: history)
            )
        case .batteryStatus:
            return PopoverMetricCard(
                kind: .batteryStatus,
                title: "Battery",
                text: SummaryFormatter.formatBattery(metric?.primaryValue),
                trendSeries: singleTrendSeries(
                    label: "Level",
                    samples: history,
                    keyPath: \.primary
                )
            )
        case .diskUsage:
            return PopoverMetricCard(
                kind: .diskUsage,
                title: "Disk",
                text: SummaryFormatter.formatDisk(
                    usedGB: metric?.primaryValue,
                    totalGB: metric?.secondaryValue
                ),
                trendSeries: singleTrendSeries(
                    label: "Used",
                    samples: history,
                    keyPath: \.primary
                )
            )
        }
    }

    private static func singleTrendSeries(
        label: String,
        samples: [MetricHistorySample],
        keyPath: KeyPath<MetricHistorySample, Double?>
    ) -> [PopoverTrendSeries] {
        let points = samples.compactMap { $0[keyPath: keyPath] }
        guard !points.isEmpty else {
            return []
        }
        return [PopoverTrendSeries(label: label, points: points)]
    }

    private static func dualTrendSeries(samples: [MetricHistorySample]) -> [PopoverTrendSeries] {
        let downPoints = samples.compactMap(\.primary)
        let upPoints = samples.compactMap(\.secondary)
        var result: [PopoverTrendSeries] = []

        if !downPoints.isEmpty {
            result.append(PopoverTrendSeries(label: "Down", points: downPoints))
        }
        if !upPoints.isEmpty {
            result.append(PopoverTrendSeries(label: "Up", points: upPoints))
        }

        return result
    }
}
