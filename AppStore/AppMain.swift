import SwiftUI
import MacStatsBar

@main
struct MacStatsBarStoreAppEntry: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
