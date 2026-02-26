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

    func testCollectIncludesProcessCPUUsagesFromProcessCollector() async throws {
        let processUsages = [
            ProcessCPUUsage(processName: "Xcode", cpuUsagePercent: 21.5),
            ProcessCPUUsage(processName: "Chrome Helper", cpuUsagePercent: 7.8)
        ]
        let collector = SystemStatsCollector(
            cpu: FailingCPUCollector(),
            memory: FailingMemoryCollector(),
            network: FailingNetworkCollector(),
            battery: FailingBatteryCollector(),
            disk: FailingDiskCollector(),
            processCPU: StubProcessCPUCollector(value: processUsages)
        )

        let snapshot = try await collector.collect()

        XCTAssertEqual(snapshot.processCPUUsages, processUsages)
    }

    func testCPUCollectorComputesUsageFromTickDeltasAndSkipsFirstSample() {
        var samples: [(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)] = [
            (100, 50, 850, 0),
            (130, 70, 900, 0)
        ]
        let collector = CPUCollector(sampleTicks: {
            guard !samples.isEmpty else { return nil }
            return samples.removeFirst()
        })

        XCTAssertNil(collector.collectCPUUsage())
        let secondMetric = collector.collectCPUUsage()

        XCTAssertNotNil(secondMetric)
        XCTAssertEqual(secondMetric?.unit, .percent)
        XCTAssertEqual(secondMetric?.primaryValue ?? .nan, 50, accuracy: 0.0001)
    }

    func testCPUCollectorReturnsNilWhenTickDeltaIsInvalid() {
        var samples: [(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)] = [
            (200, 100, 700, 0),
            (190, 95, 710, 0)
        ]
        let collector = CPUCollector(sampleTicks: {
            guard !samples.isEmpty else { return nil }
            return samples.removeFirst()
        })

        XCTAssertNil(collector.collectCPUUsage())
        XCTAssertNil(collector.collectCPUUsage())
    }

    func testProcessCPUCollectorNormalizesPerProcessPercentByLogicalCPUCount() {
        let collector = ProcessCPUCollector(
            logicalCPUCountProvider: { 8 },
            commandRunner: { _, _ in
                """
                80.0 Xcode
                20.0 Google Chrome Helper
                0.4 mds
                """
            }
        )

        let usages = collector.collectProcessCPUUsages()

        XCTAssertEqual(usages.count, 3)
        XCTAssertEqual(usages[0].processName, "Xcode")
        XCTAssertEqual(usages[0].cpuUsagePercent, 10.0, accuracy: 0.0001)
        XCTAssertEqual(usages[1].processName, "Google Chrome Helper")
        XCTAssertEqual(usages[1].cpuUsagePercent, 2.5, accuracy: 0.0001)
        XCTAssertEqual(usages[2].cpuUsagePercent, 0.05, accuracy: 0.0001)
    }

    func testDiskCollectorClampsAvailableCapacityIntoBoundsBeforeDerivingUsed() {
        let gibibyte = Int64(1_073_741_824)

        let negativeAvailableCollector = DiskCollector(
            volumeURL: URL(fileURLWithPath: "/"),
            capacityProvider: { _ in (totalCapacity: gibibyte, availableCapacity: -512) }
        )
        let overflowAvailableCollector = DiskCollector(
            volumeURL: URL(fileURLWithPath: "/"),
            capacityProvider: { _ in (totalCapacity: gibibyte, availableCapacity: gibibyte * 2) }
        )

        let usedWithNegativeAvailable = negativeAvailableCollector.collectDiskUsage()
        let usedWithOverflowAvailable = overflowAvailableCollector.collectDiskUsage()

        XCTAssertEqual(usedWithNegativeAvailable?.primaryValue ?? .nan, 1, accuracy: 0.0001)
        XCTAssertEqual(usedWithNegativeAvailable?.secondaryValue ?? .nan, 1, accuracy: 0.0001)
        XCTAssertEqual(usedWithOverflowAvailable?.primaryValue ?? .nan, 0, accuracy: 0.0001)
        XCTAssertEqual(usedWithOverflowAvailable?.secondaryValue ?? .nan, 1, accuracy: 0.0001)
    }
}

private struct FailingCPUCollector: CPUCollecting {
    func collectCPUUsage() -> MetricValue? { nil }
}

private struct StubProcessCPUCollector: ProcessCPUCollecting {
    let value: [ProcessCPUUsage]

    func collectProcessCPUUsages() -> [ProcessCPUUsage] {
        value
    }
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
