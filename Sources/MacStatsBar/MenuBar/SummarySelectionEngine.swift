public enum SummarySelectionEngine {
    public static let defaultMaxVisible = 2

    public static func visibleMetrics(
        order: [MetricKind],
        maxVisible: Int = defaultMaxVisible
    ) -> [MetricKind] {
        guard maxVisible > 0 else {
            return []
        }

        return Array(order.prefix(maxVisible))
    }
}
