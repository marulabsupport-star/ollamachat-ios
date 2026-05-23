import SwiftUI

/// Side drawer matching Android's ModalNavigationDrawer.
/// Contains: New Chat, Recents, Settings links, and current model display.
struct DrawerView: View {
    let currentRoute: String
    let selectedModelName: String
    let onNewChat: () -> Void
    let onRecents: () -> Void
    let onSettings: () -> Void
    let onFeedback: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("LLM Chat")
                    .font(.headline)
                    .padding(.top, 24)
                Spacer().frame(height: 4)
            }
            .padding(.horizontal, 20)
            
            Divider()
                .padding(.vertical, 12)
            
            // Navigation items
            VStack(spacing: 4) {
                DrawerItem(
                    icon: "plus.circle.fill",
                    title: "New Chat",
                    isSelected: currentRoute == "chat",
                    action: onNewChat
                )
                
                DrawerItem(
                    icon: "clock.arrow.circlepath",
                    title: "Recents",
                    isSelected: currentRoute == "recents",
                    action: onRecents
                )
                
                Divider()
                    .padding(.vertical, 8)
                
                DrawerItem(
                    icon: "gearshape.fill",
                    title: "Settings",
                    isSelected: currentRoute == "settings",
                    action: onSettings
                )
                
                DrawerItem(
                    icon: "envelope.fill",
                    title: "Send Feedback",
                    isSelected: false,
                    action: onFeedback
                )
            }
            .padding(.horizontal, 12)
            
            Spacer()
            
            // Current model display
            HStack {
                Image(systemName: "cpu")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Model: \(selectedModelName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: 280)
        .background(Color(.systemBackground))
    }
}

struct DrawerItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 28)
                
                Text(title)
                    .font(.body)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
    }
}