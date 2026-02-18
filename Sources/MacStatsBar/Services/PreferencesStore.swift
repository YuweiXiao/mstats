import Foundation

public struct PreferencesStore {
    static let storageKey = "user_preferences_v1"

    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        userDefaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.userDefaults = userDefaults
        self.encoder = encoder
        self.decoder = decoder
    }

    public func save(_ preferences: UserPreferences) {
        guard let data = try? encoder.encode(preferences) else {
            return
        }

        userDefaults.set(data, forKey: Self.storageKey)
    }

    public func load() -> UserPreferences {
        guard let data = userDefaults.data(forKey: Self.storageKey) else {
            return .defaultValue
        }

        guard let preferences = try? decoder.decode(UserPreferences.self, from: data) else {
            return .defaultValue
        }

        return preferences
    }
}
