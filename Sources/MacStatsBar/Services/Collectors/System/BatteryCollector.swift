import Foundation
import IOKit.ps

public protocol BatteryCollecting {
    func collectBatteryStatus() -> MetricValue?
}

public struct BatteryCollector: BatteryCollecting {
    public init() {}

    public func collectBatteryStatus() -> MetricValue? {
        guard
            let powerSourcesInfo = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let powerSources = IOPSCopyPowerSourcesList(powerSourcesInfo)?.takeRetainedValue() as? [CFTypeRef]
        else {
            return nil
        }

        for source in powerSources {
            guard
                let description = IOPSGetPowerSourceDescription(powerSourcesInfo, source)?
                    .takeUnretainedValue() as? [String: Any],
                (description[kIOPSIsPresentKey as String] as? Bool) == true,
                let currentCapacity = numberValue(forKey: kIOPSCurrentCapacityKey as String, in: description),
                let maxCapacity = numberValue(forKey: kIOPSMaxCapacityKey as String, in: description),
                maxCapacity > 0
            else {
                continue
            }

            let percentage = min(max((currentCapacity / maxCapacity) * 100, 0), 100)
            return MetricValue(primaryValue: percentage, secondaryValue: nil, unit: .percent)
        }

        return nil
    }

    private func numberValue(forKey key: String, in dictionary: [String: Any]) -> Double? {
        if let value = dictionary[key] as? Double { return value }
        if let value = dictionary[key] as? Int { return Double(value) }
        if let value = dictionary[key] as? NSNumber { return value.doubleValue }
        return nil
    }
}
