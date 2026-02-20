import SwiftUI
import Charts

struct MetricSparklinePoint: Equatable {
    let seriesLabel: String
    let sampleIndex: Int
    let value: Double
}

enum MetricSparklineDataBuilder {
    static func buildPoints(from series: [PopoverTrendSeries]) -> [MetricSparklinePoint] {
        series.flatMap { trend in
            trend.points.enumerated().map { index, value in
                MetricSparklinePoint(seriesLabel: trend.label, sampleIndex: index, value: value)
            }
        }
    }
}

public struct MetricCardView: View {
    public let card: PopoverMetricCard
    private let accentColor: Color

    public init(card: PopoverMetricCard, accentColor: Color = .accentColor) {
        self.card = card
        self.accentColor = accentColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(card.title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(card.text)
                .font(.headline.monospacedDigit())
                .foregroundStyle(.primary)
            if !card.trendSeries.isEmpty {
                MetricSparklineView(series: card.trendSeries, accentColor: accentColor)
                    .frame(height: 34)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(accentColor.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(accentColor.opacity(0.25), lineWidth: 1)
        )
    }
}

private struct MetricSparklineView: View {
    let series: [PopoverTrendSeries]
    let accentColor: Color
    private var points: [MetricSparklinePoint] {
        MetricSparklineDataBuilder.buildPoints(from: series)
    }

    var body: some View {
        Chart {
            ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                LineMark(
                    x: .value("Sample", point.sampleIndex),
                    y: .value("Value", point.value),
                    series: .value("Series", point.seriesLabel)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(color(for: point.seriesLabel))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartPlotStyle { plotArea in
            plotArea.background(.clear)
        }
    }

    private func color(for label: String) -> Color {
        let index = series.firstIndex(where: { $0.label == label }) ?? 0
        if index == 0 {
            return accentColor
        }
        return accentColor.opacity(0.6)
    }
}
