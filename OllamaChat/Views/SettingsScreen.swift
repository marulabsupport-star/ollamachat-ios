import SwiftUI
import SwiftData

struct SettingsScreen: View {
    @Bindable var viewModel: SettingsViewModel
    var onNavigateBack: (() -> Void)? = nil
    @Environment(\.modelContext) private var modelContext
    
    // Expandable card state
    @State private var expandedCard: String? = "apikey"
    @State private var showApiKey = false
    @State private var showTavilyKey = false
    @State private var showModelDropdown = false
    @State private var showThemeDropdown = false
    
    // Persona state
    @State private var personas: [PersonaEntry] = []
    @State private var selectedPersonaId: UUID? = nil
    @State private var editingPersona: PersonaEntry?
    @State private var showAddPersonaSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header card
                headerCard
                
                // 1. API Key Section
                ExpandableSettingsCard(
                    title: "API Key",
                    icon: "key.fill",
                    cardId: "apikey",
                    expandedCard: $expandedCard
                ) {
                    apiKeyContent
                }
                
                // 2. Server URL Section
                ExpandableSettingsCard(
                    title: "Local Server",
                    icon: "server.rack",
                    cardId: "serverurl",
                    expandedCard: $expandedCard
                ) {
                    serverUrlContent
                }
                
                // 3. Model Section
                ExpandableSettingsCard(
                    title: "Model",
                    icon: "cpu",
                    cardId: "model",
                    expandedCard: $expandedCard
                ) {
                    modelContent
                }
                
                // 4. Web Search
                ExpandableSettingsCard(
                    title: "Web Search",
                    icon: "magnifyingglass",
                    cardId: "search",
                    expandedCard: $expandedCard
                ) {
                    webSearchContent
                }
                
                // 4.5 Follow-up Suggestions
                ExpandableSettingsCard(
                    title: "Follow-up Suggestions",
                    icon: "text.bubble.fill",
                    cardId: "followup",
                    expandedCard: $expandedCard
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("When enabled, the AI will suggest follow-up questions at the end of each response.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Toggle("Enable Follow-up Suggestions", isOn: $viewModel.settings.followUpSuggestions)
                            .tint(.accentColor)
                    }
                    .padding(.vertical, 4)
                }
                
                // 5. System Prompt
                ExpandableSettingsCard(
                    title: "System Prompt",
                    icon: "sparkles",
                    cardId: "prompt",
                    expandedCard: $expandedCard
                ) {
                    systemPromptContent
                }
                
                // 6. Personas
                ExpandableSettingsCard(
                    title: "Personas",
                    icon: "person.crop.circle.fill",
                    cardId: "personas",
                    expandedCard: $expandedCard
                ) {
                    personaContent
                }
                
                // 7. Memory
                MemorySection()
                
                // 7. Theme
                ExpandableSettingsCard(
                    title: "Theme",
                    icon: "moon.fill",
                    cardId: "theme",
                    expandedCard: $expandedCard
                ) {
                    themeContent
                }
                
                // 9. Backup & Restore
                ExpandableSettingsCard(
                    title: "Backup & Restore",
                    icon: "internaldrive.fill",
                    cardId: "backup",
                    expandedCard: $expandedCard
                ) {
                    backupContent
                }
                
                // 10. Privacy Policy
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    HStack {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 16)
                
                // 11. Clear Data
                Button(role: .destructive) {
                    viewModel.clearAllData(modelContext: modelContext)
                } label: {
                    Label("Clear All Chat Data", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                
                // Save status
                if let message = viewModel.saveMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
                
                Spacer(minLength: 32)
            }
            .padding(.top, 8)
        }
        .navigationTitle("Settings")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            loadPersonas()
        }
        .sheet(item: $editingPersona) { persona in
            PersonaEditSheet(mode: .edit(persona)) { name, prompt in
                let repo = PersonaRepository(modelContext: modelContext)
                repo.update(persona, name: name, systemPrompt: prompt)
                loadPersonas()
            }
        }
        .sheet(isPresented: $showAddPersonaSheet) {
            PersonaEditSheet(mode: .add) { name, prompt in
                let repo = PersonaRepository(modelContext: modelContext)
                let persona = repo.create(name: name, systemPrompt: prompt)
                loadPersonas()
                selectedPersonaId = persona.id
            }
        }
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        VStack(spacing: 8) {
            Text("API Configuration")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Configure your server settings below")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.accentColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    // MARK: - API Key Content
    
    private var apiKeyContent: some View {
        VStack(spacing: 12) {
            HStack {
                if showApiKey {
                    TextField("Cloud API Key", text: $viewModel.ollamaKeyInput)
                        .textContentType(.password)
                        .autocapitalization(.none)
                } else {
                    SecureField("Cloud API Key", text: $viewModel.ollamaKeyInput)
                        .textContentType(.password)
                }
                Button(action: { showApiKey.toggle() }) {
                    Image(systemName: showApiKey ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(.secondary)
                }
            }
            
            Button("Save API Key") {
                viewModel.saveOllamaKey()
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.ollamaKeyInput.isEmpty && !viewModel.settingsRepo.hasOllamaAPIKey)
        }
    }
    
    // MARK: - Server URL Content
    
    private var serverUrlContent: some View {
        VStack(spacing: 12) {
            TextField("Server URL (e.g. 192.168.1.100)", text: $viewModel.localURLInput)
                .textContentType(.URL)
                .autocapitalization(.none)
                .keyboardType(.URL)
            
            Text("Tip: Enter a local IP like 192.168.1.100 (http:// added automatically) or a full URL for Cloudflare Tunnel access.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 2)
            Link("What is Cloudflare Tunnel?", destination: URL(string: "https://developers.cloudflare.com/tunnel/")!)
            
            HStack {
                Button("Save URL") {
                    viewModel.saveLocalURL()
                }
                .disabled(viewModel.localURLInput.isEmpty)
                
                Spacer()
                
                Button {
                    Task { await viewModel.testLocalConnection() }
                } label: {
                    if viewModel.isTestingConnection {
                        ProgressView()
                            .frame(height: 20)
                    } else {
                        Label("Test Connection", systemImage: "antenna.radiowaves.left.and.right")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.localURLInput.isEmpty)
            }
            
            // Connection test result
            if let result = viewModel.connectionTestResult {
                Group {
                    switch result {
                    case .success(let message):
                        Label(message, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    case .failure(let message):
                        Label(message, systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
                .font(.caption)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(result.isSuccess ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                )
            }
        }
    }
    
    // MARK: - Model Content
    
    private var modelContent: some View {
        Picker("Default Model", selection: $viewModel.settings.defaultModel) {
            let groups = AvailableModels.shared.modelGroups
            ForEach(groups, id: \.title) { group in
                Section(group.title) {
                    ForEach(group.models) { model in
                        Text(model.attributedDisplayName).tag(model.id)
                    }
                }
            }
        }
    }
    
    // MARK: - Web Search Content
    
    private var webSearchContent: some View {
        VStack(spacing: 12) {
            HStack {
                if showTavilyKey {
                    TextField("Tavily API Key", text: $viewModel.tavilyKeyInput)
                        .textContentType(.password)
                        .autocapitalization(.none)
                } else {
                    SecureField("Tavily API Key", text: $viewModel.tavilyKeyInput)
                        .textContentType(.password)
                }
                Button(action: { showTavilyKey.toggle() }) {
                    Image(systemName: showTavilyKey ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(.secondary)
                }
            }
            
            Button("Save API Key") {
                viewModel.saveTavilyKey()
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.bordered)
            
            Picker("Search Mode", selection: $viewModel.settings.webSearchMode) {
                Text("Auto").tag("auto")
                Text("Always").tag("always")
                Text("Off").tag("off")
            }
            .pickerStyle(.segmented)
            
            switch viewModel.settings.webSearchMode {
            case "auto":
                Text("Search automatically when questions need current info (weather, news, prices, etc.)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case "always":
                Text("Search for every message before responding.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            default:
                Text("Never search the web. Responses based on training data only.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - System Prompt Content
    
    private var systemPromptContent: some View {
        VStack(spacing: 8) {
            TextField("System Prompt", text: $viewModel.settings.systemPrompt, axis: .vertical)
                .lineLimit(3...8)
            
            Text("Sets the AI's behavior. Leave empty for default.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Theme Content
    
    private var themeContent: some View {
        VStack(spacing: 8) {
            Picker("Theme", selection: $viewModel.settings.themeMode) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)
        }
    }
    
    // MARK: - Backup Content
    
    private var backupContent: some View {
        VStack(spacing: 12) {
            Text("Export your chat history as JSON, or restore from a backup.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            NavigationLink("Backup & Restore") {
                BackupRestoreScreen()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Persona Content
    
    private var personaContent: some View {
        VStack(spacing: 12) {
            if personas.isEmpty {
                Text("No personas yet. Add one to customize AI behavior.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(personas) { persona in
                    PersonaRow(
                        persona: persona,
                        isSelected: selectedPersonaId == persona.id,
                        onSelect: {
                            if selectedPersonaId == persona.id {
                                selectedPersonaId = nil
                                viewModel.settings.systemPrompt = ""
                            } else {
                                selectedPersonaId = persona.id
                                viewModel.settings.systemPrompt = persona.systemPrompt
                            }
                        },
                        onEdit: { editingPersona = persona },
                        onSetDefault: {
                            let repo = PersonaRepository(modelContext: modelContext)
                            repo.setDefault(persona)
                            loadPersonas()
                        },
                        onDelete: {
                            let repo = PersonaRepository(modelContext: modelContext)
                            repo.delete(persona)
                            if selectedPersonaId == persona.id {
                                selectedPersonaId = nil
                                viewModel.settings.systemPrompt = ""
                            }
                            loadPersonas()
                        }
                    )
                }
            }
            
            Button {
                showAddPersonaSheet = true
            } label: {
                Label("Add Persona", systemImage: "plus.circle.fill")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)
        }
    }
    
    private func loadPersonas() {
        let repo = PersonaRepository(modelContext: modelContext)
        repo.seedDefaultsIfNeeded()
        personas = repo.fetchAll()
        // Restore selected persona
        if selectedPersonaId == nil {
            if let defaultPersona = repo.fetchDefault() {
                selectedPersonaId = defaultPersona.id
                viewModel.settings.systemPrompt = defaultPersona.systemPrompt
            }
        }
    }
}