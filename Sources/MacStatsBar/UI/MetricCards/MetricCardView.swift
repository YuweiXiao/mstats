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
    public enum HeaderLayout {
        case stacked
        case inline
    }

    public let card: PopoverMetricCard
    private let accentColor: Color
    private let sparklineStyle: MetricSparklineStyle
    private let sparklineHeight: CGFloat
    private let headerLayout: HeaderLayout
    private let minimumCardHeight: CGFloat?

    public init(
        card: PopoverMetricCard,
        accentColor: Color = .accentColor,
        sparklineHeight: CGFloat? = nil,
        headerLayout: HeaderLayout = .stacked,
        minimumCardHeight: CGFloat? = nil
    ) {
        let sparklineStyle = MetricSparklineStyle.forMetric(card.kind)
        self.card = card
        self.accentColor = accentColor
        self.sparklineStyle = sparklineStyle
        self.sparklineHeight = sparklineHeight ?? sparklineStyle.plotHeight
        self.headerLayout = headerLayout
        self.minimumCardHeight = minimumCardHeight
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            headerView
            if minimumCardHeight != nil, !card.trendSeries.isEmpty {
                Spacer(minLength: 0)
            }
            if !card.trendSeries.isEmpty {
                MetricSparklineView(
                    series: card.trendSeries,
                    accentColor: accentColor,
                    style: sparklineStyle
                )
                    .frame(height: sparklineHeight)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: minimumCardHeight, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(accentColor.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(accentColor.opacity(0.25), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var headerView: some View {
        switch headerLayout {
        case .stacked:
            VStack(alignment: .leading, spacing: 2) {
                Text(card.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(card.text)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.primary)
            }
        case .inline:
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(card.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(card.text)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.primary)
            }
        }
    }
}

private struct MetricSparklineView: View {
    let series: [PopoverTrendSeries]
    let accentColor: Color
    let style: MetricSparklineStyle

    private var points: [MetricSparklinePoint] {
        MetricSparklineDataBuilder.buildPoints(from: series)
    }

    var body: some View {
        chartContent
    }

    @ViewBuilder
    private var chartContent: some View {
        if let yDomain = style.yDomain {
            baseChart
                .chartYScale(domain: yDomain)
        } else {
            baseChart
        }
    }

    private var baseChart: some View {
        let seriesColors = buildSeriesColors()

        return Chart {
            ForEach(referenceLineValues, id: \.self) { value in
                RuleMark(y: .value("Reference", value))
                    .foregroundStyle(accentColor.opacity(value == 50 ? 0.16 : 0.10))
                    .lineStyle(StrokeStyle(lineWidth: 0.6))
            }

            if style.showsAreaFill {
                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    AreaMark(
                        x: .value("Sample", point.sampleIndex),
                        y: .value("Value", point.value),
                        series: .value("Series", point.seriesLabel)
                    )
                    .interpolationMethod(chartInterpolationMethod)
                    .foregroundStyle(color(for: point.seriesLabel, using: seriesColors).opacity(0.10))
                }
            }

            ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                if style.showsAreaFill {
                    LineMark(
                        x: .value("Sample", point.sampleIndex),
                        y: .value("Value", point.value),
                        series: .value("Series", point.seriesLabel)
                    )
                    .interpolationMethod(chartInterpolationMethod)
                    .lineStyle(StrokeStyle(lineWidth: 1.6))
                    .foregroundStyle(color(for: point.seriesLabel, using: seriesColors))
                } else {
                    LineMark(
                        x: .value("Sample", point.sampleIndex),
                        y: .value("Value", point.value),
                        series: .value("Series", point.seriesLabel)
                    )
                    .interpolationMethod(chartInterpolationMethod)
                    .foregroundStyle(color(for: point.seriesLabel, using: seriesColors))
                }
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartPlotStyle { plotArea in
            plotArea.background(.clear)
        }
    }

    private var chartInterpolationMethod: InterpolationMethod {
        switch style.interpolation {
        case .catmullRom:
            return .catmullRom
        case .monotone:
            return .monotone
        case .linear:
            return .linear
        }
    }

    private var referenceLineValues: [Double] {
        guard style.showsReferenceLines else {
            return []
        }

        guard let yDomain = style.yDomain else {
            return style.referenceLineValues
        }

        return style.referenceLineValues.filter(yDomain.contains)
    }

    private func color(for label: String, using seriesColors: [String: Color]) -> Color {
        seriesColors[label] ?? accentColor
    }

    private func buildSeriesColors() -> [String: Color] {
        var colors: [String: Color] = [:]
        colors.reserveCapacity(series.count)
        for (index, trend) in series.enumerated() {
            if colors[trend.label] == nil {
                colors[trend.label] = index == 0 ? accentColor : accentColor.opacity(0.6)
            }
        }
        return colors
    }
}
