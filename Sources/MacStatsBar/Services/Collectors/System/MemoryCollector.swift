import Darwin
import Foundation

public protocol MemoryCollecting {
    func collectMemoryUsage() -> MetricValue?
}

public struct MemoryCollector: MemoryCollecting {
    public init() {}

    public func collectMemoryUsage() -> MetricValue? {
        let totalBytes = ProcessInfo.processInfo.physicalMemory
        guard totalBytes > 0 else { return nil }

        var pageSize: vm_size_t = 0
        guard host_page_size(mach_host_self(), &pageSize) == KERN_SUCCESS else { return nil }

        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )

        let status = withUnsafeMutablePointer(to: &vmStats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, reboundPointer, &count)
            }
        }

        guard status == KERN_SUCCESS else { return nil }

        let usedPages = vmStats.active_count + vmStats.inactive_count + vmStats.wire_count + vmStats.compressor_page_count
        let usedBytes = Double(usedPages) * Double(pageSize)

        let usedGigabytes = usedBytes / 1_073_741_824
        let totalGigabytes = Double(totalBytes) / 1_073_741_824
        guard totalGigabytes > 0 else { return nil }

        return MetricValue(
            primaryValue: min(usedGigabytes, totalGigabytes),
            secondaryValue: totalGigabytes,
            unit: .gigabytes
        )
    }
}
