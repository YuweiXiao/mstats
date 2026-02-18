import AppKit

public final class StatusBarController {
    private static let fallbackSummaryText = "--"
    private static let menuBarMaxVisibleMetrics = 2

    private let statusItem: NSStatusItem

    public init(
        statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    ) {
        self.statusItem = statusItem
        statusItem.button?.title = Self.fallbackSummaryText
    }

    func renderSummary(snapshot: StatsSnapshot?, preferences: UserPreferences) {
        statusItem.button?.title = Self.summaryText(snapshot: snapshot, preferences: preferences)
    }

    static func summaryText(snapshot: StatsSnapshot?, preferences: UserPreferences) -> String {
        let maxVisible = min(
            menuBarMaxVisibleMetrics,
            max(0, preferences.maxVisibleSummaryItems)
        )
        let metricKinds = SummarySelectionEngine.visibleMetrics(
            order: preferences.summaryMetricOrder,
            maxVisible: maxVisible
        )

        let parts = metricKinds.map { metricKind in
            format(metricKind: metricKind, snapshot: snapshot)
        }

        guard !parts.isEmpty else {
            return fallbackSummaryText
        }

        return parts.joined(separator: " | ")
    }

    private static func format(metricKind: MetricKind, snapshot: StatsSnapshot?) -> String {
        let metric = snapshot?.metrics[metricKind]

        switch metricKind {
        case .cpuUsage:
            return SummaryFormatter.formatCPU(metric?.primaryValue)
        case .memoryUsage:
            return SummaryFormatter.formatMemory(
                usedGB: metric?.primaryValue,
                totalGB: metric?.secondaryValue
            )
        case .networkThroughput:
            return SummaryFormatter.formatNetwork(
                downloadMBps: metric?.primaryValue,
                uploadMBps: metric?.secondaryValue
            )
        case .batteryStatus:
            let formatted = SummaryFormatter.formatCPU(metric?.primaryValue)
            return formatted.replacingOccurrences(of: "CPU", with: "BAT")
        case .diskUsage:
            let formatted = SummaryFormatter.formatMemory(
                usedGB: metric?.primaryValue,
                totalGB: metric?.secondaryValue
            )
            return formatted.replacingOccurrences(of: "MEM", with: "DSK")
        }
    }
}
