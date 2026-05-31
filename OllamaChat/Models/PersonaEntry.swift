import Foundation
import SwiftData

/// A custom persona that injects its systemPrompt when active.
/// Mirrors Android's PersonaEntry (id, name, systemPrompt, isDefault, createdAt).
@Model
final class PersonaEntry {
    var id: UUID
    var name: String
    var systemPrompt: String
    var isDefault: Bool
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        systemPrompt: String,
        isDefault: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.systemPrompt = systemPrompt
        self.isDefault = isDefault
        self.createdAt = createdAt
    }
}