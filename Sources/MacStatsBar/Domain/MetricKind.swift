public enum MetricKind: String, Codable, CaseIterable, Equatable {
    case cpuUsage
    case memoryUsage
    case networkThroughput
    case batteryStatus
    case diskUsage
}
