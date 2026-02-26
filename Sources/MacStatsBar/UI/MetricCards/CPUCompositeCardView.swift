import Foundation
import SwiftUI

public struct CPUCompositeCardView: View {
    private static let topProcessPanelWidth: CGFloat = 132
    private static let topProcessPanelHeight: CGFloat = 172

    public let card: PopoverMetricCard
    public let topProcesses: [PopoverTopCPUProcess]

    public init(card: PopoverMetricCard, topProcesses: [PopoverTopCPUProcess]) {
        self.card = card
        self.topProcesses = topProcesses
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 8) {
            CPUCardView(card: card, minimumCardHeight: Self.topProcessPanelHeight)
                .frame(maxWidth: .infinity, alignment: .top)

            processListPanel
                .frame(width: Self.topProcessPanelWidth, height: Self.topProcessPanelHeight, alignment: .topLeading)
        }
    }

    private var processListPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(topProcesses) { process in
                HStack(spacing: 6) {
                    Text(process.name)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer(minLength: 4)
                    Text(Self.formatCPUPercent(process.cpuUsagePercent))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .font(.caption2)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.red.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.red.opacity(0.16), lineWidth: 1)
        )
    }

    private static func formatCPUPercent(_ value: Double) -> String {
        if value >= 10 {
            return String(format: "%.0f%%", value)
        }
        return String(format: "%.1f%%", value)
    }
}
