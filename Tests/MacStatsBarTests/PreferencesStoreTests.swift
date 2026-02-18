import Foundation
import XCTest
@testable import MacStatsBar

final class PreferencesStoreTests: XCTestCase {
    func testLoadReturnsDefaultWhenNoPersistedValueExists() {
        let userDefaults = makeUserDefaults()
        let store = PreferencesStore(userDefaults: userDefaults)

        XCTAssertEqual(store.load(), UserPreferences.defaultValue)
    }

    func testSaveThenLoadRoundTripsPreferencesUsingStableKey() {
        let userDefaults = makeUserDefaults()
        let store = PreferencesStore(userDefaults: userDefaults)
        let input = UserPreferences(
            summaryMetricOrder: [.diskUsage, .networkThroughput, .cpuUsage],
            maxVisibleSummaryItems: 3
        )

        store.save(input)

        XCTAssertNotNil(userDefaults.data(forKey: "user_preferences_v1"))
        XCTAssertEqual(store.load(), input)
    }

    func testLoadReturnsDefaultWhenPersistedDataIsCorrupt() {
        let userDefaults = makeUserDefaults()
        let store = PreferencesStore(userDefaults: userDefaults)
        userDefaults.set(Data([0xFF, 0xD8, 0xFF]), forKey: "user_preferences_v1")

        XCTAssertEqual(store.load(), UserPreferences.defaultValue)
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "PreferencesStoreTests.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Expected UserDefaults suite for \(suiteName)")
        }

        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}
