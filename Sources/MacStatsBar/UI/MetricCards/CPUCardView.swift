import SwiftUI

public struct CPUCardView: View {
    public let card: PopoverMetricCard

    public init(card: PopoverMetricCard) {
        self.card = card
    }

    public var body: some View {
        MetricCardView(card: card, accentColor: .red)
    }
}
