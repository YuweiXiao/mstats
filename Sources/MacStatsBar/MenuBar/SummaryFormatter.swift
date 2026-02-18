import Foundation

public enum SummaryFormatter {
    private static let placeholder = "--"

    public static func formatCPU(_ percent: Double?) -> String {
        guard let percent = normalized(percent) else {
            return "CPU \(placeholder)"
        }

        return "CPU \(Int(percent.rounded()))%"
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
        if roundedToTenths == roundedToTenths.rounded() {
            return String(Int(roundedToTenths))
        }

        return String(format: "%.1f", roundedToTenths)
    }

    private static func normalized(_ value: Double?) -> Double? {
        guard let value, value.isFinite else {
            return nil
        }

        return value
    }
}
