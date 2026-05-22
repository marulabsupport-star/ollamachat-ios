import SwiftUI

/// In-app Privacy Policy page.
/// Also serves as the content for the App Store Connect privacy policy URL.
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.title.bold())
                    .padding(.top, 16)
                
                Text("Last updated: May 2026")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                policySection("1. Overview") {
                    Text("OllamaChat (\"the App\") is a client application that connects to Ollama servers. The App itself does not collect, store, or transmit any personal data to its developer. All data processing occurs between your device and the Ollama server you choose to connect to.")
                }
                
                policySection("2. Data Collected by the App") {
                    VStack(alignment: .leading, spacing: 8) {
                        bullet("Chat messages: Stored locally on your device using SwiftData. Not transmitted to the app developer.")
                        bullet("API keys: Stored securely in your device's Keychain. Never sent anywhere except the server they are intended for.")
                        bullet("Server URLs: Stored locally in UserDefaults to remember your configuration.")
                        bullet("Settings preferences (theme, default model, etc.): Stored locally in UserDefaults.")
                    }
                }
                
                policySection("3. Data Shared with Third-Party Services") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("When you use the App, data is sent to third-party services that you configure:")
                        
                        thirdPartyBlock(
                            name: "Ollama Server (Local or Cloud)",
                            description: "Your Ollama server, configured by you",
                            dataSent: ["Chat messages and prompts", "Images (when using vision-capable models)", "System prompts"],
                            purpose: "To generate AI responses to your queries"
                        )
                        
                        thirdPartyBlock(
                            name: "Ollama Cloud API",
                            description: "Ollama, Inc. (https://ollama.com)",
                            dataSent: ["Chat messages and prompts", "Images (when using vision-capable models)", "API key for authentication"],
                            purpose: "To access cloud-hosted AI models"
                        )
                        
                        thirdPartyBlock(
                            name: "Tavily Search API",
                            description: "Tavily, Inc. (https://tavily.com)",
                            dataSent: ["Search queries derived from your messages"],
                            purpose: "To provide web search results for grounded responses"
                        )
                    }
                }
                
                policySection("4. Your Consent") {
                    Text("Before any data is sent to a third-party service, the App clearly explains what data will be sent and to whom, and asks for your explicit permission. You can review and change your server configuration at any time in Settings.")
                }
                
                policySection("5. Data Retention") {
                    VStack(alignment: .leading, spacing: 8) {
                        bullet("Local chat history: Stored on your device until you delete it. You can clear all data in Settings → Clear All Chat Data.")
                        bullet("API keys: Stored in Keychain until you delete them from Settings.")
                        bullet("Third-party services: Data retention is governed by each service's own privacy policy.")
                    }
                }
                
                policySection("6. Third-Party Privacy Policies") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Each third-party service has its own privacy policy regarding how it handles your data:")
                        
                        Link("Ollama Privacy Policy", destination: URL(string: "https://ollama.com/privacy")!)
                        Link("Tavily Privacy Policy", destination: URL(string: "https://tavily.com/privacy")!)
                    }
                }
                
                policySection("7. No Tracking or Analytics") {
                    Text("The App does not include any analytics, tracking, or advertising SDKs. The App developer has no access to your data, conversations, or server configurations.")
                }
                
                policySection("8. Children's Privacy") {
                    Text("The App is not directed at children under 13. The App does not knowingly collect personal information from children.")
                }
                
                policySection("9. Changes to This Policy") {
                    Text("This privacy policy may be updated from time to time. Changes will be reflected in the \"Last updated\" date above. Continued use of the App after changes constitutes acceptance of the updated policy.")
                }
                
                policySection("10. Contact") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("If you have questions about this privacy policy or your data, please contact:")
                        Link("marulabsupport@gmail.com", destination: URL(string: "mailto:marulabsupport@gmail.com")!)
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("Privacy Policy")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    // MARK: - Components
    
    private func policySection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
    }
    
    private func thirdPartyBlock(name: String, description: String, dataSent: [String], purpose: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name)
                .font(.subheadline.bold())
            Text(description)
                .font(.caption)
                .foregroundStyle(.tertiary)
            Text("Data sent:")
                .font(.caption.bold())
            ForEach(dataSent, id: \.self) { item in
                HStack(alignment: .top, spacing: 6) {
                    Text("•").font(.caption)
                    Text(item).font(.caption)
                }
            }
            Text("Purpose: \(purpose)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}