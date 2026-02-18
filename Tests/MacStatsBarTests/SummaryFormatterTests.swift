import XCTest
@testable import MacStatsBar

final class SummaryFormatterTests: XCTestCase {
    func testFormatCPURoundsToNearestWholePercent() {
        XCTAssertEqual(SummaryFormatter.formatCPU(23.2), "CPU 23%")
        XCTAssertEqual(SummaryFormatter.formatCPU(23.5), "CPU 24%")
    }

    func testFormatCPUUsesPlaceholderWhenUnavailable() {
        XCTAssertEqual(SummaryFormatter.formatCPU(nil), "CPU --")
    }

    func testFormatMemoryFormatsUsedAndTotalGigabytesCompactly() {
        XCTAssertEqual(
            SummaryFormatter.formatMemory(usedGB: 14.24, totalGB: 31.96),
            "MEM 14.2/32 GB"
        )
        XCTAssertEqual(
            SummaryFormatter.formatMemory(usedGB: 8.0, totalGB: 16.0),
            "MEM 8/16 GB"
        )
    }

    func testFormatMemoryUsesPlaceholdersForUnavailableComponents() {
        XCTAssertEqual(
            SummaryFormatter.formatMemory(usedGB: nil, totalGB: 32.0),
            "MEM --/32 GB"
        )
        XCTAssertEqual(
            SummaryFormatter.formatMemory(usedGB: nil, totalGB: nil),
            "MEM --/-- GB"
        )
    }

    func testFormatNetworkFormatsDownAndUpWithArrowsAndMbps() {
        XCTAssertEqual(
            SummaryFormatter.formatNetwork(downloadMBps: 12.34, uploadMBps: 0.05),
            "NET 12.3↓ 0.1↑ MB/s"
        )
        XCTAssertEqual(
            SummaryFormatter.formatNetwork(downloadMBps: 5.0, uploadMBps: 2.0),
            "NET 5↓ 2↑ MB/s"
        )
    }

    func testFormatNetworkUsesPlaceholdersWhenUnavailable() {
        XCTAssertEqual(
            SummaryFormatter.formatNetwork(downloadMBps: nil, uploadMBps: nil),
            "NET --↓ --↑ MB/s"
        )
    }

    func testDecimalFormattingUsesDotSeparatorDeterministically() {
        XCTAssertEqual(
            SummaryFormatter.formatMemory(usedGB: 1.2, totalGB: 3.4),
            "MEM 1.2/3.4 GB"
        )
        XCTAssertEqual(
            SummaryFormatter.formatNetwork(downloadMBps: 12.34, uploadMBps: 0.56),
            "NET 12.3↓ 0.6↑ MB/s"
        )
    }

    func testOutOfRangeFiniteValuesReturnPlaceholderInsteadOfCrashing() {
        let huge = Double(Int.max) * 2

        XCTAssertEqual(SummaryFormatter.formatCPU(huge), "CPU --")
        XCTAssertEqual(
            SummaryFormatter.formatMemory(usedGB: huge, totalGB: 16),
            "MEM --/16 GB"
        )
        XCTAssertEqual(
            SummaryFormatter.formatNetwork(downloadMBps: huge, uploadMBps: 1),
            "NET --↓ 1↑ MB/s"
        )
    }

    func testNonFiniteValuesAreTreatedAsUnavailable() {
        XCTAssertEqual(SummaryFormatter.formatCPU(.nan), "CPU --")
        XCTAssertEqual(
            SummaryFormatter.formatMemory(usedGB: .infinity, totalGB: 16),
            "MEM --/16 GB"
        )
        XCTAssertEqual(
            SummaryFormatter.formatNetwork(downloadMBps: 4, uploadMBps: -.infinity),
            "NET 4↓ --↑ MB/s"
        )
    }
}
