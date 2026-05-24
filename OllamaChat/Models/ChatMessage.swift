import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id: UUID
    var role: String       // "user" | "assistant"
    var content: String?
    var thinkingContent: String?
    var isStreaming: Bool
    var hasImages: Bool
    var createdAt: Date
    
    var session: ChatSession?
    
    init(
        id: UUID = UUID(),
        role: String,
        content: String? = nil,
        thinkingContent: String? = nil,
        isStreaming: Bool = false,
        hasImages: Bool = false,
        createdAt: Date = Date(),
        session: ChatSession? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.thinkingContent = thinkingContent
        self.isStreaming = isStreaming
        self.hasImages = hasImages
        self.createdAt = createdAt
        self.session = session
    }
}