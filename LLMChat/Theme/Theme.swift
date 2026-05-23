import SwiftUI

// MARK: - Theme Manager

struct ThemeManager: View {
    @Bindable var settings: AppSettings
    
    var body: some View {
        EmptyView()  // Applied via .preferredColorScheme modifier
    }
    
    /// Apply the selected color scheme to the app
    @ViewBuilder
    static func applyTheme(_ settings: AppSettings, content: some View) -> some View {
        content
            .preferredColorScheme(settings.colorScheme)
    }
}

// MARK: - Colors

extension Color {
    static let appBackground = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let userBubble = Color.blue.opacity(0.15)
    static let aiBubble = Color(.secondarySystemBackground)
    
    // Semantic colors
    static let cloudModel = Color.blue
    static let localModel = Color.green
    static let thinkingBackground = Color(.secondarySystemBackground)
    static let errorBackground = Color.red.opacity(0.15)
}