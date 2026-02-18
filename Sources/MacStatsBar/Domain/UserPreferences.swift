public struct UserPreferences: Codable, Equatable {
    public static let defaultValue = UserPreferences(
        summaryMetricOrder: [
            .cpuUsage,
            .memoryUsage,
            .networkThroughput,
            .batteryStatus,
            .diskUsage
        ],
        maxVisibleSummaryItems: 2
    )

    public let summaryMetricOrder: [MetricKind]
    public let maxVisibleSummaryItems: Int

    public var visibleSummaryMetrics: [MetricKind] {
        let cappedCount = max(0, maxVisibleSummaryItems)
        return Array(summaryMetricOrder.prefix(cappedCount))
    }

    public init(summaryMetricOrder: [MetricKind], maxVisibleSummaryItems: Int) {
        self.summaryMetricOrder = summaryMetricOrder
        self.maxVisibleSummaryItems = maxVisibleSummaryItems
    }
}
