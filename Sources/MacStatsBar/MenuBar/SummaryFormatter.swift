import Foundation

public enum SummaryFormatter {
    private static let placeholder = "--"
    private static let fixedLocale = Locale(identifier: "en_US_POSIX")

    public static func formatCPU(_ percent: Double?) -> String {
        guard
            let percent = normalized(percent),
            let percentText = safeIntegerString(percent)
        else {
            return "CPU \(placeholder)"
        }

        return "CPU \(percentText)%"
    }

    public static func formatMemory(usedGB: Double?, totalGB: Double?) -> String {
        let usedText = compactNumber(usedGB)
        let totalText = compactNumber(totalGB)
        return "MEM \(usedText)/\(totalText) GB"
    }

    public static func formatBattery(_ percent: Double?) -> String {
        guard
            let percent = normalized(percent),
            let percentText = safeIntegerString(percent)
        else {
            return "BAT \(placeholder)"
        }

        return "BAT \(percentText)%"
    }

    public static func formatDisk(usedGB: Double?, totalGB: Double?) -> String {
        let usedText = compactNumber(usedGB)
        let totalText = compactNumber(totalGB)
        return "DSK \(usedText)/\(totalText) GB"
    }

    public static func formatNetwork(downloadMBps: Double?, uploadMBps: Double?) -> String {
        let download = normalizedWithinIntegerBounds(downloadMBps)
        let upload = normalizedWithinIntegerBounds(uploadMBps)

        guard download != nil || upload != nil else {
            return "NET \(placeholder)↓ \(placeholder)↑ MB/s"
        }

        let unit = compactThroughputUnit(downloadMBps: download, uploadMBps: upload)
        let downText = detailedThroughput(downloadMBps: download, unit: unit)
        let upText = detailedThroughput(downloadMBps: upload, unit: unit)
        return "NET \(downText)↓ \(upText)↑ \(unit.rawValue)"
    }

    static func compactPercentValue(_ percent: Double?) -> String {
        guard
            let percent = normalized(percent),
            let percentText = safeIntegerString(min(max(percent, 0), 99))
        else {
            return placeholder
        }

        return "\(percentText)%"
    }

    static func compactPairValue(first: Double?, second: Double?, suffix: String = "") -> String {
        let firstText = compactClampedNumber(first, maxValue: 99.9)
        let secondText = compactClampedNumber(second, maxValue: 99.9)
        return "\(firstText)/\(secondText)\(suffix)"
    }

    static func compactNetworkValue(downloadMBps: Double?, uploadMBps: Double?) -> String {
        let download = normalized(downloadMBps)
        let upload = normalized(uploadMBps)

        guard download != nil || upload != nil else {
            return "\(placeholder)↓\(placeholder)↑MB/s"
        }

        let unit = compactThroughputUnit(downloadMBps: download, uploadMBps: upload)
        let downText = compactThroughput(downloadMBps: download, unit: unit)
        let upText = compactThroughput(downloadMBps: upload, unit: unit)
        return "\(downText)↓\(upText)↑\(unit.rawValue)"
    }

    static func compactNetworkValueMultiline(downloadMBps: Double?, uploadMBps: Double?) -> String {
        let download = normalized(downloadMBps)
        let upload = normalized(uploadMBps)

        guard download != nil || upload != nil else {
            return "\(placeholder)↓MB/s\n\(placeholder)↑MB/s"
        }

        let unit = compactThroughputUnit(downloadMBps: download, uploadMBps: upload)
        let downText = compactThroughput(downloadMBps: download, unit: unit)
        let upText = compactThroughput(downloadMBps: upload, unit: unit)
        return "\(downText)↓\(unit.rawValue)\n\(upText)↑\(unit.rawValue)"
    }

    static func compactSummaryPlaceholder() -> String {
        placeholder
    }

    private static func compactNumber(_ value: Double?) -> String {
        guard let value = normalized(value) else {
            return placeholder
        }

        let roundedToTenths = (value * 10).rounded() / 10
        guard roundedToTenths.isFinite else {
            return placeholder
        }

        if roundedToTenths == roundedToTenths.rounded() {
            guard let integerText = safeIntegerString(roundedToTenths) else {
                return placeholder
            }

            return integerText
        }

        return String(format: "%.1f", locale: fixedLocale, roundedToTenths)
    }

    private static func compactClampedNumber(_ value: Double?, maxValue: Double) -> String {
        guard let value = normalized(value), value >= 0 else {
            return placeholder
        }

        return compactNumber(min(value, maxValue))
    }

    private enum ThroughputUnit: String {
        case kilobytesPerSecond = "KB/s"
        case megabytesPerSecond = "MB/s"
        case gigabytesPerSecond = "GB/s"
    }

    private static func compactThroughputUnit(downloadMBps: Double?, uploadMBps: Double?) -> ThroughputUnit {
        let maxValue = max(downloadMBps ?? 0, uploadMBps ?? 0)

        if maxValue >= 1024 {
            return .gigabytesPerSecond
        }
        if maxValue < 1 {
            return .kilobytesPerSecond
        }
        return .megabytesPerSecond
    }

    private static func compactThroughput(downloadMBps: Double?, unit: ThroughputUnit) -> String {
        guard let value = normalized(downloadMBps), value >= 0 else {
            return placeholder
        }

        let normalizedValue: Double
        switch unit {
        case .kilobytesPerSecond:
            normalizedValue = value * 1024
        case .megabytesPerSecond:
            normalizedValue = value
        case .gigabytesPerSecond:
            normalizedValue = value / 1024
        }

        return compactThroughputNumber(min(normalizedValue, 999.9))
    }

    private static func detailedThroughput(downloadMBps: Double?, unit: ThroughputUnit) -> String {
        guard let value = normalizedWithinIntegerBounds(downloadMBps), value >= 0 else {
            return placeholder
        }

        let convertedValue: Double
        switch unit {
        case .kilobytesPerSecond:
            convertedValue = value * 1024
        case .megabytesPerSecond:
            convertedValue = value
        case .gigabytesPerSecond:
            convertedValue = value / 1024
        }

        return compactThroughputNumber(convertedValue)
    }

    private static func compactThroughputNumber(_ value: Double) -> String {
        guard value.isFinite else {
            return placeholder
        }

        if value >= 1 {
            return safeIntegerString(value.rounded()) ?? placeholder
        }

        return compactNumber(value)
    }

    private static func normalized(_ value: Double?) -> Double? {
        guard let value, value.isFinite else {
            return nil
        }

        return value
    }

    private static func normalizedWithinIntegerBounds(_ value: Double?) -> Double? {
        guard let value = normalized(value), abs(value) <= Double(Int.max) else {
            return nil
        }
        return value
    }

    private static func safeIntegerString(_ value: Double) -> String? {
        let roundedIntegral = value.rounded()
        guard roundedIntegral.isFinite else {
            return nil
        }

        guard let integerValue = Int(exactly: roundedIntegral) else {
            return nil
        }

        return String(integerValue)
    }
}
