import Foundation

public struct ProcessCPUUsage: Codable, Equatable {
    public let processName: String
    public let cpuUsagePercent: Double

    public init(processName: String, cpuUsagePercent: Double) {
        self.processName = processName
        self.cpuUsagePercent = cpuUsagePercent
    }
}

public struct StatsSnapshot: Codable, Equatable {
    public let timestamp: Date
    public let metrics: [MetricKind: MetricValue]
    public let processCPUUsages: [ProcessCPUUsage]

    public init(
        timestamp: Date,
        metrics: [MetricKind: MetricValue],
        processCPUUsages: [ProcessCPUUsage] = []
    ) {
        self.timestamp = timestamp
        self.metrics = metrics
        self.processCPUUsages = processCPUUsages
    }

    private enum CodingKeys: String, CodingKey {
        case timestamp
        case metrics
        case processCPUUsages
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        metrics = try container.decode([MetricKind: MetricValue].self, forKey: .metrics)
        processCPUUsages = try container.decodeIfPresent([ProcessCPUUsage].self, forKey: .processCPUUsages) ?? []
    }
}
