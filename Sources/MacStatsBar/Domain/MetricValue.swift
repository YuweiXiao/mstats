public struct MetricValue: Codable, Equatable {
    public enum Unit: String, Codable, Equatable {
        case percent
        case gigabytes
        case megabytesPerSecond
    }

    public let primaryValue: Double
    public let secondaryValue: Double?
    public let unit: Unit

    public init(primaryValue: Double, secondaryValue: Double?, unit: Unit) {
        self.primaryValue = primaryValue
        self.secondaryValue = secondaryValue
        self.unit = unit
    }
}
