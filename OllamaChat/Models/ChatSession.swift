import Foundation
import SwiftData

@Model
final class ChatSession {
    var id: UUID
    var title: String
    var modelName: String
    var connectionMode: String  // "cloud" | "local"
    var systemPrompt: String
    var pinned: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // Cached values to avoid touching @Relationship on list render
    var cachedMessageCount: Int
    var cachedPreview: String?
    
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.session)
    var messages: [ChatMessage]
    
    var lastMessagePreview: String? {
        cachedPreview ?? String((messages.last?.content ?? "").prefix(100))
    }
    
    var messageCount: Int {
        cachedMessageCount >= 0 ? cachedMessageCount : messages.count
    }
    
    init(
        id: UUID = UUID(),
        title: String = "New Chat",
        modelName: String = "",
        connectionMode: String = "cloud",
        systemPrompt: String = "",
        pinned: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        messages: [ChatMessage] = []
    ) {
        self.id = id
        self.title = title
        self.modelName = modelName
        self.connectionMode = connectionMode
        self.systemPrompt = systemPrompt
        self.pinned = pinned
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.cachedMessageCount = messages.count
        self.cachedPreview = nil
        self.messages = messages
    }
    
    /// Call after adding/removing messages to keep cached values in sync.
    func updateCachedValues() {
        cachedMessageCount = messages.count
        cachedPreview = messages.last?.content.map { String($0.prefix(100)) }
    }
}