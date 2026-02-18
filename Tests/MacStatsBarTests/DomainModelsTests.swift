import Foundation
import XCTest
@testable import MacStatsBar

final class DomainModelsTests: XCTestCase {
    func testUserPreferencesDefaultStartsWithCPUAndMemory() {
        let preferences = UserPreferences.defaultValue

        XCTAssertEqual(Array(preferences.summaryMetricOrder.prefix(2)), [.cpuUsage, .memoryUsage])
    }

    func testUserPreferencesDefaultMaxVisibleSummaryItemsIsTwo() {
        let preferences = UserPreferences.defaultValue

        XCTAssertEqual(preferences.maxVisibleSummaryItems, 2)
    }

    func testUserPreferencesCodableRoundTrip() throws {
        let input = UserPreferences(
            summaryMetricOrder: [.diskUsage, .networkThroughput, .cpuUsage],
            maxVisibleSummaryItems: 3
        )

        let output = try roundTrip(input)
        XCTAssertEqual(output, input)
    }

    func testVisibleSummaryMetricsCapsToMaxVisibleSummaryItems() {
        let preferences = UserPreferences(
            summaryMetricOrder: [.cpuUsage, .memoryUsage, .networkThroughput],
            maxVisibleSummaryItems: 2
        )

        XCTAssertEqual(preferences.visibleSummaryMetrics, [.cpuUsage, .memoryUsage])
    }

    func testVisibleSummaryMetricsReturnsAllWhenCapIsAtLeastCount() {
        let preferences = UserPreferences(
            summaryMetricOrder: [.cpuUsage, .memoryUsage],
            maxVisibleSummaryItems: 4
        )

        XCTAssertEqual(preferences.visibleSummaryMetrics, [.cpuUsage, .memoryUsage])
    }

    func testUserPreferencesInitializerClampsNegativeMaxVisibleSummaryItemsToZero() {
        let preferences = UserPreferences(
            summaryMetricOrder: [.cpuUsage, .memoryUsage],
            maxVisibleSummaryItems: -1
        )

        XCTAssertEqual(preferences.maxVisibleSummaryItems, 0)
    }

    func testUserPreferencesDecodingClampsNegativeMaxVisibleSummaryItemsToZero() throws {
        let json = """
        {
          "summaryMetricOrder": ["cpuUsage", "memoryUsage"],
          "maxVisibleSummaryItems": -5
        }
        """

        let decoded = try JSONDecoder().decode(UserPreferences.self, from: Data(json.utf8))
        XCTAssertEqual(decoded.maxVisibleSummaryItems, 0)
    }

    func testVisibleSummaryMetricsIsEmptyWhenCapIsZero() {
        let preferences = UserPreferences(
            summaryMetricOrder: [.cpuUsage, .memoryUsage],
            maxVisibleSummaryItems: 0
        )

        XCTAssertEqual(preferences.visibleSummaryMetrics, [])
    }

    func testMetricValueCodableRoundTrip() throws {
        let input = MetricValue(
            primaryValue: 2.4,
            secondaryValue: 0.7,
            unit: .megabytesPerSecond
        )

        let output = try roundTrip(input)
        XCTAssertEqual(output, input)
    }

    func testStatsSnapshotCodableRoundTrip() throws {
        let timestamp = Date(timeIntervalSince1970: 1_706_000_000)
        let input = StatsSnapshot(
            timestamp: timestamp,
            metrics: [
                .cpuUsage: MetricValue(primaryValue: 23, secondaryValue: nil, unit: .percent),
                .memoryUsage: MetricValue(primaryValue: 14.2, secondaryValue: 32, unit: .gigabytes)
            ]
        )

        let output = try roundTrip(input)
        XCTAssertEqual(output, input)
    }

    func testMetricKindCodableRoundTrip() throws {
        let input = MetricKind.batteryStatus

        let output = try roundTrip(input)
        XCTAssertEqual(output, input)
    }

    private func roundTrip<Value: Codable & Equatable>(_ value: Value) throws -> Value {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(value)
        return try decoder.decode(Value.self, from: data)
    }
}
