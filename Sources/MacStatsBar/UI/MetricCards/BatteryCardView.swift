import SwiftUI

public struct BatteryCardView: View {
    public let card: PopoverMetricCard

    public init(card: PopoverMetricCard) {
        self.card = card
    }

    public var body: some View {
        MetricCardView(card: card, accentColor: .green)
    }
}
