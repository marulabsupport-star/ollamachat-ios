import SwiftUI
import SwiftData

/// Main app container with drawer navigation.
/// Uses a single NavigationStack to prevent navigation stack issues.
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Use @State to hold ChatViewModel so it survives navigation changes.
    // For @Observable class, @State preserves object identity across view rebuilds.
    @State private var chatViewModel: ChatViewModel = {
        let chatRepo = ChatRepository()
        let apiClient = ApiClient(connectionConfig: LocalLLMCloudChatApp.connectionConfig)
        let chatService = ChatService(
            apiClient: apiClient,
            chatRepo: chatRepo,
            connectionConfig: LocalLLMCloudChatApp.connectionConfig,
            settings: LocalLLMCloudChatApp.settings
        )
        let searchService = SearchService()
        return ChatViewModel(
            chatService: chatService,
            searchService: searchService,
            availableModels: AvailableModels.shared,
            connectionConfig: LocalLLMCloudChatApp.connectionConfig,
            settings: LocalLLMCloudChatApp.settings
        )
    }()
    
    // Navigation path — single source of truth for where we are
    @State private var navigationPath = NavigationPath()
    
    // Shared sessions VM — created once with modelContext, survives navigation
    @State private var sessionsViewModel: SessionsViewModel?
    
    @State private var showDrawer = false
    @State private var selectedSession: ChatSession?
    
    /// App routes for type-safe navigation
    enum Route: Hashable {
        case recents
        case settings
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ChatScreen(
                viewModel: chatViewModel,
                onOpenDrawer: {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    showDrawer = true
                },
                onNavigateToSettings: { navigationPath.append(Route.settings) }
            )
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .recents:
                    RecentsScreen(
                        viewModel: sessionsViewModel ?? makeSessionsViewModel(),
                        onSelectSession: { session in
                            selectedSession = session
                            chatViewModel.loadSession(session)
                            DispatchQueue.main.async {
                                navigationPath.removeLast()
                            }
                        },
                        onNewChat: {
                            startNewChat()
                            navigationPath.removeLast()
                        },
                        onOpenDrawer: {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            showDrawer = true
                        }
                    )
                case .settings:
                    SettingsScreen(
                        viewModel: makeSettingsViewModel(),
                        onNavigateBack: { navigationPath.removeLast() }
                    )
                }
            }
        }
        .overlay {
            // Drawer overlay
            if showDrawer {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.25)) { showDrawer = false } }
                
                HStack(spacing: 0) {
                    DrawerView(
                        currentRoute: navigationPath.isEmpty ? "chat" : "recents",
                        selectedModelName: selectedModelName,
                        selectedModelId: chatViewModel.selectedModel?.id ?? "",
                        onNewChat: {
                            withAnimation(.easeInOut(duration: 0.25)) { showDrawer = false }
                            startNewChat()
                            if !navigationPath.isEmpty {
                                navigationPath = NavigationPath()
                            }
                        },
                        onRecents: {
                            withAnimation(.easeInOut(duration: 0.25)) { showDrawer = false }
                            navigationPath = NavigationPath()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                navigationPath.append(Route.recents)
                            }
                        },
                        onSettings: {
                            withAnimation(.easeInOut(duration: 0.25)) { showDrawer = false }
                            navigationPath = NavigationPath()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                navigationPath.append(Route.settings)
                            }
                        },
                        onFeedback: {
                            withAnimation(.easeInOut(duration: 0.25)) { showDrawer = false }
                            openFeedbackEmail()
                        }
                    )
                    .transition(.move(edge: .leading))
                    
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showDrawer)
        .preferredColorScheme(LocalLLMCloudChatApp.settings.colorScheme)
        .onAppear {
            chatViewModel.updateModelContext(modelContext)
            
            // Create sessions VM once with modelContext
            if sessionsViewModel == nil {
                sessionsViewModel = SessionsViewModel(chatRepo: ChatRepository(modelContext: modelContext))
            }
            
            // Fetch cloud models if API key is available
            if let apiKey = SettingsRepository.shared.ollamaAPIKey, !apiKey.isEmpty {
                Task {
                    await AvailableModels.shared.fetchCloudModels(apiKey: apiKey)
                    chatViewModel.updateDefaultModelIfNeeded()
                }
            }
        }
        // Sync selected model when navigating back to chat
        .onChange(of: navigationPath) { _, newPath in
            if newPath.isEmpty {
                // Back at root (chat screen)
                chatViewModel.updateDefaultModelIfNeeded()
            }
        }
    }
    
    // MARK: - Computed
    
    private var selectedModelName: String {
        chatViewModel.selectedModel?.attributedDisplayName ?? "None"
    }
    
    // MARK: - Factory Methods
    
    private func makeSessionsViewModel() -> SessionsViewModel {
        if let existing = sessionsViewModel {
            return existing
        }
        let vm = SessionsViewModel(chatRepo: ChatRepository(modelContext: modelContext))
        sessionsViewModel = vm
        return vm
    }
    
    private func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            settings: LocalLLMCloudChatApp.settings,
            connectionConfig: LocalLLMCloudChatApp.connectionConfig
        )
    }
    
    private func startNewChat() {
        selectedSession = nil
        chatViewModel.startNewChat()
    }
    
    private func openFeedbackEmail() {
        let email = "marulabsupport@gmail.com"
        let subject = "Local LLM Cloud Chat Feedback"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        guard let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}