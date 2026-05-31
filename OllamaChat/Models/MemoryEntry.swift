import Foundation
import SwiftData

/// Persistent key-value memory entries injected into every conversation as context.
@Model
final class MemoryEntry {
    @Attribute(.unique) var key: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    
    init(key: String, content: String) {
        self.key = key
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}