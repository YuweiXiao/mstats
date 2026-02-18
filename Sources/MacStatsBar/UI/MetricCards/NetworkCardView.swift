import SwiftUI

public struct NetworkCardView: View {
    public let card: PopoverMetricCard

    public init(card: PopoverMetricCard) {
        self.card = card
    }

    public var body: some View {
        MetricCardView(card: card, accentColor: .mint)
    }
}
