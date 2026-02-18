import Darwin
import Foundation

public protocol CPUCollecting {
    func collectCPUUsage() -> MetricValue?
}

public final class CPUCollector: CPUCollecting {
    typealias TickSnapshot = (user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)

    private let sampleTicks: () -> TickSnapshot?
    private let lock = NSLock()
    private var previousTicks: TickSnapshot?

    public init() {
        self.sampleTicks = Self.readCurrentTicks
    }

    init(sampleTicks: @escaping () -> TickSnapshot?) {
        self.sampleTicks = sampleTicks
    }

    public func collectCPUUsage() -> MetricValue? {
        lock.lock()
        defer { lock.unlock() }

        guard let currentTicks = sampleTicks() else { return nil }
        guard let previousTicks else {
            self.previousTicks = currentTicks
            return nil
        }
        self.previousTicks = currentTicks

        guard
            let userDelta = delta(from: previousTicks.user, to: currentTicks.user),
            let systemDelta = delta(from: previousTicks.system, to: currentTicks.system),
            let idleDelta = delta(from: previousTicks.idle, to: currentTicks.idle),
            let niceDelta = delta(from: previousTicks.nice, to: currentTicks.nice)
        else {
            return nil
        }

        let totalDelta = userDelta + systemDelta + idleDelta + niceDelta
        guard totalDelta > 0 else { return nil }

        let usagePercent = ((userDelta + systemDelta + niceDelta) / totalDelta) * 100
        guard usagePercent.isFinite else { return nil }
        return MetricValue(primaryValue: usagePercent, secondaryValue: nil, unit: .percent)
    }

    private func delta(from oldValue: UInt64, to newValue: UInt64) -> Double? {
        guard newValue >= oldValue else { return nil }
        return Double(newValue - oldValue)
    }

    private static func readCurrentTicks() -> TickSnapshot? {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size
        )

        let status = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, reboundPointer, &count)
            }
        }

        guard status == KERN_SUCCESS else { return nil }

        return (
            user: UInt64(info.cpu_ticks.0),
            system: UInt64(info.cpu_ticks.1),
            idle: UInt64(info.cpu_ticks.2),
            nice: UInt64(info.cpu_ticks.3)
        )
    }
}
