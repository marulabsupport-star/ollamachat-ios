import Foundation
import SwiftData
import os

/// Orchestrates chat operations: send messages, stream responses, manage state.
@MainActor
@Observable
final class ChatService {
    
    private let logger = Logger(subsystem: "com.openclaw.ollamachat", category: "chat")
    
    // MARK: - Dependencies
    
    private let apiClient: ApiClient
    private(set) var chatRepo: ChatRepository
    private let connectionConfig: ConnectionConfig
    private let settings: AppSettings
    
    /// Update model context on the repository (called from ContentView.onAppear)
    func updateModelContext(_ context: ModelContext) {
        chatRepo.modelContext = context
    }
    
    // MARK: - State
    
    var currentSession: ChatSession?
    var messages: [ChatMessage] = []
    var isStreaming: Bool = false
    var errorMessage: String?
    
    // Incremental save timer
    private var saveTimer: Timer?
    private var streamingMessage: ChatMessage?
    private var accumulatedContent: String = ""
    private var accumulatedThinking: String = ""
    
    // MARK: - Init
    
    init(apiClient: ApiClient, chatRepo: ChatRepository, connectionConfig: ConnectionConfig, settings: AppSettings) {
        self.apiClient = apiClient
        self.chatRepo = chatRepo
        self.connectionConfig = connectionConfig
        self.settings = settings
    }
    
    // MARK: - Session Management
    
    func startNewSession(modelName: String, connectionMode: String) -> ChatSession {
        // Save any in-progress streaming
        cancelStreaming()
        
        let session = chatRepo.createSession(
            modelName: modelName,
            connectionMode: connectionMode,
            systemPrompt: settings.systemPrompt
        )
        currentSession = session
        messages = []
        return session
    }
    
    func loadSession(_ session: ChatSession) {
        cancelStreaming()
        currentSession = session
        messages = chatRepo.fetchMessages(for: session)
    }
    
    // MARK: - Send Message
    
    func sendMessage(_ text: String, searchContext: String? = nil, images: [Data]? = nil) async {
        guard let session = currentSession else {
            errorMessage = "No active session"
            return
        }
        
        guard !isStreaming else { return }
        
        // Switch connection for model
        connectionConfig.switchForModel(session.modelName)
        
        // Save user message
        let hasImages = (images ?? []).isEmpty ? false : true
        let userMessage = chatRepo.addMessage(
            role: "user",
            content: text,
            hasImages: hasImages,
            to: session
        )
        messages.append(userMessage)
        
        // Create assistant message placeholder (streaming)
        let assistantMessage = chatRepo.addMessage(
            role: "assistant",
            content: "",
            isStreaming: true,
            to: session
        )
        messages.append(assistantMessage)
        streamingMessage = assistantMessage
        accumulatedContent = ""
        accumulatedThinking = ""
        isStreaming = true
        errorMessage = nil
        
        // Start incremental save timer (every 2s)
        startSaveTimer()
        
        // Build request
        let request = buildChatRequest(session: session, userText: text, searchContext: searchContext, images: images)
        
        // Stream response
        do {
            let stream = await apiClient.streamChat(request: request)
            for try await event in stream {
                handleStreamEvent(event)
            }
        } catch is CancellationError {
            // User cancelled — silently finalize
        } catch {
            handleStreamError(error)
        }
        
        // Finalize
        stopSaveTimer()
        finalizeStreamingMessage()
    }
    
    func cancelStreaming() {
        stopSaveTimer()
        if let message = streamingMessage {
            chatRepo.finalizeDraft(message)
            streamingMessage = nil
        }
        isStreaming = false
    }
    
    // MARK: - Private
    
    /// Default system prompt injected when user hasn't set a custom one.
    /// Ensures models always produce runnable single-file code artifacts.
    private static let defaultSystemPrompt = """
    You are a helpful assistant inside Ollama Chat, an iOS app with a built-in web preview.
    
    When writing code (web apps, tools, widgets, games, visualizations, etc.):
    1. Always produce a SINGLE, SELF-CONTAINED HTML file with all CSS and JavaScript inline.
    2. Use <!DOCTYPE html> and include <meta name="viewport" content="width=device-width, initial-scale=1">.
    3. Make it mobile-friendly and visually polished — this runs on an iPhone screen.
    4. Do NOT split into separate files. Do NOT reference external CDN links unless absolutely necessary.
    5. Put the complete code in a single ```html code block so it can be previewed instantly.
    
    For non-code responses, respond normally.
    """
    
    private func buildChatRequest(session: ChatSession, userText: String, searchContext: String? = nil, images: [Data]?) -> OllamaChatRequest {
        var ollamaMessages: [OllamaMessage] = []
        
        // System prompt: user custom > default
        var systemPrompt = session.systemPrompt.isEmpty ? Self.defaultSystemPrompt : session.systemPrompt
        if let search = searchContext {
            systemPrompt += "\n\n" + search
        }
        ollamaMessages.append(OllamaMessage(role: "system", content: systemPrompt))
        
        // History (images from previous messages not stored, so text-only for history)
        for msg in messages.dropLast() {  // Exclude the just-added assistant placeholder
            ollamaMessages.append(OllamaMessage(role: msg.role, content: msg.content ?? ""))
        }
        
        // Current user message
        var userImages: [String]? = nil
        if let images = images {
            userImages = images.map { $0.base64EncodedString() }
        }
        // Ensure content is never empty — Ollama requires it
        let messageContent = userText.isEmpty ? "Describe this image." : userText
        ollamaMessages.append(OllamaMessage(role: "user", content: messageContent, images: userImages))
        
        // Options
        var options: OllamaOptions? = nil
        if settings.temperature != 0.7 || settings.maxTokens != 2048 {
            options = OllamaOptions(temperature: settings.temperature, numPredict: settings.maxTokens)
        }
        
        return OllamaChatRequest(
            model: session.modelName,
            messages: ollamaMessages,
            stream: true,
            options: options
        )
    }
    
    private func handleStreamEvent(_ event: StreamEvent) {
        guard let message = streamingMessage else { return }
        
        switch event {
        case .token(let text):
            accumulatedContent += text
            chatRepo.updateMessageInMemory(message, content: accumulatedContent)
            
        case .thinking(let text):
            accumulatedThinking += text
            chatRepo.updateMessageInMemory(message, thinkingContent: accumulatedThinking)
            
        case .complete:
            break  // Handled in finalize
            
        case .streamCancelled:
            break  // User cancelled
            
        case .error(let errorText):
            errorMessage = errorText
        }
    }
    
    private func handleStreamError(_ error: Error) {
        logger.error("Stream error: \(error.localizedDescription)")
        if let ollamaError = error as? OllamaError {
            errorMessage = ollamaError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
        finalizeStreamingMessage()
    }
    
    private func finalizeStreamingMessage() {
        guard let message = streamingMessage else {
            isStreaming = false
            return
        }
        chatRepo.updateMessage(message, isStreaming: false)
        streamingMessage = nil
        isStreaming = false
        
        // Auto-title: use first user message if session title is default
        if let session = currentSession, session.title == "New Chat" {
            if let firstUserMsg = messages.first(where: { $0.role == "user" }) {
                let title = String(firstUserMsg.content?.prefix(50) ?? "Chat")
                chatRepo.updateSessionTitle(session, title: title)
            }
        }
    }
    
    // MARK: - Incremental Save Timer
    
    private func startSaveTimer() {
        saveTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.saveStreamingProgress()
            }
        }
    }
    
    private func stopSaveTimer() {
        saveTimer?.invalidate()
        saveTimer = nil
    }
    
    private func saveStreamingProgress() {
        guard let message = streamingMessage else { return }
        chatRepo.updateMessage(
            message,
            content: accumulatedContent,
            thinkingContent: accumulatedThinking
        )
    }
}