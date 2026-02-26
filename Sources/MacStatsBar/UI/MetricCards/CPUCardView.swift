import SwiftUI

public struct CPUCardView: View {
    private static let expandedSparklineHeight: CGFloat = 104

    public let card: PopoverMetricCard
    private let minimumCardHeight: CGFloat?

    public init(card: PopoverMetricCard, minimumCardHeight: CGFloat? = nil) {
        self.card = card
        self.minimumCardHeight = minimumCardHeight
    }

    public var body: some View {
        MetricCardView(
            card: card,
            accentColor: .red,
            sparklineHeight: Self.expandedSparklineHeight,
            headerLayout: .inline,
            minimumCardHeight: minimumCardHeight
        )
    }
}
