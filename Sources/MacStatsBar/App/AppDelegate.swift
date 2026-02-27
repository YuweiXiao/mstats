import AppKit
import Combine

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var statsStore: StatsStore?
    private let preferencesStore = PreferencesStore()
    private let loginItemService: any LoginItemServicing
    private var cancellables: Set<AnyCancellable> = []
    private var workspaceNotificationObservers: [NSObjectProtocol] = []
    private var settingsState = SettingsState.defaultValue
    private var metricHistoryStore = MetricHistoryStore(maxSamples: 60)

    private let backgroundRefreshInterval: TimeInterval = 3
    private let detailPopoverRefreshInterval: TimeInterval = 1

    public override init() {
        loginItemService = LoginItemService()
        super.init()
    }

    init(loginItemService: any LoginItemServicing) {
        self.loginItemService = loginItemService
        super.init()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        settingsState = buildInitialSettings()
        let statusBarController = StatusBarController(
            initialSettings: settingsState,
            onSettingsChanged: { [weak self] settings in
                self?.handleSettingsChanged(settings)
            },
            onPopoverVisibilityChanged: { [weak self] isShown in
                self?.handlePopoverVisibilityChanged(isShown)
            }
        )
        self.statusBarController = statusBarController

        let statsStore = StatsStore(
            collector: SystemStatsCollector(),
            refreshInterval: backgroundRefreshInterval
        )
        self.statsStore = statsStore

        statsStore.$currentSnapshot
            .sink { [weak self] snapshot in
                guard let self, let statusBarController = self.statusBarController else {
                    return
                }

                self.metricHistoryStore.append(snapshot: snapshot)
                let preferences = self.currentSummaryPreferences()
                statusBarController.renderSummary(snapshot: snapshot, preferences: preferences)
                statusBarController.updatePopover(
                    snapshot: snapshot,
                    history: self.metricHistoryStore.history,
                    settings: self.settingsState
                )
            }
            .store(in: &cancellables)

        statusBarController.renderSummary(
            snapshot: statsStore.currentSnapshot,
            preferences: currentSummaryPreferences()
        )
        metricHistoryStore.append(snapshot: statsStore.currentSnapshot)
        statusBarController.updatePopover(
            snapshot: statsStore.currentSnapshot,
            history: metricHistoryStore.history,
            settings: settingsState
        )
        registerLifecycleObservers(for: statsStore)
        statsStore.startPolling()
    }

    deinit {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        workspaceNotificationObservers.forEach { notificationCenter.removeObserver($0) }
    }

    private func registerLifecycleObservers(for statsStore: StatsStore) {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        removeLifecycleObservers()

        let willSleepObserver = notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak statsStore] _ in
            MainActor.assumeIsolated {
                statsStore?.handleWillSleep()
            }
        }

        let didWakeObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak statsStore] _ in
            MainActor.assumeIsolated {
                statsStore?.handleDidWake()
            }
        }

        workspaceNotificationObservers = [willSleepObserver, didWakeObserver]
    }

    private func removeLifecycleObservers() {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        workspaceNotificationObservers.forEach { notificationCenter.removeObserver($0) }
        workspaceNotificationObservers.removeAll()
    }

    private func buildInitialSettings() -> SettingsState {
        let savedPreferences = preferencesStore.load()
        let showSecondaryMetric = savedPreferences.maxVisibleSummaryItems > 1 && savedPreferences.summaryMetricOrder.count > 1
        return SettingsState(
            summaryMetricOrder: savedPreferences.summaryMetricOrder,
            showSecondaryMetric: showSecondaryMetric,
            refreshInterval: backgroundRefreshInterval,
            launchAtLoginEnabled: loginItemService.isEnabled,
            popoverPinBehavior: .autoClose
        )
    }

    private func currentSummaryPreferences() -> UserPreferences {
        var order = [settingsState.primaryStatusMetric]
        if let secondary = settingsState.secondaryStatusMetric {
            order.append(secondary)
        }

        return UserPreferences(
            summaryMetricOrder: order,
            maxVisibleSummaryItems: order.count
        )
    }

    private func handleSettingsChanged(_ settings: SettingsState) {
        settingsState = settings

        let updatedPreferences = currentSummaryPreferences()
        preferencesStore.save(updatedPreferences)
        statusBarController?.renderSummary(snapshot: statsStore?.currentSnapshot, preferences: updatedPreferences)

        do {
            try loginItemService.setEnabled(settings.launchAtLoginEnabled)
        } catch {
            // Keep UI responsive; backend failures are handled by service tests.
        }
    }

    private func handlePopoverVisibilityChanged(_ isShown: Bool) {
        let interval = isShown ? detailPopoverRefreshInterval : backgroundRefreshInterval
        settingsState.refreshInterval = interval
        statsStore?.updateRefreshInterval(interval)
    }
}
