import SwiftUI
import SwiftData

@main
struct OllamaChatApp: App {
    
    // MARK: - SwiftData
    
    let modelContainer: ModelContainer
    
    // MARK: - Services (created once, shared globally)
    
    static let settings = AppSettings()
    static let connectionConfig = ConnectionConfig()
    static let availableModels = AvailableModels.shared
    
    // MARK: - Init
    
    init() {
        do {
            let schema = Schema([ChatSession.self, ChatMessage.self])
            let config = ModelConfiguration(schema: schema)
            self.modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(Self.settings)
                .environment(Self.connectionConfig)
                .environment(Self.availableModels)
        }
        .modelContainer(modelContainer)
    }
}