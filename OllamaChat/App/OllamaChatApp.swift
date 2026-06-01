import SwiftUI
import SwiftData

@main
struct LocalLLMCloudChatApp: App {
    
    // MARK: - SwiftData
    
    let modelContainer: ModelContainer
    
    // MARK: - Services (created once, shared globally)
    
    static let settings = AppSettings()
    static let connectionConfig = ConnectionConfig()
    static let availableModels = AvailableModels.shared
    
    // MARK: - Privacy Consent & Launch
    
    @AppStorage("privacyConsentGiven") private var privacyConsentGiven = false
    @State private var showSplash = true
    
    // MARK: - Init
    
    init() {
        do {
            let schema = Schema([
                ChatSession.self,
                ChatMessage.self,
                PersonaEntry.self,
                MemoryEntry.self,
                TokenUsageEntry.self
            ])
            self.modelContainer = try ModelContainer(for: schema)
        } catch {
            // Schema mismatch (e.g. after adding new fields) — delete and recreate
            print("ModelContainer error: \(error). Resetting database...")
            do {
                let schema = Schema([
                    ChatSession.self,
                    ChatMessage.self,
                    PersonaEntry.self,
                    MemoryEntry.self,
                    TokenUsageEntry.self
                ])
                // Delete existing database and recreate
                let url = URL.applicationSupportDirectory.appending(path: "default.store")
                try? FileManager.default.removeItem(at: url)
                try? FileManager.default.removeItem(at: url.appendingPathExtension("wal"))
                try? FileManager.default.removeItem(at: url.appendingPathExtension("shm"))
                self.modelContainer = try ModelContainer(for: schema)
            } catch {
                fatalError("Failed to create ModelContainer even after reset: \(error)")
            }
        }
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if privacyConsentGiven {
                    ContentView()
                        .environment(Self.settings)
                        .environment(Self.connectionConfig)
                        .environment(Self.availableModels)
                } else {
                    PrivacyConsentView(onConsentGiven: {
                        withAnimation {
                            privacyConsentGiven = true
                        }
                    })
                }
                
                // Splash screen overlay
                if showSplash {
                    LaunchScreen()
                        .transition(.opacity)
                        .zIndex(1)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showSplash = false
                                }
                            }
                        }
                }
            }
        }
        .modelContainer(modelContainer)
    }
}