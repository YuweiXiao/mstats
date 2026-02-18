import Foundation

public protocol DiskCollecting {
    func collectDiskUsage() -> MetricValue?
}

public struct DiskCollector: DiskCollecting {
    typealias CapacitySnapshot = (totalCapacity: Int64, availableCapacity: Int64?)

    private let volumeURL: URL
    private let capacityProvider: (URL) -> CapacitySnapshot?

    public init(volumeURL: URL = URL(fileURLWithPath: "/")) {
        self.volumeURL = volumeURL
        self.capacityProvider = Self.readCapacity
    }

    init(
        volumeURL: URL,
        capacityProvider: @escaping (URL) -> CapacitySnapshot?
    ) {
        self.volumeURL = volumeURL
        self.capacityProvider = capacityProvider
    }

    public func collectDiskUsage() -> MetricValue? {
        guard
            let capacity = capacityProvider(volumeURL),
            capacity.totalCapacity > 0
        else {
            return nil
        }

        let totalCapacity = capacity.totalCapacity
        let rawAvailable = capacity.availableCapacity ?? 0
        let clampedAvailable = min(max(rawAvailable, 0), totalCapacity)
        let usedCapacity = totalCapacity - clampedAvailable

        return MetricValue(
            primaryValue: bytesToGigabytes(usedCapacity),
            secondaryValue: bytesToGigabytes(totalCapacity),
            unit: .gigabytes
        )
    }

    private func bytesToGigabytes(_ bytes: Int64) -> Double {
        Double(bytes) / 1_073_741_824
    }

    private static func readCapacity(for volumeURL: URL) -> CapacitySnapshot? {
        let keys: Set<URLResourceKey> = [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey
        ]

        do {
            let values = try volumeURL.resourceValues(forKeys: keys)
            guard let totalCapacity = values.volumeTotalCapacity, totalCapacity > 0 else { return nil }
            let availableCapacity = values.volumeAvailableCapacityForImportantUsage
                ?? Int64(values.volumeAvailableCapacity ?? 0)
            return (totalCapacity: Int64(totalCapacity), availableCapacity: availableCapacity)
        } catch {
            return nil
        }
    }
}
