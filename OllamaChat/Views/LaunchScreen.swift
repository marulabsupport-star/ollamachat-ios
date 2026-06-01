import SwiftUI

struct LaunchScreen: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            // App icon centered
            Image(uiImage: loadImageFromAssetCatalog() ?? UIImage())
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        }
    }
    
    private func loadImageFromAssetCatalog() -> UIImage? {
        // Load the app icon from the asset catalog by name
        return UIImage(named: "AppIcon")
    }
}

#Preview {
    LaunchScreen()
}