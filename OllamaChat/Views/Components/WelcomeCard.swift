import SwiftUI

struct WelcomeCard: View {
    var settings: AppSettings?
    var onNavigateToSettings: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue.gradient)
            
            if settings == nil {
                // Not configured — show API key setup prompt
                Text("Get Started")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Configure your API key or local server to start chatting with AI.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: { onNavigateToSettings?() }) {
                    Label("Open Settings", systemImage: "gearshape.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            } else {
                Text("Welcome to LocalLLM Chat")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Chat with AI models locally or in the cloud.\nSelect a model above to get started.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.vertical, 24)
    }
}