import XCTest
@testable import MacStatsBar

final class MetricCardLayoutRulesTests: XCTestCase {
    func testFixedHeightTrendUsesFlexibleHeight() {
        XCTAssertTrue(
            MetricCardLayoutRules.shouldUseFlexibleTrendHeight(
                fixedCardHeight: 200,
                hasTrendSeries: true
            )
        )
    }

    func testNoFixedHeightUsesConfiguredTrendHeight() {
        XCTAssertFalse(
            MetricCardLayoutRules.shouldUseFlexibleTrendHeight(
                fixedCardHeight: nil,
                hasTrendSeries: true
            )
        )
    }

    func testFixedHeightWithoutTrendSeriesDoesNotUseFlexibleHeight() {
        XCTAssertFalse(
            MetricCardLayoutRules.shouldUseFlexibleTrendHeight(
                fixedCardHeight: 200,
                hasTrendSeries: false
            )
        )
    }
}
