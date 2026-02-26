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

public struct PopoverTopCPUProcess: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let cpuUsagePercent: Double

    public init(id: String, name: String, cpuUsagePercent: Double) {
        self.id = id
        self.name = name
        self.cpuUsagePercent = cpuUsagePercent
    }

    public init(name: String, cpuUsagePercent: Double) {
        self.init(id: name, name: name, cpuUsagePercent: cpuUsagePercent)
    }
}

public struct PopoverViewModel: Equatable {
    public let cards: [PopoverMetricCard]
    public let topCPUProcesses: [PopoverTopCPUProcess]
    private static let processListMinimumCPUPercent = 1.0
    private static let processListMaximumCount = 10

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
        topCPUProcesses = Self.makeTopCPUProcesses(from: snapshot?.processCPUUsages ?? [])
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
                text: cpuCardText(metric?.primaryValue),
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

    private static func cpuCardText(_ percent: Double?) -> String {
        let formatted = SummaryFormatter.formatCPU(percent)
        if formatted.hasPrefix("CPU ") {
            return String(formatted.dropFirst(4))
        }
        return formatted
    }

    private static func makeTopCPUProcesses(from processUsages: [ProcessCPUUsage]) -> [PopoverTopCPUProcess] {
        processUsages
            .enumerated()
            .filter { $0.element.cpuUsagePercent.isFinite && $0.element.cpuUsagePercent >= processListMinimumCPUPercent }
            .sorted {
                if $0.element.cpuUsagePercent == $1.element.cpuUsagePercent {
                    let nameOrder = $0.element.processName.localizedCaseInsensitiveCompare($1.element.processName)
                    if nameOrder == .orderedSame {
                        return $0.offset < $1.offset
                    }
                    return nameOrder == .orderedAscending
                }
                return $0.element.cpuUsagePercent > $1.element.cpuUsagePercent
            }
            .prefix(processListMaximumCount)
            .enumerated()
            .map { rank, indexedProcess in
                let sourceIndex = indexedProcess.offset
                let process = indexedProcess.element
                return PopoverTopCPUProcess(
                    id: "cpu-top-\(rank)-\(sourceIndex)",
                    name: process.processName,
                    cpuUsagePercent: process.cpuUsagePercent
                )
            }
    }
}
