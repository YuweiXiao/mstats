import Darwin
import Foundation

public protocol NetworkCollecting {
    func collectNetworkThroughput() -> MetricValue?
}

public final class NetworkCollector: NetworkCollecting {
    private struct TotalsSnapshot {
        let timestamp: TimeInterval
        let receivedBytes: UInt64
        let sentBytes: UInt64
    }

    private let lock = NSLock()
    private var previousSnapshot: TotalsSnapshot?

    public init() {}

    public func collectNetworkThroughput() -> MetricValue? {
        guard let currentSnapshot = readTotalsSnapshot() else { return nil }

        lock.lock()
        defer { lock.unlock() }
        defer { previousSnapshot = currentSnapshot }

        guard let previousSnapshot else {
            return MetricValue(primaryValue: 0, secondaryValue: 0, unit: .megabytesPerSecond)
        }

        let elapsedSeconds = currentSnapshot.timestamp - previousSnapshot.timestamp
        guard elapsedSeconds > 0 else {
            return MetricValue(primaryValue: 0, secondaryValue: 0, unit: .megabytesPerSecond)
        }

        let downloadedBytes = currentSnapshot.receivedBytes >= previousSnapshot.receivedBytes
            ? currentSnapshot.receivedBytes - previousSnapshot.receivedBytes
            : 0
        let uploadedBytes = currentSnapshot.sentBytes >= previousSnapshot.sentBytes
            ? currentSnapshot.sentBytes - previousSnapshot.sentBytes
            : 0

        return MetricValue(
            primaryValue: bytesToMegabytesPerSecond(downloadedBytes, over: elapsedSeconds),
            secondaryValue: bytesToMegabytesPerSecond(uploadedBytes, over: elapsedSeconds),
            unit: .megabytesPerSecond
        )
    }

    private func bytesToMegabytesPerSecond(_ bytes: UInt64, over seconds: TimeInterval) -> Double {
        guard seconds > 0 else { return 0 }
        return Double(bytes) / 1_048_576 / seconds
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

        return TotalsSnapshot(
            timestamp: Date().timeIntervalSince1970,
            receivedBytes: receivedBytes,
            sentBytes: sentBytes
        )
    }
}
