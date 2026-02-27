import SwiftUI

public struct SettingsState: Equatable {
    public enum PopoverPinBehavior: String, CaseIterable, Equatable, Identifiable {
        case autoClose
        case pinned

        public var id: String { rawValue }

        var label: String {
            switch self {
            case .autoClose:
                return "Auto-close"
            case .pinned:
                return "Pinned"
            }
        }
    }

    public var summaryMetricOrder: [MetricKind]
    public var showSecondaryMetric: Bool
    public var refreshInterval: TimeInterval
    public var launchAtLoginEnabled: Bool
    public var popoverPinBehavior: PopoverPinBehavior

    public static let defaultValue = SettingsState(
        summaryMetricOrder: [
            .cpuUsage,
            .memoryUsage,
            .networkThroughput,
            .batteryStatus,
            .diskUsage
        ],
        showSecondaryMetric: true,
        refreshInterval: 5,
        launchAtLoginEnabled: false,
        popoverPinBehavior: .autoClose
    )

    public init(
        summaryMetricOrder: [MetricKind],
        showSecondaryMetric: Bool = true,
        refreshInterval: TimeInterval,
        launchAtLoginEnabled: Bool,
        popoverPinBehavior: PopoverPinBehavior
    ) {
        self.summaryMetricOrder = Self.normalizedSummaryMetricOrder(summaryMetricOrder)
        self.showSecondaryMetric = showSecondaryMetric
        self.refreshInterval = refreshInterval
        self.launchAtLoginEnabled = launchAtLoginEnabled
        self.popoverPinBehavior = popoverPinBehavior
    }

    public var primaryStatusMetric: MetricKind {
        get {
            summaryMetricOrder.first ?? .cpuUsage
        }
        set {
            updateSummaryMetric(at: 0, to: newValue)
        }
    }

    public var secondaryStatusMetric: MetricKind? {
        get {
            guard showSecondaryMetric, summaryMetricOrder.indices.contains(1) else {
                return nil
            }
            return summaryMetricOrder[1]
        }
        set {
            guard let newValue else {
                showSecondaryMetric = false
                return
            }
            showSecondaryMetric = true
            updateSummaryMetric(at: 1, to: newValue)
        }
    }

    public mutating func updateSummaryMetric(at index: Int, to newValue: MetricKind) {
        guard summaryMetricOrder.indices.contains(index) else {
            return
        }

        if summaryMetricOrder[index] == newValue {
            return
        }

        if let duplicateIndex = summaryMetricOrder.firstIndex(of: newValue), duplicateIndex != index {
            summaryMetricOrder.swapAt(index, duplicateIndex)
            return
        }

        summaryMetricOrder[index] = newValue
    }

    private static func normalizedSummaryMetricOrder(_ input: [MetricKind]) -> [MetricKind] {
        var ordered: [MetricKind] = []
        for metric in input where !ordered.contains(metric) {
            ordered.append(metric)
        }
        for metric in MetricKind.allCases where !ordered.contains(metric) {
            ordered.append(metric)
        }
        return ordered
    }
}

public struct SettingsView: View {
    @Binding private var settings: SettingsState

    public init(settings: Binding<SettingsState>) {
        _settings = settings
    }

    public var body: some View {
        Form {
            Section("Status Bar Metrics") {
                Text("Only Primary and optional Secondary are shown in the menu bar.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Picker("Primary", selection: primaryMetricBinding) {
                    ForEach(MetricKind.allCases, id: \.self) { kind in
                        Text(label(for: kind)).tag(kind)
                    }
                }

                Picker("Secondary", selection: secondaryMetricBinding) {
                    Text("None").tag(Optional<MetricKind>.none)
                    ForEach(MetricKind.allCases.filter { $0 != settings.primaryStatusMetric }, id: \.self) { kind in
                        Text(label(for: kind)).tag(Optional(kind))
                    }
                }
            }
            Toggle("Launch at Login", isOn: $settings.launchAtLoginEnabled)
        }
    }

    private var primaryMetricBinding: Binding<MetricKind> {
        Binding(
            get: { settings.primaryStatusMetric },
            set: { newValue in
                settings.primaryStatusMetric = newValue
            }
        )
    }

    private var secondaryMetricBinding: Binding<MetricKind?> {
        Binding(
            get: { settings.secondaryStatusMetric },
            set: { newValue in
                settings.secondaryStatusMetric = newValue
            }
        )
    }

    private func label(for kind: MetricKind) -> String {
        switch kind {
        case .cpuUsage:
            return "CPU"
        case .memoryUsage:
            return "Memory"
        case .networkThroughput:
            return "Network"
        case .batteryStatus:
            return "Battery"
        case .diskUsage:
            return "Disk"
        }
    }
}
