import Foundation
import XCTest
@testable import MacStatsBar

final class StatsCollectorProtocolTests: XCTestCase {
    func testFakeCollectorReturnsInjectedSnapshot() async throws {
        let snapshot = StatsSnapshot(
            timestamp: Date(timeIntervalSince1970: 1_706_000_000),
            metrics: [.cpuUsage: MetricValue(primaryValue: 42, secondaryValue: nil, unit: .percent)]
        )
        let collector = FakeStatsCollector(snapshot: snapshot)

        let collected = try await collector.collect()

        XCTAssertEqual(collected, snapshot)
    }

    func testFakeCollectorThrowsInjectedError() async {
        enum SampleError: Error, Equatable {
            case expected
        }

        let snapshot = StatsSnapshot(timestamp: Date(), metrics: [:])
        let collector = FakeStatsCollector(snapshot: snapshot, error: SampleError.expected)

        do {
            _ = try await collector.collect()
            XCTFail("Expected collect() to throw")
        } catch let error as SampleError {
            XCTAssertEqual(error, .expected)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
