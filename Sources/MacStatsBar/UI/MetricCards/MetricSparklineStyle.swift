import Foundation
import CoreGraphics

struct MetricSparklineStyle: Equatable {
    enum MarkType: Equatable {
        case line
        case bar
    }

    enum Interpolation: Equatable {
        case catmullRom
        case monotone
        case linear
    }

    let markType: MarkType
    let interpolation: Interpolation
    let plotHeight: CGFloat
    let yDomain: ClosedRange<Double>?
    let showsReferenceLines: Bool
    let referenceLineValues: [Double]
    let showsAreaFill: Bool

    static let defaultCard = MetricSparklineStyle(
        markType: .bar,
        interpolation: .catmullRom,
        plotHeight: 44,
        yDomain: nil,
        showsReferenceLines: false,
        referenceLineValues: [],
        showsAreaFill: false
    )

    static let cpuCard = MetricSparklineStyle(
        markType: .bar,
        interpolation: .monotone,
        plotHeight: 44,
        yDomain: 0...100,
        showsReferenceLines: true,
        referenceLineValues: [0, 50, 100],
        showsAreaFill: true
    )

    static let batteryCard = MetricSparklineStyle(
        markType: .bar,
        interpolation: .catmullRom,
        plotHeight: 44,
        yDomain: 0...100,
        showsReferenceLines: true,
        referenceLineValues: [0, 50, 100],
        showsAreaFill: false
    )

    static func forMetric(_ kind: MetricKind) -> MetricSparklineStyle {
        switch kind {
        case .cpuUsage:
            return .cpuCard
        case .batteryStatus:
            return .batteryCard
        case .memoryUsage, .networkThroughput, .diskUsage:
            return .defaultCard
        }
    }
}
