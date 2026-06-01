import Foundation
import SwiftData

/// Weekly token usage tracking entry.
/// Tracks token counts per week/category/direction (cloud/local × input/output).
@Model
final class TokenUsageEntry {
    var weekId: String       // ISO week: "2026-W22"
    var category: String     // "cloud" or "local"
    var direction: String    // "input" or "output"
    var tokens: Int
    var updatedAt: Date
    
    init(weekId: String, category: String, direction: String, tokens: Int = 0) {
        self.weekId = weekId
        self.category = category
        self.direction = direction
        self.tokens = tokens
        self.updatedAt = Date()
    }
}