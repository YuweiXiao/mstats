import SwiftUI

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
