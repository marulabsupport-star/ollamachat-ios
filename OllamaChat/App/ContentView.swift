import SwiftUI
import SwiftData

/// Main app container with drawer navigation.
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Use @State to hold ChatViewModel so it survives navigation changes.
    // For @Observable class, @State preserves object identity across view rebuilds.
    @State private var chatViewModel: ChatViewModel = {
        let chatRepo = ChatRepository()
        let apiClient = ApiClient(connectionConfig: OllamaChatApp.connectionConfig)
        let chatService = ChatService(
            apiClient: apiClient,
            chatRepo: chatRepo,
            connectionConfig: OllamaChatApp.connectionConfig,
            settings: OllamaChatApp.settings
        )
        let searchService = SearchService()
        return ChatViewModel(
            chatService: chatService,
            searchService: searchService,
            availableModels: AvailableModels.shared,
            connectionConfig: OllamaChatApp.connectionConfig,
            settings: OllamaChatApp.settings
        )
    }()
    
    @AppStorage("currentRoute") private var currentRoute: String = "chat"
    @State private var showDrawer = false
    @State private var selectedSession: ChatSession?
    
    var body: some View {
        ZStack {
            currentScreen
            
            // Drawer overlay
            if showDrawer {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.25)) { showDrawer = false } }
                
                HStack(spacing: 0) {
                    DrawerView(
                        currentRoute: currentRoute,
                        selectedModelName: selectedModelName,
                        onNewChat: {
                            withAnimation(.easeInOut(duration: 0.25)) { showDrawer = false }
                            startNewChat()
                        },
                        onRecents: {
                            withAnimation(.easeInOut(duration: 0.25)) { showDrawer = false }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                currentRoute = "recents"
                            }
                        },
                        onSettings: {
                            withAnimation(.easeInOut(duration: 0.25)) { showDrawer = false }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                currentRoute = "settings"
                            }
                        }
                    )
                    .transition(.move(edge: .leading))
                    
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showDrawer)
        .preferredColorScheme(OllamaChatApp.settings.colorScheme)
        .onAppear {
            chatViewModel.updateModelContext(modelContext)
            
            // Fetch cloud models if API key is available
            if let apiKey = SettingsRepository.shared.ollamaAPIKey, !apiKey.isEmpty {
                Task {
                    await AvailableModels.shared.fetchCloudModels(apiKey: apiKey)
                    chatViewModel.updateDefaultModelIfNeeded()
                }
            }
        }
        // Sync selected model when navigating back to chat (e.g., from Settings)
        .onChange(of: currentRoute) { _, newValue in
            if newValue == "chat" {
                chatViewModel.updateDefaultModelIfNeeded()
            }
        }
    }
    
    // MARK: - Computed
    
    @ViewBuilder
    private var currentScreen: some View {
        switch currentRoute {
        case "recents":
            NavigationStack {
                RecentsScreen(
                    viewModel: makeSessionsViewModel(),
                    onSelectSession: { session in
                        selectedSession = session
                        chatViewModel.loadSession(session)
                        currentRoute = "chat"
                    },
                    onNewChat: { startNewChat() },
                    onOpenDrawer: { showDrawer = true }
                )
            }
        case "settings":
            NavigationStack {
                SettingsScreen(
                    viewModel: makeSettingsViewModel(),
                    onNavigateBack: { currentRoute = "chat" }
                )
            }
        default:
            NavigationStack {
                ChatScreen(
                    viewModel: chatViewModel,
                    onOpenDrawer: { showDrawer = true },
                    onNavigateToSettings: { currentRoute = "settings" }
                )
            }
        }
    }
    
    private var selectedModelName: String {
        if let session = selectedSession {
            return session.modelName
        }
        return chatViewModel.selectedModel?.displayName ?? "None"
    }
    
    // MARK: - Factory Methods
    
    private func makeSessionsViewModel() -> SessionsViewModel {
        SessionsViewModel(chatRepo: ChatRepository(modelContext: modelContext))
    }
    
    private func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            settings: OllamaChatApp.settings,
            connectionConfig: OllamaChatApp.connectionConfig
        )
    }
    
    private func startNewChat() {
        selectedSession = nil
        currentRoute = "chat"
        chatViewModel.startNewChat()
    }
}