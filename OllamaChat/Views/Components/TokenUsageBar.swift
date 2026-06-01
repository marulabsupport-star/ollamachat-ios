import SwiftUI
import SwiftData

/// Shows weekly token usage as a stacked bar chart in the drawer.
/// Output tokens fill the bar fully, input tokens overlay on top in a different color.
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
                // Stacked bar: output fills bar, input overlays on top
                VStack(spacing: 3) {
                    // Cloud bar
                    if usage.totalCloud > 0 {
                        StackedBar(
                            input: usage.cloudInput,
                            output: usage.cloudOutput,
                            inputColor: .cyan,
                            outputColor: .blue,
                            total: usage.total
                        )
                    }
                    // Local bar
                    if usage.totalLocal > 0 {
                        StackedBar(
                            input: usage.localInput,
                            output: usage.localOutput,
                            inputColor: .yellow,
                            outputColor: .orange,
                            total: usage.total
                        )
                    }
                }
                .frame(height: usage.totalCloud > 0 && usage.totalLocal > 0 ? 22 : 12)
                
                // Legend
                HStack(spacing: 12) {
                    if usage.totalCloud > 0 {
                        HStack(spacing: 4) {
                            LegendDot(color: .blue, label: "Out")
                            LegendDot(color: .cyan, label: "In")
                            Text("Cloud")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if usage.totalLocal > 0 {
                        HStack(spacing: 4) {
                            LegendDot(color: .orange, label: "Out")
                            LegendDot(color: .yellow, label: "In")
                            Text("Local")
                                .foregroundStyle(.secondary)
                        }
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

/// A single stacked bar where output fills the full width and input overlays on top.
struct StackedBar: View {
    let input: Int
    let output: Int
    let inputColor: Color
    let outputColor: Color
    let total: Int
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Output fills full width (background)
                RoundedRectangle(cornerRadius: 4)
                    .fill(outputColor.opacity(0.85))
                
                // Input overlays from left (proportional width)
                if input > 0, total > 0 {
                    let inputWidth = max(CGFloat(input) / CGFloat(total) * geo.size.width, 2)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(inputColor.opacity(0.85))
                        .frame(width: inputWidth)
                }
            }
        }
    }
}

struct LegendDot: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .foregroundStyle(.secondary)
        }
    }
}