import SwiftUI

struct LaunchScreen: View {
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                // App icon
                Image("icon_1024x1024")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                
                // App name
                Text("Local LLM Cloud Chat")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // Tagline at bottom
                Text("Connect. Chat. Create.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    LaunchScreen()
}