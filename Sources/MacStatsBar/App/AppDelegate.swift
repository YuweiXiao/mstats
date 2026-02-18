import AppKit
import Combine

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var statsStore: StatsStore?
    private let preferencesStore = PreferencesStore()
    private var cancellables: Set<AnyCancellable> = []
    private var workspaceNotificationObservers: [NSObjectProtocol] = []

    private let summaryRefreshInterval: TimeInterval = 2

    public override init() {}

    public func applicationDidFinishLaunching(_ notification: Notification) {
        let statusBarController = StatusBarController()
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

                let preferences = self.preferencesStore.load()
                statusBarController.renderSummary(snapshot: snapshot, preferences: preferences)
            }
            .store(in: &cancellables)

        statusBarController.renderSummary(
            snapshot: statsStore.currentSnapshot,
            preferences: preferencesStore.load()
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
}
