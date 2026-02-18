import Foundation

public enum SummaryFormatter {
    private static let placeholder = "--"
    private static let fixedLocale = Locale(identifier: "en_US_POSIX")
    private static let minIntAsDouble = Double(Int.min)
    private static let maxIntAsDouble = Double(Int.max)

    public static func formatCPU(_ percent: Double?) -> String {
        guard
            let percent = normalized(percent),
            let percentText = safeIntegerString(percent.rounded())
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

    public static func formatNetwork(downloadMBps: Double?, uploadMBps: Double?) -> String {
        let downText = compactNumber(downloadMBps)
        let upText = compactNumber(uploadMBps)
        return "NET \(downText)↓ \(upText)↑ MB/s"
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
            guard let integerText = safeIntegerString(roundedToTenths.rounded()) else {
                return placeholder
            }

            return integerText
        }

        return String(format: "%.1f", locale: fixedLocale, roundedToTenths)
    }

    private static func normalized(_ value: Double?) -> Double? {
        guard let value, value.isFinite else {
            return nil
        }

        return value
    }

    private static func safeIntegerString(_ value: Double) -> String? {
        guard value >= minIntAsDouble, value <= maxIntAsDouble else {
            return nil
        }

        return String(Int(value))
    }
}
