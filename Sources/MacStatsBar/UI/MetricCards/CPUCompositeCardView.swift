import Foundation
import SwiftUI

enum CPUCompositeCardLayout {
    static let processPanelWidth: CGFloat = 132
    static let maxProcessRows = 10
    static let processRowHeight: CGFloat = 13
    static let processRowSpacing: CGFloat = 6
    static let processPanelVerticalPadding: CGFloat = 10
    static let processPanelHeight: CGFloat = requiredProcessPanelHeight
    static let cpuPanelHeight: CGFloat = processPanelHeight

    static var requiredProcessPanelHeight: CGFloat {
        let rowsHeight = CGFloat(maxProcessRows) * processRowHeight
        let spacingHeight = CGFloat(max(0, maxProcessRows - 1)) * processRowSpacing
        return (processPanelVerticalPadding * 2) + rowsHeight + spacingHeight
    }
}

public struct CPUCompositeCardView: View {
    public let card: PopoverMetricCard
    public let topProcesses: [PopoverTopCPUProcess]

    public init(card: PopoverMetricCard, topProcesses: [PopoverTopCPUProcess]) {
        self.card = card
        self.topProcesses = topProcesses
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 8) {
            CPUCardView(card: card, fixedCardHeight: CPUCompositeCardLayout.cpuPanelHeight)
                .frame(maxWidth: .infinity, alignment: .top)

            processListPanel
        }
    }

    private var processListPanel: some View {
        VStack(alignment: .leading, spacing: CPUCompositeCardLayout.processRowSpacing) {
            ForEach(topProcesses.prefix(CPUCompositeCardLayout.maxProcessRows)) { process in
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
                .frame(height: CPUCompositeCardLayout.processRowHeight, alignment: .leading)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.vertical, CPUCompositeCardLayout.processPanelVerticalPadding)
        .padding(.horizontal, 10)
        .frame(
            width: CPUCompositeCardLayout.processPanelWidth,
            height: CPUCompositeCardLayout.processPanelHeight,
            alignment: .topLeading
        )
        .clipped()
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
