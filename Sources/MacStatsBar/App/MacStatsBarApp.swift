import SwiftUI

public struct MacStatsBarAppBootstrap: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    public init() {}

    public var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
