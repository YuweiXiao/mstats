import Darwin
import Foundation

public protocol CPUCollecting {
    func collectCPUUsage() -> MetricValue?
}

public struct CPUCollector: CPUCollecting {
    public init() {}

    public func collectCPUUsage() -> MetricValue? {
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

        let user = Double(info.cpu_ticks.0)
        let system = Double(info.cpu_ticks.1)
        let idle = Double(info.cpu_ticks.2)
        let nice = Double(info.cpu_ticks.3)
        let total = user + system + idle + nice
        guard total > 0 else { return nil }

        let usagePercent = ((user + system + nice) / total) * 100
        return MetricValue(primaryValue: usagePercent, secondaryValue: nil, unit: .percent)
    }
}
