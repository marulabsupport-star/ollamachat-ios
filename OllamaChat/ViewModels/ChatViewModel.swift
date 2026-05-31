import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class ChatViewModel {
    
    // MARK: - Dependencies
    
    private let chatService: ChatService
    let searchService: SearchService
    let availableModels: AvailableModels
    let connectionConfig: ConnectionConfig
    let settings: AppSettings
    
    // MARK: - Chat State
    
    var currentSession: ChatSession? { chatService.currentSession }
    var messages: [ChatMessage] { chatService.messages }
    var isStreaming: Bool { chatService.isStreaming }
    var errorMessage: String? {
        didSet { /* trigger observation */ }
    }
    
    // MARK: - UI State
    
    var inputText: String = ""
    
    /// The currently selected model for chat.
    /// Syncs with AppSettings.defaultModel — single source of truth.
    var selectedModel: DisplayModel? {
        didSet {
            if let model = selectedModel {
                settings.defaultModel = model.id
                UserDefaults.standard.set(model.id, forKey: "selectedModelId")
            } else {
                settings.defaultModel = ""
                UserDefaults.standard.removeObject(forKey: "selectedModelId")
            }
        }
    }
    
    var showModelPicker: Bool = false
    var showThinkingSection: Bool = false
    var showVisionWarning: Bool = false
    
    /// Whether the currently selected model supports vision/image input
    var currentModelSupportsVision: Bool {
        selectedModel?.supportsVision ?? false
    }
    
    // MARK: - Configuration
    
    /// Whether the app has a working connection configured
    var isConfigured: Bool {
        let hasApiKey = !(SettingsRepository.shared.ollamaAPIKey ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasLocalURL = !connectionConfig.localServerURL.trimmingCharacters(in: .whitespaces).isEmpty
        // Configured if either cloud (API key) or local (URL) is set up
        return hasApiKey || hasLocalURL
    }
    
    // MARK: - Search State
    
    var isSearching: Bool { searchService.isSearching }
    
    // MARK: - Init
    
    init(
        chatService: ChatService,
        searchService: SearchService,
        availableModels: AvailableModels = .shared,
        connectionConfig: ConnectionConfig,
        settings: AppSettings
    ) {
        self.chatService = chatService
        self.searchService = searchService
        self.availableModels = availableModels
        self.connectionConfig = connectionConfig
        self.settings = settings
        
        // Resolve selected model from persistence.
        // Priority: AppSettings.defaultModel > UserDefaults "selectedModelId" > first available
        let savedId: String = {
            let fromSettings = settings.defaultModel.trimmingCharacters(in: .whitespaces)
            if !fromSettings.isEmpty { return fromSettings }
            return UserDefaults.standard.string(forKey: "selectedModelId") ?? ""
        }()
        
        if !savedId.isEmpty,
           let model = availableModels.allModels.first(where: { $0.id == savedId }) {
            selectedModel = model
        } else {
            // Models may not be loaded yet — will be resolved in updateDefaultModelIfNeeded()
            selectedModel = availableModels.allModels.first
        }
    }
    
    // MARK: - Model Resolution
    
    func updateModelContext(_ context: ModelContext) {
        chatService.updateModelContext(context)
    }
    
    /// Re-resolve selected model after model list changes or returning from Settings.
    /// Uses AppSettings.defaultModel as the single source of truth.
    /// If the saved model no longer exists in the list, falls back to first available.
    func updateDefaultModelIfNeeded() {
        let savedId: String = {
            let fromSettings = settings.defaultModel.trimmingCharacters(in: .whitespaces)
            if !fromSettings.isEmpty { return fromSettings }
            return UserDefaults.standard.string(forKey: "selectedModelId") ?? ""
        }()
        
        // Try to find the saved model in the current model list
        if !savedId.isEmpty,
           let model = availableModels.allModels.first(where: { $0.id == savedId }) {
            selectedModel = model
            return
        }
        
        // Current selection still valid?
        if let current = selectedModel,
           availableModels.allModels.contains(where: { $0.id == current.id }) {
            return
        }
        
        // Fallback: first available model
        selectedModel = availableModels.allModels.first
    }
    
    // MARK: - Actions
    
    func startNewChat() {
        guard let model = selectedModel else {
            // Models not loaded yet — will retry after fetch completes
            return
        }
        // Always create a new session, clearing old messages
        _ = chatService.startNewSession(
            modelName: model.id,
            connectionMode: model.connectionMode
        )
    }
    
    func loadSession(_ session: ChatSession) {
        chatService.loadSession(session)
        // Sync session's model back to selectedModel
        if let model = availableModels.allModels.first(where: { $0.id == session.modelName }) {
            selectedModel = model
        }
    }
    
    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let attachments = AttachmentManager.shared.attachments
        let hasContent = !text.isEmpty || !attachments.isEmpty
        guard hasContent else { return }
        guard !isStreaming else { return }
        
        guard selectedModel != nil else {
            // Models not loaded yet — silent, will retry
            return
        }
        
        // Validate connection is configured
        guard isConfigured else {
            errorMessage = "Not configured. Add your API key or local server URL in Settings."
            return
        }
        
        // Build final text: append file contents to message
        var finalText = text
        for attachment in attachments {
            if let fileContent = attachment.formattedTextContent {
                finalText += fileContent
            }
        }
        
        // Collect image data for vision models (images + PDF page renders)
        var imageData: [Data] = []
        for attachment in attachments {
            if attachment.isVisionCompatible {
                imageData.append(attachment.data)
            } else if attachment.isPDF {
                let pages = PDFRenderer.renderPages(data: attachment.data)
                if !pages.isEmpty {
                    imageData.append(contentsOf: pages)
                    if finalText.isEmpty || finalText == text {
                        finalText += "\nAnalyze this PDF document."
                    }
                }
            }
        }
        let finalImageData: [Data]? = imageData.isEmpty ? nil : imageData
        
        inputText = ""
        AttachmentManager.shared.clear()
        
        // Start new session if needed
        if currentSession == nil {
            guard let model = selectedModel else { return }
            _ = chatService.startNewSession(
                modelName: model.id,
                connectionMode: model.connectionMode
            )
        }
        
        // Determine if web search should be used
        var searchContext: String? = nil
        let searchMode = settings.webSearchMode
        let shouldSearch: Bool
        switch searchMode {
        case "always":
            shouldSearch = true
        case "off":
            shouldSearch = false
        default: // "auto"
            shouldSearch = needsWebSearch(text)
        }
        
        if shouldSearch {
            searchContext = await searchService.search(query: text)
        }
        
        await chatService.sendMessage(finalText, searchContext: searchContext, images: finalImageData)
    }
    
    func cancelStreaming() {
        chatService.cancelStreaming()
    }
    
    // MARK: - Edit & Regenerate
    
    func editUserMessage(_ message: ChatMessage, newContent: String) async {
        await chatService.editUserMessage(message, newContent: newContent)
    }
    
    func regenerateAiMessage(_ message: ChatMessage) async {
        await chatService.regenerateAiMessage(message)
    }
    
    func dismissError() {
        errorMessage = nil
    }
    
    // MARK: - Auto Search Logic
    
    /// Determine if a message likely needs web search for current information.
    /// Uses simple keyword/heuristic detection — not AI-based.
    private func needsWebSearch(_ text: String) -> Bool {
        let lower = text.lowercased()
        
        // Time-sensitive keywords
        let timeSensitive = [
            "today", "right now", "currently", "latest", "recent", "current",
            "this week", "this month", "this year", "now",
            "2024", "2025", "2026", "2027",
            "오늘", "지금", "최신", "현재", "올해"
        ]
        
        // Topics that typically need fresh data
        let freshTopics = [
            "weather", "temperature", "forecast", "날씨", "기온",
            "news", "headline", "뉴스", "소식",
            "stock", "price", "market", "crypto", "bitcoin", "ethereum",
            "주식", "주가", "시세", "코인", "비트코인", "이더리움", "암호화폐",
            "score", "game", "match", "playoff", "경기", "스코어",
            "election", "president", "prime minister",
            "release", "update", "version",
            "trending", "viral", "popular",
            "nvidia", "엔비디아", "앤비디아", "tesla", "테슬라", "apple", "애플"
        ]
        
        // Question patterns that imply recency
        let recencyPatterns = [
            "what's happening", "what is happening",
            "what's the latest", "what are the latest",
            "what's new", "what is new",
            "who won", "who is winning",
            "how much does", "how much is", "얼마", "값은", "가격",
            "where is", "where can i buy",
            "알려줘", "알려줘라",          // "tell me"
            "오르고", "내리고",          // "rising", "falling"
            "상승", "하락",            // "rise", "decline"
            "얼마야", "얼마니"          // "how much is" casual
        ]
        
        for keyword in timeSensitive where lower.contains(keyword) { return true }
        for keyword in freshTopics where lower.contains(keyword) { return true }
        for pattern in recencyPatterns where lower.contains(pattern) { return true }
        
        return false
    }
    
    func toggleModelPicker() {
        showModelPicker.toggle()
    }
}

// MARK: - PDF Rendering
// PDF rendering is handled by PDFRenderer in InputBar.swift