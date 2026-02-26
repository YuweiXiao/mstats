import Foundation
import CoreGraphics

struct MetricSparklineStyle: Equatable {
    enum Interpolation: Equatable {
        case catmullRom
        case monotone
        case linear
    }

    let interpolation: Interpolation
    let plotHeight: CGFloat
    let yDomain: ClosedRange<Double>?
    let showsReferenceLines: Bool
    let referenceLineValues: [Double]
    let showsAreaFill: Bool

    static let defaultCard = MetricSparklineStyle(
        interpolation: .catmullRom,
        plotHeight: 34,
        yDomain: nil,
        showsReferenceLines: false,
        referenceLineValues: [],
        showsAreaFill: false
    )

    static let cpuCard = MetricSparklineStyle(
        interpolation: .monotone,
        plotHeight: 44,
        yDomain: 0...100,
        showsReferenceLines: true,
        referenceLineValues: [0, 50, 100],
        showsAreaFill: true
    )

    static func forMetric(_ kind: MetricKind) -> MetricSparklineStyle {
        switch kind {
        case .cpuUsage:
            return .cpuCard
        case .memoryUsage, .networkThroughput, .batteryStatus, .diskUsage:
            return .defaultCard
        }
    }
}
