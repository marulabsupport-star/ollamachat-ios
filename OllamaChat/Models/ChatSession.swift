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
    
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.session)
    var messages: [ChatMessage]
    
    var lastMessagePreview: String? {
        guard let content = messages.last?.content else { return nil }
        return String(content.prefix(100))
    }
    
    var messageCount: Int {
        messages.count
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
        self.messages = messages
    }
}