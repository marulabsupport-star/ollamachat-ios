import SwiftUI
import SwiftData

/// Shows weekly token usage as a compact bar chart in the drawer.
struct TokenUsageBar: View {
    @Environment(\.modelContext) private var modelContext
    @State private var usage = TokenUsageRepository.WeekUsage()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("This Week")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(usage.total) tokens")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            
            if usage.total > 0 {
                // Proportional bar
                HStack(spacing: 1) {
                    BarSegment(count: usage.cloudInput, total: usage.total, color: .blue)
                    BarSegment(count: usage.cloudOutput, total: usage.total, color: .cyan)
                    BarSegment(count: usage.localInput, total: usage.total, color: .orange)
                    BarSegment(count: usage.localOutput, total: usage.total, color: .yellow)
                }
                .frame(height: 10)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                
                // Legend
                HStack(spacing: 12) {
                    if usage.totalCloud > 0 {
                        LegendDot(color: .blue, label: "Cloud \(usage.totalCloud)")
                    }
                    if usage.totalLocal > 0 {
                        LegendDot(color: .orange, label: "Local \(usage.totalLocal)")
                    }
                }
                .font(.caption2)
            } else {
                Text("No usage yet this week")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .onAppear { loadUsage() }
    }
    
    private func loadUsage() {
        let repo = TokenUsageRepository(modelContext: modelContext)
        usage = repo.getCurrentWeekUsage()
    }
}

struct BarSegment: View {
    let count: Int
    let total: Int
    let color: Color
    
    var body: some View {
        if count > 0, total > 0 {
            Rectangle()
                .fill(color)
                .frame(maxWidth: .infinity)
                .frame(minWidth: 2)
        }
    }
}

struct LegendDot: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }
}