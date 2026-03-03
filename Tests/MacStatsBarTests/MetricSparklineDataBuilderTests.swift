import XCTest
@testable import MacStatsBar

final class MetricSparklineDataBuilderTests: XCTestCase {
    func testBuildPointsPreservesSeriesLabelsForLineGrouping() {
        let series = [
            PopoverTrendSeries(label: "Down", points: [1.2, 1.6]),
            PopoverTrendSeries(label: "Up", points: [0.2, 0.4])
        ]

        let points = MetricSparklineDataBuilder.buildPoints(from: series)

        XCTAssertEqual(points.count, 4)
        XCTAssertEqual(points.map(\.seriesLabel), ["Down", "Down", "Up", "Up"])
        XCTAssertEqual(points.map(\.sampleIndex), [0, 1, 0, 1])
        XCTAssertEqual(points.map(\.value), [1.2, 1.6, 0.2, 0.4])
    }

    func testBuildPointsReturnsEmptyForNoSeries() {
        XCTAssertEqual(MetricSparklineDataBuilder.buildPoints(from: []), [])
    }

    func testBuildPointsKeepsLatestSamplesWhenSeriesExceedsVisibleSlots() {
        let points = (0..<120).map(Double.init)
        let series = [PopoverTrendSeries(label: "Usage", points: points)]

        let built = MetricSparklineDataBuilder.buildPoints(from: series, maxPointsPerSeries: 60)

        XCTAssertEqual(built.count, 60)
        XCTAssertEqual(built.first?.value, 60)
        XCTAssertEqual(built.last?.value, 119)
    }

    func testBuildPointsShiftLeftByOneWhenNewSampleArrives() {
        let previous = MetricSparklineDataBuilder.buildPoints(
            from: [PopoverTrendSeries(label: "Usage", points: (0..<120).map(Double.init))],
            maxPointsPerSeries: 60
        )
        let next = MetricSparklineDataBuilder.buildPoints(
            from: [PopoverTrendSeries(label: "Usage", points: (0..<121).map(Double.init))],
            maxPointsPerSeries: 60
        )

        XCTAssertEqual(previous.dropFirst().map(\.value), next.dropLast().map(\.value))
        XCTAssertEqual(next.last?.value, 120)
    }

    func testBuildPointsRightAlignsWhenSeriesHasFewerPointsThanVisibleSlots() {
        let series = [PopoverTrendSeries(label: "Usage", points: [10, 20, 30])]

        let built = MetricSparklineDataBuilder.buildPoints(
            from: series,
            maxPointsPerSeries: 60,
            trailingSlotCount: 60
        )

        XCTAssertEqual(built.count, 3)
        XCTAssertEqual(built.map(\.sampleIndex), [57, 58, 59])
        XCTAssertEqual(built.map(\.value), [10, 20, 30])
    }

    func testSparklineStyleForCPUUsesFixedPercentDomainAndReferenceLines() {
        let style = MetricSparklineStyle.forMetric(.cpuUsage)

        XCTAssertEqual(style.yDomain, 0...100)
        XCTAssertTrue(style.showsReferenceLines)
    }

    func testSparklineStyleForCPUUsesNonOvershootingInterpolationAndTallerPlotHeight() {
        let style = MetricSparklineStyle.forMetric(.cpuUsage)

        XCTAssertEqual(style.interpolation, .monotone)
        XCTAssertGreaterThan(style.plotHeight, MetricSparklineStyle.defaultCard.plotHeight)
    }

    func testSparklineStyleForCPUUsesExactPercentReferenceAnchors() {
        let style = MetricSparklineStyle.forMetric(.cpuUsage)

        XCTAssertEqual(style.referenceLineValues, [0, 50, 100])
    }

    func testSparklineStyleAreaFillIsEnabledOnlyForCPU() {
        let cpuStyle = MetricSparklineStyle.forMetric(.cpuUsage)

        XCTAssertTrue(cpuStyle.showsAreaFill)
        XCTAssertFalse(MetricSparklineStyle.defaultCard.showsAreaFill)
    }

    func testSparklineStyleUsesBarMarksForAllMetrics() {
        for kind in MetricKind.allCases {
            XCTAssertEqual(MetricSparklineStyle.forMetric(kind).markType, .bar)
        }
    }

    func testSparklineStyleForNonCPUMetricsKeepsDefaultValues() {
        let nonCPUKinds = MetricKind.allCases.filter { $0 != .cpuUsage }

        for kind in nonCPUKinds {
            XCTAssertEqual(MetricSparklineStyle.forMetric(kind), .defaultCard, "Expected default style for \(kind)")
        }
    }
}
