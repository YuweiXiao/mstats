import Foundation
import XCTest
@testable import MacStatsBar

final class SystemCollectorMappingTests: XCTestCase {
    func testCollectOmitsUnavailableCPUAndKeepsOtherMetrics() async throws {
        let collector = SystemStatsCollector(
            cpu: FailingCPUCollector(),
            memory: StubMemoryCollector(),
            network: StubNetworkCollector(),
            battery: StubBatteryCollector(),
            disk: StubDiskCollector()
        )

        let snapshot = try await collector.collect()

        XCTAssertNil(snapshot.metrics[.cpuUsage])
        XCTAssertEqual(snapshot.metrics[.memoryUsage], StubMemoryCollector.value)
        XCTAssertEqual(snapshot.metrics[.networkThroughput], StubNetworkCollector.value)
        XCTAssertEqual(snapshot.metrics[.batteryStatus], StubBatteryCollector.value)
        XCTAssertEqual(snapshot.metrics[.diskUsage], StubDiskCollector.value)
    }

    func testCollectReturnsEmptyMetricMapWhenAllCollectorsUnavailable() async throws {
        let collector = SystemStatsCollector(
            cpu: FailingCPUCollector(),
            memory: FailingMemoryCollector(),
            network: FailingNetworkCollector(),
            battery: FailingBatteryCollector(),
            disk: FailingDiskCollector()
        )

        let snapshot = try await collector.collect()

        XCTAssertEqual(snapshot.metrics, [:])
    }
}

private struct FailingCPUCollector: CPUCollecting {
    func collectCPUUsage() -> MetricValue? { nil }
}

private struct StubMemoryCollector: MemoryCollecting {
    static let value = MetricValue(primaryValue: 8, secondaryValue: 16, unit: .gigabytes)

    func collectMemoryUsage() -> MetricValue? { Self.value }
}

private struct StubNetworkCollector: NetworkCollecting {
    static let value = MetricValue(primaryValue: 1.5, secondaryValue: 0.75, unit: .megabytesPerSecond)

    func collectNetworkThroughput() -> MetricValue? { Self.value }
}

private struct StubBatteryCollector: BatteryCollecting {
    static let value = MetricValue(primaryValue: 88, secondaryValue: nil, unit: .percent)

    func collectBatteryStatus() -> MetricValue? { Self.value }
}

private struct StubDiskCollector: DiskCollecting {
    static let value = MetricValue(primaryValue: 512, secondaryValue: 1024, unit: .gigabytes)

    func collectDiskUsage() -> MetricValue? { Self.value }
}

private struct FailingMemoryCollector: MemoryCollecting {
    func collectMemoryUsage() -> MetricValue? { nil }
}

private struct FailingNetworkCollector: NetworkCollecting {
    func collectNetworkThroughput() -> MetricValue? { nil }
}

private struct FailingBatteryCollector: BatteryCollecting {
    func collectBatteryStatus() -> MetricValue? { nil }
}

private struct FailingDiskCollector: DiskCollecting {
    func collectDiskUsage() -> MetricValue? { nil }
}
