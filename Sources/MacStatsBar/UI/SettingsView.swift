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
        refreshInterval: 2,
        launchAtLoginEnabled: false,
        popoverPinBehavior: .autoClose
    )

    public init(
        summaryMetricOrder: [MetricKind],
        refreshInterval: TimeInterval,
        launchAtLoginEnabled: Bool,
        popoverPinBehavior: PopoverPinBehavior
    ) {
        self.summaryMetricOrder = summaryMetricOrder
        self.refreshInterval = refreshInterval
        self.launchAtLoginEnabled = launchAtLoginEnabled
        self.popoverPinBehavior = popoverPinBehavior
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
}

public struct SettingsView: View {
    @Binding private var settings: SettingsState

    private static let refreshIntervals: [TimeInterval] = [1, 2, 5, 10]

    public init(settings: Binding<SettingsState>) {
        _settings = settings
    }

    public var body: some View {
        Form {
            Section("Summary Order") {
                ForEach(Array(settings.summaryMetricOrder.enumerated()), id: \.offset) { index, _ in
                    Picker("Position \(index + 1)", selection: summaryMetricBinding(at: index)) {
                        ForEach(MetricKind.allCases, id: \.self) { kind in
                            Text(label(for: kind)).tag(kind)
                        }
                    }
                }
            }

            Section("Updates") {
                Picker("Refresh", selection: $settings.refreshInterval) {
                    ForEach(Self.refreshIntervals, id: \.self) { interval in
                        Text("\(Int(interval))s").tag(interval)
                    }
                }

                Toggle("Launch at Login", isOn: $settings.launchAtLoginEnabled)

                Picker("Popover", selection: $settings.popoverPinBehavior) {
                    ForEach(SettingsState.PopoverPinBehavior.allCases) { behavior in
                        Text(behavior.label).tag(behavior)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private func summaryMetricBinding(at index: Int) -> Binding<MetricKind> {
        Binding(
            get: {
                guard settings.summaryMetricOrder.indices.contains(index) else {
                    return .cpuUsage
                }

                return settings.summaryMetricOrder[index]
            },
            set: { newValue in
                guard settings.summaryMetricOrder.indices.contains(index) else {
                    return
                }

                settings.updateSummaryMetric(at: index, to: newValue)
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
