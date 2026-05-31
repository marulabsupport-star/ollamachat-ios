import Foundation
import SwiftData

@MainActor
final class MemoryRepository {
    
    var modelContext: ModelContext!
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    // MARK: - CRUD
    
    func fetchAll() -> [MemoryEntry] {
        let descriptor = FetchDescriptor<MemoryEntry>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func add(key: String, content: String) -> MemoryEntry {
        // Check if key already exists — update instead
        if let existing = fetchByKey(key) {
            existing.content = content
            existing.updatedAt = Date()
            try? modelContext.save()
            return existing
        }
        let entry = MemoryEntry(key: key, content: content)
        modelContext.insert(entry)
        try? modelContext.save()
        return entry
    }
    
    func update(_ entry: MemoryEntry, key: String, content: String) {
        entry.key = key
        entry.content = content
        entry.updatedAt = Date()
        try? modelContext.save()
    }
    
    func delete(_ entry: MemoryEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }
    
    func deleteAll() {
        let entries = fetchAll()
        for entry in entries {
            modelContext.delete(entry)
        }
        try? modelContext.save()
    }
    
    // MARK: - Search
    
    func search(query: String) -> [MemoryEntry] {
        let descriptor = FetchDescriptor<MemoryEntry>(
            predicate: #Predicate {
                $0.key.localizedStandardContains(query) || $0.content.localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    // MARK: - Build System Prompt Context
    
    /// Build a system prompt fragment from all memory entries.
    /// Returns nil if no entries exist.
    func buildMemoryContext() -> String? {
        let entries = fetchAll()
        guard !entries.isEmpty else { return nil }
        
        var lines = ["[User Memory Context]"]
        for entry in entries {
            lines.append("- \(entry.key): \(entry.content)")
        }
        lines.append("[/User Memory Context]")
        return lines.joined(separator: "\n")
    }
    
    // MARK: - Private
    
    private func fetchByKey(_ key: String) -> MemoryEntry? {
        let descriptor = FetchDescriptor<MemoryEntry>(
            predicate: #Predicate { $0.key == key }
        )
        return (try? modelContext.fetch(descriptor))?.first
    }
}