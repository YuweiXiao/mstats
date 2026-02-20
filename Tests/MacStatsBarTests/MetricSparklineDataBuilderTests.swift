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
}
