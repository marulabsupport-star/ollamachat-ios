import Foundation
import SwiftData

/// Manages chat session and message persistence via SwiftData.
@MainActor
final class ChatRepository {
    
    /// ModelContext — set once from SwiftUI's environment in ContentView.onAppear
    var modelContext: ModelContext!
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    // MARK: - Sessions
    
    func createSession(title: String = "New Chat", modelName: String, connectionMode: String, systemPrompt: String = "") -> ChatSession {
        let session = ChatSession(
            title: title,
            modelName: modelName,
            connectionMode: connectionMode,
            systemPrompt: systemPrompt
        )
        modelContext.insert(session)
        try? modelContext.save()
        return session
    }
    
    func fetchSessions() -> [ChatSession] {
        var descriptor = FetchDescriptor<ChatSession>(
            sortBy: [
                SortDescriptor(\.updatedAt, order: .reverse)
            ]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchSession(by id: UUID) -> ChatSession? {
        let descriptor = FetchDescriptor<ChatSession>(
            predicate: #Predicate { $0.id == id }
        )
        return (try? modelContext.fetch(descriptor))?.first
    }
    
    func deleteSession(_ session: ChatSession) {
        modelContext.delete(session)
        try? modelContext.save()
    }
    
    func pinSession(_ session: ChatSession) {
        session.pinned = true
        session.updatedAt = Date()
        try? modelContext.save()
    }
    
    func unpinSession(_ session: ChatSession) {
        session.pinned = false
        session.updatedAt = Date()
        try? modelContext.save()
    }
    
    func updateSessionTitle(_ session: ChatSession, title: String) {
        session.title = title
        session.updatedAt = Date()
        try? modelContext.save()
    }
    
    // MARK: - Messages
    
    func addMessage(role: String, content: String? = nil, thinkingContent: String? = nil, isStreaming: Bool = false, hasImages: Bool = false, to session: ChatSession) -> ChatMessage {
        let message = ChatMessage(
            role: role,
            content: content,
            thinkingContent: thinkingContent,
            isStreaming: isStreaming,
            hasImages: hasImages,
            session: session
        )
        modelContext.insert(message)
        session.updatedAt = Date()
        session.updateCachedValues()
        try? modelContext.save()
        return message
    }
    
    /// Update message in memory only (no SwiftData save). Used during streaming for smooth UI updates.
    func updateMessageInMemory(_ message: ChatMessage, content: String? = nil, thinkingContent: String? = nil) {
        if let content { message.content = content }
        if let thinkingContent { message.thinkingContent = thinkingContent }
        // No save — just update @Model properties which SwiftUI observes directly
    }
    
    /// Update message and persist to SwiftData. Used for final saves (stream end, incremental timer).
    func updateMessage(_ message: ChatMessage, content: String? = nil, thinkingContent: String? = nil, isStreaming: Bool? = nil) {
        if let content { message.content = content }
        if let thinkingContent { message.thinkingContent = thinkingContent }
        if let isStreaming { message.isStreaming = isStreaming }
        try? modelContext.save()
    }
    
    func fetchMessages(for session: ChatSession) -> [ChatMessage] {
        let sessionId = session.id
        let descriptor = FetchDescriptor<ChatMessage>(
            predicate: #Predicate { $0.session?.id == sessionId },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    // MARK: - Search
    
    func searchSessions(query: String) -> [ChatSession] {
        let descriptor = FetchDescriptor<ChatSession>(
            predicate: #Predicate { $0.title.localizedStandardContains(query) }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    // MARK: - Draft Recovery
    
    /// Find any streaming (incomplete) messages that weren't finalized
    func findDraftMessages() -> [ChatMessage] {
        let descriptor = FetchDescriptor<ChatMessage>(
            predicate: #Predicate { $0.isStreaming == true }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func finalizeDraft(_ message: ChatMessage) {
        message.isStreaming = false
        try? modelContext.save()
    }
    
    // MARK: - Delete Messages
    
    /// Delete a single message by ID.
    func deleteMessage(_ message: ChatMessage) {
        let session = message.session
        modelContext.delete(message)
        session?.updateCachedValues()
        try? modelContext.save()
    }
    
    /// Delete a message and all messages after it (by timestamp within the session).
    func deleteMessagesFrom(sessionId: UUID, from timestamp: Date) {
        let descriptor = FetchDescriptor<ChatMessage>(
            predicate: #Predicate {
                $0.session?.id == sessionId && $0.createdAt >= timestamp
            }
        )
        let messages = (try? modelContext.fetch(descriptor)) ?? []
        for msg in messages {
            modelContext.delete(msg)
        }
        // Find session and update cache
        let sessionDescriptor = FetchDescriptor<ChatSession>(
            predicate: #Predicate { $0.id == sessionId }
        )
        if let session = try? modelContext.fetch(sessionDescriptor).first {
            session.updateCachedValues()
        }
        try? modelContext.save()
    }
}