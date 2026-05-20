import SwiftUI

/// Expandable settings card matching Android's SettingsExpandableCard.
/// Shows a title row with icon and chevron, expanding to reveal content.
/// Works as an accordion: managed by parent via expandedCard binding.
struct ExpandableSettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let cardId: String
    @Binding var expandedCard: String?
    let content: Content
    
    init(title: String, icon: String, cardId: String, expandedCard: Binding<String?>, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.cardId = cardId
        self._expandedCard = expandedCard
        self.content = content()
    }
    
    private var isExpanded: Bool {
        expandedCard == cardId
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header row
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    if isExpanded {
                        expandedCard = nil
                    } else {
                        expandedCard = cardId
                    }
                }
            }) {
                HStack(spacing: 14) {
                    // Icon in circle
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: icon)
                            .font(.body)
                            .foregroundStyle(Color.accentColor)
                    }
                    
                    Text(title)
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.25), value: isExpanded)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            
            // Expandable content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    content
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}