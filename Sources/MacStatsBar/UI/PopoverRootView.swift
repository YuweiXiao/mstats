import Foundation
import SwiftUI

public struct PopoverRootView: View {
    private static let contentWidth: CGFloat = 420

    private let viewModel: PopoverViewModel
    private let onExitRequested: () -> Void
    @Binding private var settings: SettingsState

    public init(
        snapshot: StatsSnapshot?,
        history: [MetricKind: [MetricHistorySample]] = [:],
        onExitRequested: @escaping () -> Void = {},
        settings: Binding<SettingsState>
    ) {
        viewModel = PopoverViewModel(snapshot: snapshot, history: history)
        self.onExitRequested = onExitRequested
        _settings = settings
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(viewModel.cards) { card in
                cardView(for: card)
            }

            Divider()

            SettingsView(settings: $settings)

            Button("Quit mstats") {
                onExitRequested()
            }
            .keyboardShortcut("q")
        }
        .padding(12)
        .frame(width: Self.contentWidth)
    }

    @ViewBuilder
    private func cardView(for card: PopoverMetricCard) -> some View {
        switch card.kind {
        case .cpuUsage:
            CPUCompositeCardView(card: card, topProcesses: viewModel.topCPUProcesses)
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
