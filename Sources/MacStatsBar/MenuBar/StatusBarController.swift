import AppKit
import SwiftUI

public protocol ApplicationTerminating {
    func terminate(_ sender: Any?)
}

extension NSApplication: ApplicationTerminating {}

public final class StatusBarController: NSObject {
    private static let fallbackSummaryText = "--"
    private static let menuBarMaxVisibleMetrics = 2
    private static let singleMetricStatusLength: CGFloat = 48
    private static let dualMetricStatusLength: CGFloat = 92

    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let onSettingsChanged: (SettingsState) -> Void
    private let appTerminator: any ApplicationTerminating
    private var popoverSnapshot: StatsSnapshot?
    private var popoverSettings: SettingsState

    public init(
        statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength),
        initialSettings: SettingsState = .defaultValue,
        onSettingsChanged: @escaping (SettingsState) -> Void = { _ in },
        popover: NSPopover = NSPopover(),
        appTerminator: any ApplicationTerminating = NSApplication.shared
    ) {
        self.popover = popover
        self.onSettingsChanged = onSettingsChanged
        self.appTerminator = appTerminator
        self.popoverSettings = initialSettings
        self.statusItem = statusItem
        super.init()

        statusItem.button?.title = Self.fallbackSummaryText
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover(_:))

        self.popover.behavior = Self.popoverBehavior(for: initialSettings.popoverPinBehavior)
        self.popover.animates = true
        self.popover.contentSize = NSSize(width: 340, height: 420)
        refreshPopoverContent()
    }

    func renderSummary(snapshot: StatsSnapshot?, preferences: UserPreferences) {
        let text = Self.summaryText(snapshot: snapshot, preferences: preferences)
        let visibleCount = Self.visibleMetricCount(preferences: preferences)
        statusItem.length = visibleCount > 1 ? Self.dualMetricStatusLength : Self.singleMetricStatusLength

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        ]
        statusItem.button?.attributedTitle = NSAttributedString(string: text, attributes: attributes)
    }

    func updatePopover(snapshot: StatsSnapshot?, settings: SettingsState) {
        popoverSnapshot = snapshot
        popoverSettings = settings
        popover.behavior = Self.popoverBehavior(for: settings.popoverPinBehavior)
        refreshPopoverContent()
    }

    static func popoverBehavior(for behavior: SettingsState.PopoverPinBehavior) -> NSPopover.Behavior {
        switch behavior {
        case .autoClose:
            return .transient
        case .pinned:
            return .applicationDefined
        }
    }

    static func summaryText(snapshot: StatsSnapshot?, preferences: UserPreferences) -> String {
        let metricKinds = visibleMetricKinds(preferences: preferences)

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
            return SummaryFormatter.compactPercentValue(metric?.primaryValue)
        case .memoryUsage:
            return SummaryFormatter.compactPairValue(
                first: metric?.primaryValue,
                second: metric?.secondaryValue,
                suffix: "G"
            )
        case .networkThroughput:
            return SummaryFormatter.compactNetworkValue(
                downloadMBps: metric?.primaryValue,
                uploadMBps: metric?.secondaryValue
            )
        case .batteryStatus:
            return SummaryFormatter.compactPercentValue(metric?.primaryValue)
        case .diskUsage:
            return SummaryFormatter.compactPairValue(
                first: metric?.primaryValue,
                second: metric?.secondaryValue,
                suffix: "G"
            )
        }
    }

    private static func visibleMetricCount(preferences: UserPreferences) -> Int {
        visibleMetricKinds(preferences: preferences).count
    }

    private static func visibleMetricKinds(preferences: UserPreferences) -> [MetricKind] {
        let maxVisible = min(
            menuBarMaxVisibleMetrics,
            max(0, preferences.maxVisibleSummaryItems)
        )
        return SummarySelectionEngine.visibleMetrics(
            order: preferences.summaryMetricOrder,
            maxVisible: maxVisible
        )
    }

    @objc
    private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else {
            return
        }

        if popover.isShown {
            popover.performClose(sender)
            return
        }

        refreshPopoverContent()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private func refreshPopoverContent() {
        let rootView = PopoverRootView(
            snapshot: popoverSnapshot,
            onExitRequested: { [weak self] in
                self?.handleExitRequested()
            },
            settings: Binding(
                get: { self.popoverSettings },
                set: { [weak self] updated in
                    guard let self else {
                        return
                    }

                    self.popoverSettings = updated
                    self.popover.behavior = Self.popoverBehavior(for: updated.popoverPinBehavior)
                    self.onSettingsChanged(updated)
                }
            )
        )

        if let hostingController = popover.contentViewController as? NSHostingController<PopoverRootView> {
            hostingController.rootView = rootView
        } else {
            popover.contentViewController = NSHostingController(rootView: rootView)
        }
    }

    func handleExitRequested() {
        popover.performClose(nil)
        appTerminator.terminate(nil)
    }
}
