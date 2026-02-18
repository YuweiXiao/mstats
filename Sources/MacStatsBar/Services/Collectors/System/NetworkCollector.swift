import Darwin
import Foundation

public protocol NetworkCollecting {
    func collectNetworkThroughput() -> MetricValue?
}

public final class NetworkCollector: NetworkCollecting {
    private struct TotalsSnapshot {
        let receivedBytes: UInt64
        let sentBytes: UInt64
    }

    public init() {}

    public func collectNetworkThroughput() -> MetricValue? {
        guard let currentSnapshot = readTotalsSnapshot() else { return nil }
        return MetricValue(
            primaryValue: bytesToMegabytes(currentSnapshot.receivedBytes),
            secondaryValue: bytesToMegabytes(currentSnapshot.sentBytes),
            unit: .megabytesPerSecond
        )
    }

    private func bytesToMegabytes(_ bytes: UInt64) -> Double {
        Double(bytes) / 1_048_576
    }

    private func readTotalsSnapshot() -> TotalsSnapshot? {
        var interfacesAddress: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfacesAddress) == 0, let firstInterface = interfacesAddress else { return nil }
        defer { freeifaddrs(interfacesAddress) }

        var receivedBytes: UInt64 = 0
        var sentBytes: UInt64 = 0
        var cursor: UnsafeMutablePointer<ifaddrs>? = firstInterface

        while let interface = cursor {
            defer { cursor = interface.pointee.ifa_next }

            let flags = interface.pointee.ifa_flags
            let isUp = (flags & UInt32(IFF_UP)) != 0
            let isLoopback = (flags & UInt32(IFF_LOOPBACK)) != 0
            guard isUp, !isLoopback else { continue }

            guard let dataPointer = interface.pointee.ifa_data else { continue }
            let data = dataPointer.assumingMemoryBound(to: if_data.self).pointee
            receivedBytes &+= UInt64(data.ifi_ibytes)
            sentBytes &+= UInt64(data.ifi_obytes)
        }

        return TotalsSnapshot(receivedBytes: receivedBytes, sentBytes: sentBytes)
    }
}
