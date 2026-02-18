import SwiftUI

public struct PopoverRootView: View {
    private let viewModel: PopoverViewModel
    @State private var settings: SettingsState

    public init(
        snapshot: StatsSnapshot?,
        initialSettings: SettingsState = .defaultValue
    ) {
        viewModel = PopoverViewModel(snapshot: snapshot)
        _settings = State(initialValue: initialSettings)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(viewModel.cards) { card in
                cardView(for: card)
            }

            Divider()

            SettingsView(settings: $settings)
                .frame(minHeight: 260)
        }
        .padding(12)
        .frame(width: 340)
    }

    @ViewBuilder
    private func cardView(for card: PopoverMetricCard) -> some View {
        switch card.kind {
        case .cpuUsage:
            CPUCardView(card: card)
        case .memoryUsage:
            MemoryCardView(card: card)
        case .networkThroughput:
            NetworkCardView(card: card)
        case .batteryStatus:
            BatteryCardView(card: card)
        case .diskUsage:
            DiskCardView(card: card)
        }
    }
}
