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

    private let summaryRefreshInterval: TimeInterval = 2

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
            }
        )
        self.statusBarController = statusBarController

        let statsStore = StatsStore(
            collector: SystemStatsCollector(),
            refreshInterval: summaryRefreshInterval
        )
        self.statsStore = statsStore

        statsStore.$currentSnapshot
            .sink { [weak self] snapshot in
                guard let self, let statusBarController = self.statusBarController else {
                    return
                }

                let preferences = self.currentSummaryPreferences()
                statusBarController.renderSummary(snapshot: snapshot, preferences: preferences)
                statusBarController.updatePopover(snapshot: snapshot, settings: self.settingsState)
            }
            .store(in: &cancellables)

        statusBarController.renderSummary(
            snapshot: statsStore.currentSnapshot,
            preferences: currentSummaryPreferences()
        )
        statusBarController.updatePopover(snapshot: statsStore.currentSnapshot, settings: settingsState)
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
        return SettingsState(
            summaryMetricOrder: savedPreferences.summaryMetricOrder,
            refreshInterval: summaryRefreshInterval,
            launchAtLoginEnabled: loginItemService.isEnabled,
            popoverPinBehavior: .autoClose
        )
    }

    private func currentSummaryPreferences() -> UserPreferences {
        UserPreferences(
            summaryMetricOrder: settingsState.summaryMetricOrder,
            maxVisibleSummaryItems: 2
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
}
