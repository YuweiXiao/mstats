import AppKit
import SwiftUI

public protocol ApplicationTerminating {
    func terminate(_ sender: Any?)
}

extension NSApplication: ApplicationTerminating {}

public final class StatusBarController: NSObject {
    private static let fallbackSummaryText = "--"
    private static let menuBarMaxVisibleMetrics = 2
    private static let singleMetricMinLength: CGFloat = 32
    private static let singleMetricStatusLength: CGFloat = 52
    private static let dualMetricMinLength: CGFloat = 66
    private static let dualMetricStatusLength: CGFloat = 108
    private static let multilineNetworkStatusLength: CGFloat = 44
    private static let summaryHorizontalPadding: CGFloat = 8
    private static let multilineLeadingSpacing: CGFloat = 2

    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let onSettingsChanged: (SettingsState) -> Void
    private let appTerminator: any ApplicationTerminating
    private let notificationCenter: NotificationCenter
    private let workspaceNotificationCenter: NotificationCenter
    private let externalInteractionObserverRemover: (Any) -> Void
    private var popoverSnapshot: StatsSnapshot?
    private var popoverHistory: [MetricKind: [MetricHistorySample]] = [:]
    private var popoverSettings: SettingsState
    private var externalInteractionObserverToken: Any?
    private lazy var networkMultilineView: NetworkMultilineStatusItemView = {
        let view = NetworkMultilineStatusItemView(
            frame: NSRect(
                x: 0,
                y: 0,
                width: Self.multilineNetworkStatusLength,
                height: NSStatusBar.system.thickness
            )
        )
        view.onPressed = { [weak self] in
            self?.togglePopover(nil)
        }
        return view
    }()

    public init(
        statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength),
        initialSettings: SettingsState = .defaultValue,
        onSettingsChanged: @escaping (SettingsState) -> Void = { _ in },
        popover: NSPopover = NSPopover(),
        appTerminator: any ApplicationTerminating = NSApplication.shared,
        notificationCenter: NotificationCenter = .default,
        workspaceNotificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter,
        externalInteractionObserverRegistrar: @escaping (@escaping () -> Void) -> Any? = { handler in
            NSEvent.addGlobalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
            ) { _ in
                handler()
            }
        },
        externalInteractionObserverRemover: @escaping (Any) -> Void = { monitor in
            NSEvent.removeMonitor(monitor)
        }
    ) {
        self.popover = popover
        self.onSettingsChanged = onSettingsChanged
        self.appTerminator = appTerminator
        self.notificationCenter = notificationCenter
        self.workspaceNotificationCenter = workspaceNotificationCenter
        self.externalInteractionObserverRemover = externalInteractionObserverRemover
        self.popoverSettings = initialSettings
        self.statusItem = statusItem
        super.init()

        notificationCenter.addObserver(
            self,
            selector: #selector(handleApplicationDidResignActive(_:)),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )
        workspaceNotificationCenter.addObserver(
            self,
            selector: #selector(handleWorkspaceDidActivateApplication(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        externalInteractionObserverToken = externalInteractionObserverRegistrar { [weak self] in
            guard let self else {
                return
            }
            if Thread.isMainThread {
                self.closePopoverIfShown()
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.closePopoverIfShown()
                }
            }
        }
        configureStatusButton()

        self.popover.behavior = Self.popoverBehavior(for: initialSettings.popoverPinBehavior)
        self.popover.animates = true
        self.popover.contentSize = NSSize(width: 340, height: 420)
        refreshPopoverContent()
    }

    deinit {
        notificationCenter.removeObserver(
            self,
            name: NSApplication.didResignActiveNotification,
            object: nil
        )
        workspaceNotificationCenter.removeObserver(
            self,
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        if let externalInteractionObserverToken {
            externalInteractionObserverRemover(externalInteractionObserverToken)
        }
    }

    func renderSummary(snapshot: StatsSnapshot?, preferences: UserPreferences) {
        let visibleCount = Self.visibleMetricCount(preferences: preferences)

        let metricKinds = Self.visibleMetricKinds(preferences: preferences)
        if metricKinds.contains(.networkThroughput) {
            let networkMetric = snapshot?.metrics[.networkThroughput]
            let networkText = SummaryFormatter.compactNetworkValueMultiline(
                downloadMBps: networkMetric?.primaryValue,
                uploadMBps: networkMetric?.secondaryValue
            )
            let segments = networkText.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
            let topLine = segments.first.map(String.init) ?? Self.fallbackSummaryText
            let bottomLine = segments.count > 1 ? String(segments[1]) : Self.fallbackSummaryText
            let leadingMetricKind = metricKinds.first { $0 != .networkThroughput }
            let leadingText = leadingMetricKind.map { Self.format(metricKind: $0, snapshot: snapshot) }
            let width = Self.multilineStatusLength(leadingMetricKind: leadingMetricKind)

            renderMultilineSummary(
                leadingText: leadingText,
                topLine: topLine,
                bottomLine: bottomLine,
                width: width
            )
            return
        }

        let text = Self.summaryText(snapshot: snapshot, preferences: preferences)
        let widthMetricKinds = visibleCount > 0 ? metricKinds : [.cpuUsage]
        statusItem.length = Self.singleLineStatusLength(metricKinds: widthMetricKinds)
        if statusItem.view != nil {
            statusItem.view = nil
        }
        configureStatusButton()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byTruncatingTail

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular),
            .paragraphStyle: paragraphStyle
        ]
        statusItem.button?.attributedTitle = NSAttributedString(string: text, attributes: attributes)
        if let cell = statusItem.button?.cell as? NSButtonCell {
            cell.usesSingleLineMode = true
            cell.wraps = false
            cell.lineBreakMode = .byTruncatingTail
            cell.alignment = .center
        }
    }

    func updatePopover(
        snapshot: StatsSnapshot?,
        history: [MetricKind: [MetricHistorySample]],
        settings: SettingsState
    ) {
        popoverSnapshot = snapshot
        popoverHistory = history
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
        guard !metricKinds.isEmpty else {
            return fallbackSummaryText
        }

        if let networkIndex = metricKinds.firstIndex(of: .networkThroughput) {
            let metric = snapshot?.metrics[.networkThroughput]
            let networkText = SummaryFormatter.compactNetworkValueMultiline(
                downloadMBps: metric?.primaryValue,
                uploadMBps: metric?.secondaryValue
            )
            let lines = networkText.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
            let networkTopLine = lines.first.map(String.init) ?? fallbackSummaryText
            let networkBottomLine = lines.count > 1 ? String(lines[1]) : fallbackSummaryText

            guard metricKinds.count > 1 else {
                return networkText
            }

            let otherKind = metricKinds.first { $0 != .networkThroughput }
            let otherText = otherKind.map { format(metricKind: $0, snapshot: snapshot) } ?? fallbackSummaryText
            let topLine: String
            if networkIndex == 0 {
                topLine = "\(networkTopLine)|\(otherText)"
            } else {
                topLine = "\(otherText)|\(networkTopLine)"
            }
            return "\(topLine)\n\(networkBottomLine)"
        }

        let parts = metricKinds.map { metricKind in
            format(metricKind: metricKind, snapshot: snapshot)
        }

        return parts.joined(separator: "|")
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

    private static func singleLineStatusLength(metricKinds: [MetricKind]) -> CGFloat {
        let normalizedKinds = Array(metricKinds.prefix(menuBarMaxVisibleMetrics))
        let template = normalizedKinds
            .map { summaryTemplate(for: $0) }
            .joined(separator: "|")
        let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        let measured = measuredWidth(for: template, font: font) + summaryHorizontalPadding

        if normalizedKinds.count > 1 {
            return min(max(measured, dualMetricMinLength), dualMetricStatusLength)
        }
        return min(max(measured, singleMetricMinLength), singleMetricStatusLength)
    }

    private static func multilineStatusLength(leadingMetricKind: MetricKind?) -> CGFloat {
        let networkFont = NSFont.monospacedDigitSystemFont(ofSize: 8.5, weight: .regular)
        let networkTopWidth = measuredWidth(for: "99.9↓", font: networkFont)
        let networkBottomWidth = measuredWidth(for: "99.9↑MB/s", font: networkFont)
        var measured = max(networkTopWidth, networkBottomWidth) + summaryHorizontalPadding

        if let leadingMetricKind {
            let leadingFont = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            measured += measuredWidth(for: summaryTemplate(for: leadingMetricKind), font: leadingFont)
            measured += multilineLeadingSpacing
            return min(max(measured, dualMetricMinLength), dualMetricStatusLength)
        }

        return min(max(measured, singleMetricMinLength), multilineNetworkStatusLength)
    }

    private static func summaryTemplate(for metricKind: MetricKind) -> String {
        switch metricKind {
        case .cpuUsage, .batteryStatus:
            return "99%"
        case .memoryUsage, .diskUsage:
            return "99.9/99.9G"
        case .networkThroughput:
            return "999.9↓999.9↑MB/s"
        }
    }

    private static func measuredWidth(for text: String, font: NSFont) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        return ceil((text as NSString).size(withAttributes: attributes).width)
    }

    private func configureStatusButton() {
        guard let button = statusItem.button else {
            return
        }
        button.target = self
        button.action = #selector(togglePopover(_:))
        if button.title.isEmpty, button.attributedTitle.string.isEmpty {
            button.title = Self.fallbackSummaryText
        }
    }

    private func renderMultilineSummary(
        leadingText: String?,
        topLine: String,
        bottomLine: String,
        width: CGFloat
    ) {
        networkMultilineView.update(leadingText: leadingText, topLine: topLine, bottomLine: bottomLine)
        networkMultilineView.frame = NSRect(
            x: 0,
            y: 0,
            width: width,
            height: NSStatusBar.system.thickness
        )
        if statusItem.view !== networkMultilineView {
            statusItem.view = networkMultilineView
        }
        statusItem.length = width
    }

    @objc
    private func togglePopover(_ sender: Any?) {
        guard let anchorView = statusItem.view ?? statusItem.button else {
            return
        }

        if popover.isShown {
            popover.performClose(sender)
            return
        }

        refreshPopoverContent()
        popover.show(relativeTo: anchorView.bounds, of: anchorView, preferredEdge: .minY)
    }

    private func refreshPopoverContent() {
        let rootView = PopoverRootView(
            snapshot: popoverSnapshot,
            history: popoverHistory,
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

    @objc
    private func handleApplicationDidResignActive(_ notification: Notification) {
        closePopoverIfShown()
    }

    @objc
    private func handleWorkspaceDidActivateApplication(_ notification: Notification) {
        closePopoverIfShown()
    }

    private func closePopoverIfShown() {
        guard popover.isShown else {
            return
        }

        popover.performClose(nil)
    }
}
