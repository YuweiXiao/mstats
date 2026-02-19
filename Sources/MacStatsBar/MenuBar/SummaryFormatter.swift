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
        let downText = compactNumber(downloadMBps)
        let upText = compactNumber(uploadMBps)
        return "NET \(downText)↓ \(upText)↑ MB/s"
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
        let downText = compactClampedNumber(downloadMBps, maxValue: 99.9)
        let upText = compactClampedNumber(uploadMBps, maxValue: 99.9)
        return "\(downText)↓\(upText)↑"
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

    private static func normalized(_ value: Double?) -> Double? {
        guard let value, value.isFinite else {
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
