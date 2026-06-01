import Foundation
import SwiftData

@MainActor
final class TokenUsageRepository {
    
    var modelContext: ModelContext!
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    // MARK: - Current Week ID
    
    static func currentWeekId() -> String {
        let cal = Calendar(identifier: .iso8601)
        let date = Date()
        let week = cal.component(.weekOfYear, from: date)
        let year = cal.component(.yearForWeekOfYear, from: date)
        return "\(year)-W\(String(format: "%02d", week))"
    }
    
    // MARK: - Add Tokens
    
    func addTokens(weekId: String, category: String, direction: String, count: Int) {
        let descriptor = FetchDescriptor<TokenUsageEntry>(
            predicate: #Predicate {
                $0.weekId == weekId && $0.category == category && $0.direction == direction
            }
        )
        let existing = (try? modelContext.fetch(descriptor))?.first
        if let entry = existing {
            entry.tokens += count
            entry.updatedAt = Date()
        } else {
            let entry = TokenUsageEntry(weekId: weekId, category: category, direction: direction, tokens: count)
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }
    
    // MARK: - Get Week Usage
    
    struct WeekUsage {
        var cloudInput: Int = 0
        var cloudOutput: Int = 0
        var localInput: Int = 0
        var localOutput: Int = 0
        
        var totalCloud: Int { cloudInput + cloudOutput }
        var totalLocal: Int { localInput + localOutput }
        var total: Int { totalCloud + totalLocal }
    }
    
    func getWeekUsage(weekId: String) -> WeekUsage {
        let descriptor = FetchDescriptor<TokenUsageEntry>(
            predicate: #Predicate { $0.weekId == weekId }
        )
        let entries = (try? modelContext.fetch(descriptor)) ?? []
        var usage = WeekUsage()
        for entry in entries {
            switch (entry.category, entry.direction) {
            case ("cloud", "input"): usage.cloudInput = entry.tokens
            case ("cloud", "output"): usage.cloudOutput = entry.tokens
            case ("local", "input"): usage.localInput = entry.tokens
            case ("local", "output"): usage.localOutput = entry.tokens
            default: break
            }
        }
        return usage
    }
    
    func getCurrentWeekUsage() -> WeekUsage {
        getWeekUsage(weekId: Self.currentWeekId())
    }
    
    // MARK: - Cleanup
    
    func deleteOldWeeks(keepWeekId: String) {
        let descriptor = FetchDescriptor<TokenUsageEntry>(
            predicate: #Predicate { $0.weekId != keepWeekId }
        )
        let oldEntries = (try? modelContext.fetch(descriptor)) ?? []
        for entry in oldEntries {
            modelContext.delete(entry)
        }
        try? modelContext.save()
    }
}