import Foundation

public struct PopoverMetricCard: Identifiable, Equatable {
    public let kind: MetricKind
    public let title: String
    public let text: String

    public var id: MetricKind { kind }

    public init(kind: MetricKind, title: String, text: String) {
        self.kind = kind
        self.title = title
        self.text = text
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

    public init(snapshot: StatsSnapshot?) {
        cards = Self.orderedKinds.map { kind in
            Self.makeCard(for: kind, snapshot: snapshot)
        }
    }

    private static func makeCard(for kind: MetricKind, snapshot: StatsSnapshot?) -> PopoverMetricCard {
        let metric = snapshot?.metrics[kind]

        switch kind {
        case .cpuUsage:
            return PopoverMetricCard(
                kind: .cpuUsage,
                title: "CPU",
                text: SummaryFormatter.formatCPU(metric?.primaryValue)
            )
        case .memoryUsage:
            return PopoverMetricCard(
                kind: .memoryUsage,
                title: "Memory",
                text: SummaryFormatter.formatMemory(
                    usedGB: metric?.primaryValue,
                    totalGB: metric?.secondaryValue
                )
            )
        case .networkThroughput:
            return PopoverMetricCard(
                kind: .networkThroughput,
                title: "Network",
                text: SummaryFormatter.formatNetwork(
                    downloadMBps: metric?.primaryValue,
                    uploadMBps: metric?.secondaryValue
                )
            )
        case .batteryStatus:
            return PopoverMetricCard(
                kind: .batteryStatus,
                title: "Battery",
                text: SummaryFormatter.formatBattery(metric?.primaryValue)
            )
        case .diskUsage:
            return PopoverMetricCard(
                kind: .diskUsage,
                title: "Disk",
                text: SummaryFormatter.formatDisk(
                    usedGB: metric?.primaryValue,
                    totalGB: metric?.secondaryValue
                )
            )
        }
    }
}
