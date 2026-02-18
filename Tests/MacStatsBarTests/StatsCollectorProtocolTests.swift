import Foundation
import XCTest
@testable import MacStatsBar

final class StatsCollectorProtocolTests: XCTestCase {
    func testFakeCollectorReturnsInjectedSnapshot() async throws {
        let snapshot = StatsSnapshot(
            timestamp: Date(timeIntervalSince1970: 1_706_000_000),
            metrics: [.cpuUsage: MetricValue(primaryValue: 42, secondaryValue: nil, unit: .percent)]
        )
        let collector: any StatsCollecting = FakeStatsCollector(snapshot: snapshot)

        let collected = try await collect(using: collector)

        XCTAssertEqual(collected, snapshot)
    }

    func testFakeCollectorThrowsInjectedError() async {
        enum SampleError: Error, Equatable {
            case expected
        }

        let collector: any StatsCollecting = FakeStatsCollector(error: SampleError.expected)

        do {
            _ = try await collect(using: collector)
            XCTFail("Expected collect() to throw")
        } catch let error as SampleError {
            XCTAssertEqual(error, .expected)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    private func collect(using collector: any StatsCollecting) async throws -> StatsSnapshot {
        try await collector.collect()
    }
}
