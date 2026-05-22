import SwiftUI

/// First-launch privacy consent screen.
/// Shows what data is sent, to whom, and asks for permission before proceeding.
/// Required by App Store Guidelines 5.1.1(i) and 5.1.2(i).
struct PrivacyConsentView: View {
    @Environment(\.colorScheme) private var colorScheme
    var onConsentGiven: () -> Void
    
    @State private var isAgreed = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, 40)
                
                // Title
                VStack(spacing: 8) {
                    Text("Privacy & Data Sharing")
                        .font(.title.bold())
                    
                    Text("Before you start, please review how your data is handled.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Data disclosure sections
                dataSection(
                    icon: "bubble.left.and.bubble.right",
                    title: "What Data Is Sent",
                    details: [
                        "Chat messages you type",
                        "Images you attach (if using a vision-capable model)",
                        "System prompts you configure",
                        "Web search queries (if web search is enabled)"
                    ]
                )
                
                dataSection(
                    icon: "server.rack",
                    title: "Where Your Data Goes",
                    details: [
                        "Your own Ollama server (local or cloud)",
                        "Ollama Cloud API (if you provide an API key)",
                        "Tavily Search API (if you enable web search)"
                    ]
                )
                
                dataSection(
                    icon: "lock.shield",
                    title: "How Your Data Is Protected",
                    details: [
                        "Chat history is stored only on your device",
                        "API keys are stored in your device's Keychain",
                        "No data is collected by this app beyond what you send to your chosen server",
                        "You choose which server to connect to — the app does not send data anywhere without your configuration"
                    ]
                )
                
                // Third-party notice
                VStack(alignment: .leading, spacing: 8) {
                    Label("Third-Party Services", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                    
                    Text("When you connect to an Ollama server or Ollama Cloud API, your messages are sent to that service for processing. That service may have its own privacy policy regarding how it handles your data. This app does not control third-party data practices.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 16)
                
                // Agreement toggle
                Toggle(isOn: $isAgreed) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("I understand and agree")
                            .font(.subheadline.bold())
                        Text("My chat messages will be sent to the Ollama server I configure. I can change server settings at any time in Settings.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // Continue button
                Button {
                    if isAgreed {
                        AppSettings.markPrivacyConsentGiven()
                        onConsentGiven()
                    }
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isAgreed)
                .padding(.horizontal, 16)
                
                // Privacy Policy link
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    Text("Read full Privacy Policy")
                        .font(.caption)
                        .underline()
                }
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Data Section Component
    
    private func dataSection(icon: String, title: String, details: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
            
            ForEach(details, id: \.self) { detail in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(detail)
                        .font(.caption)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
    }
}

#Preview {
    NavigationStack {
        PrivacyConsentView(onConsentGiven: {})
    }
}