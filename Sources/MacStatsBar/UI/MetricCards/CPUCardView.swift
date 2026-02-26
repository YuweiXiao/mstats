import SwiftUI

public struct CPUCardView: View {
    private static let expandedSparklineHeight: CGFloat = 104

    public let card: PopoverMetricCard
    private let fixedCardHeight: CGFloat?

    public init(card: PopoverMetricCard, fixedCardHeight: CGFloat? = nil) {
        self.card = card
        self.fixedCardHeight = fixedCardHeight
    }

    public var body: some View {
        MetricCardView(
            card: card,
            accentColor: .red,
            sparklineHeight: Self.expandedSparklineHeight,
            headerLayout: .inline,
            fixedCardHeight: fixedCardHeight
        )
    }
}
