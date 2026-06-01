import SwiftUI
import PhotosUI

struct ChatScreen: View {
    @Bindable var viewModel: ChatViewModel
    var onOpenDrawer: () -> Void = {}
    var onNavigateToSettings: () -> Void = {}
    @Environment(\.modelContext) private var modelContext
    
    // Attachment state
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showDocumentPicker = false
    @State private var showPhotoPicker = false
    @ObservedObject var attachmentManager = AttachmentManager.shared
    
    // Artifact preview state
    @State private var selectedArtifact: Artifact?
    
    // Edit/regenerate state
    @State private var editTextMessage: ChatMessage?
    @State private var regenerateMessage: ChatMessage?
    @State private var editText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Message list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Welcome card: only show when not configured (no API key, no local server)
                        if !viewModel.isConfigured && viewModel.messages.isEmpty {
                            WelcomeCard(onNavigateToSettings: onNavigateToSettings)
                        }
                        
                        // Messages
                        ForEach(viewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                showThinking: viewModel.showThinkingSection
                            ) {
                                selectedArtifact = $0
                            } onEdit: { msg in
                                editTextMessage = msg
                            } onRegenerate: { msg in
                                regenerateMessage = msg
                            }
                            .id(message.id)
                        }
                        
                        // Streaming indicator
                        if viewModel.isStreaming {
                            StreamingIndicator()
                                .id("streaming")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                #if os(iOS)
                .scrollDismissesKeyboard(.immediately)
                .defaultScrollAnchor(.bottom)
                #endif
                // Auto-scroll on new messages
                .onChange(of: viewModel.messages.count) { oldCount, newCount in
                    if newCount > oldCount, let lastMessage = viewModel.messages.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                // Scroll during streaming — throttled
                .onChange(of: viewModel.isStreaming) { _, isStreaming in
                    if isStreaming {
                        proxy.scrollTo("streaming", anchor: .bottom)
                    }
                }
            }
            
            // Error banner
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error) {
                    viewModel.dismissError()
                }
            }
            
            // Vision warning banner
            if !viewModel.currentModelSupportsVision && !attachmentManager.attachments.isEmpty {
                VisionWarningBanner(modelName: viewModel.selectedModel?.attributedDisplayName ?? "Unknown") {
                    viewModel.showModelPicker = true
                }
            }
            
            // Searching indicator
            if viewModel.isSearching {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Searching the web...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
            
            // Input bar
            InputBar(
                text: $viewModel.inputText,
                isStreaming: viewModel.isStreaming,
                onSend: { Task { await viewModel.sendMessage() } },
                onCancel: { viewModel.cancelStreaming() },
                onAttachPhoto: { showPhotoPicker = true },
                onAttachFile: { showDocumentPicker = true }
            )
        }
        #if os(iOS)
        .scrollDismissesKeyboard(.immediately)
        .onTapGesture {
            dismissKeyboard()
        }
        #endif
        .navigationTitle(viewModel.currentSession?.title ?? "Local LLM Cloud Chat")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    dismissKeyboard()
                    onOpenDrawer()
                }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                }
            }
            
            ToolbarItem(placement: .principal) {
                Button {
                    viewModel.showModelPicker = true
                } label: {
                    VStack(spacing: 2) {
                        Text(viewModel.currentSession?.title ?? "New Chat")
                            .font(.headline)
                            .lineLimit(1)
                        HStack(spacing: 4) {
                            if let imgName = AvailableModels.modelImageName(viewModel.selectedModel?.id ?? "") {
                                Image(imgName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                            } else {
                                Circle()
                                    .fill(viewModel.selectedModel?.isCloud ?? true ? Color.blue : Color.green)
                                    .frame(width: 6, height: 6)
                            }
                            Text(viewModel.selectedModel?.attributedDisplayName ?? "Select Model")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Menu {
                    Button {
                        viewModel.showThinkingSection.toggle()
                    } label: {
                        Label(
                            viewModel.showThinkingSection ? "Hide Reasoning" : "Show Reasoning",
                            systemImage: "brain"
                        )
                    }
                    
                    Divider()
                    
                    ShareLink(
                        item: chatShareText,
                        subject: Text("Chat Export"),
                        message: Text("Exported from OllamaChat"),
                        preview: SharePreview("Chat Export", image: Image(systemName: "bubble.left.and.bubble.right"))
                    ) {
                        Label("Share Chat", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            if viewModel.currentSession == nil {
                viewModel.startNewChat()
            }
            Task {
                if let apiKey = SettingsRepository.shared.ollamaAPIKey, !apiKey.isEmpty {
                    await AvailableModels.shared.fetchCloudModels(apiKey: apiKey)
                }
                if viewModel.connectionConfig.isLocalConfigured,
                   let url = viewModel.connectionConfig.resolvedLocalURL {
                    await AvailableModels.shared.fetchLocalModels(baseURL: url)
                }
                viewModel.updateDefaultModelIfNeeded()
            }
        }
        .sheet(isPresented: $viewModel.showModelPicker) {
            ModelPickerSheet(viewModel: viewModel)
        }
        .sheet(item: $selectedArtifact) { artifact in
            ArtifactPreviewSheet(artifact: artifact)
        }
        .sheet(item: $editTextMessage) { msg in
            NavigationView {
                VStack(spacing: 16) {
                    TextEditor(text: $editText)
                        .font(.body)
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(minHeight: 100)
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Edit Message")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { editTextMessage = nil }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Send") {
                            let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                Task { await viewModel.editUserMessage(msg, newContent: trimmed) }
                            }
                            editTextMessage = nil
                        }
                    }
                }
            }
            .onAppear { editText = msg.content ?? "" }
        }
        .task(id: regenerateMessage) {
            guard let msg = regenerateMessage else { return }
            await viewModel.regenerateAiMessage(msg)
            regenerateMessage = nil
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            if let newItem {
                AttachmentManager.shared.addPhoto(newItem)
                selectedPhotoItem = nil
            }
        }
        .fileImporter(isPresented: $showDocumentPicker, allowedContentTypes: [.item], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    AttachmentManager.shared.addFile(url: url)
                }
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
    
    private var chatShareText: String {
        guard !viewModel.messages.isEmpty else { return "" }
        return viewModel.messages.map { msg in
            let prefix = msg.role == "user" ? "👤 User:" : "🤖 AI:"
            return "\(prefix) \(msg.content ?? "")"
        }.joined(separator: "\n\n")
    }
    
    #if os(iOS)
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    #endif
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.caption)
                .lineLimit(2)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.red.opacity(0.15))
    }
}

// MARK: - Vision Warning Banner

struct VisionWarningBanner: View {
    let modelName: String
    let onChangeModel: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "eye.slash")
                .foregroundStyle(.orange)
                .font(.subheadline)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(modelName) doesn't support images")
                    .font(.caption)
                    .fontWeight(.medium)
                Button(action: onChangeModel) {
                    Text("Switch to a vision model")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.15))
    }
}

// MARK: - Model Picker Sheet

struct ModelPickerSheet: View {
    @Bindable var viewModel: ChatViewModel
    
    var body: some View {
        NavigationView {
            List {
                let groups = viewModel.availableModels.modelGroups
                
                if groups.isEmpty {
                    Section {
                        Text("No models available.\nAdd an API key or connect to a local server in Settings.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    ForEach(groups, id: \.title) { group in
                        Section(group.title) {
                            ForEach(group.models) { model in
                                Button {
                                    viewModel.selectedModel = model
                                    viewModel.showModelPicker = false
                                } label: {
                                    ModelPickerRow(model: model, isSelected: viewModel.selectedModel?.id == model.id)
                                }
                                .tint(.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Model")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.showModelPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct ModelPickerRow: View {
    let model: DisplayModel
    let isSelected: Bool
    
    var body: some View {
        HStack {
            if let imgName = AvailableModels.modelImageName(model.id) {
                Image(imgName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
            } else {
                Circle()
                    .fill(model.isCloud ? Color.blue : Color.green)
                    .frame(width: 8, height: 8)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(model.attributedDisplayName)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .bold : .regular)
                    if model.supportsVision {
                        Image(systemName: "eye")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
                Text(model.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            }
        }
    }
}