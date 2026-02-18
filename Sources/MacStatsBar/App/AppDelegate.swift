import AppKit
import Combine

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var statsStore: StatsStore?
    private let preferencesStore = PreferencesStore()
    private var cancellables: Set<AnyCancellable> = []

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
        statsStore.startPolling()
    }
}
