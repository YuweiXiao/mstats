import Foundation

public protocol DiskCollecting {
    func collectDiskUsage() -> MetricValue?
}

public struct DiskCollector: DiskCollecting {
    private let volumeURL: URL

    public init(volumeURL: URL = URL(fileURLWithPath: "/")) {
        self.volumeURL = volumeURL
    }

    public func collectDiskUsage() -> MetricValue? {
        let keys: Set<URLResourceKey> = [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey
        ]

        do {
            let values = try volumeURL.resourceValues(forKeys: keys)
            guard let totalCapacity = values.volumeTotalCapacity, totalCapacity > 0 else { return nil }

            let preferredAvailableCapacity = values.volumeAvailableCapacityForImportantUsage
                ?? Int64(values.volumeAvailableCapacity ?? 0)
            let usedCapacity = max(Int64(totalCapacity) - preferredAvailableCapacity, 0)

            return MetricValue(
                primaryValue: bytesToGigabytes(usedCapacity),
                secondaryValue: bytesToGigabytes(Int64(totalCapacity)),
                unit: .gigabytes
            )
        } catch {
            return nil
        }
    }

    private func bytesToGigabytes(_ bytes: Int64) -> Double {
        Double(bytes) / 1_073_741_824
    }
}
