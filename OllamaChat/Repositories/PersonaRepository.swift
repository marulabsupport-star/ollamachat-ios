import Foundation
import SwiftData

/// Manages persona CRUD operations via SwiftData.
@MainActor
final class PersonaRepository {
    
    var modelContext: ModelContext!
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    // MARK: - CRUD
    
    func fetchAll() -> [PersonaEntry] {
        let descriptor = FetchDescriptor<PersonaEntry>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func create(name: String, systemPrompt: String, isDefault: Bool = false) -> PersonaEntry {
        // If setting as default, unset existing default first
        if isDefault {
            unsetDefault()
        }
        let persona = PersonaEntry(name: name, systemPrompt: systemPrompt, isDefault: isDefault)
        modelContext.insert(persona)
        try? modelContext.save()
        return persona
    }
    
    func update(_ persona: PersonaEntry, name: String? = nil, systemPrompt: String? = nil) {
        if let name { persona.name = name }
        if let systemPrompt { persona.systemPrompt = systemPrompt }
        try? modelContext.save()
    }
    
    func delete(_ persona: PersonaEntry) {
        modelContext.delete(persona)
        try? modelContext.save()
    }
    
    func setDefault(_ persona: PersonaEntry) {
        unsetDefault()
        persona.isDefault = true
        try? modelContext.save()
    }
    
    func unsetDefault() {
        let all = fetchAll()
        for p in all where p.isDefault {
            p.isDefault = false
        }
        try? modelContext.save()
    }
    
    /// Returns the default persona, if any
    func fetchDefault() -> PersonaEntry? {
        let descriptor = FetchDescriptor<PersonaEntry>(
            predicate: #Predicate { $0.isDefault == true }
        )
        return (try? modelContext.fetch(descriptor))?.first
    }
    
    // MARK: - Seed Default Personas
    
    /// Seed built-in personas if the database is empty
    func seedDefaultsIfNeeded() {
        let existing = fetchAll()
        guard existing.isEmpty else { return }
        
        let defaults: [(String, String)] = [
            ("Helpful Assistant", "You are a helpful, friendly assistant. Answer questions accurately and concisely."),
            ("Code Expert", "You are an expert programmer. Provide clean, well-documented code with explanations. When writing code, always include error handling and comments."),
            ("Creative Writer", "You are a creative writer with a vivid imagination. Write engaging, descriptive content. Use metaphors and storytelling techniques."),
            ("Concise Responder", "You are a concise responder. Give brief, direct answers without unnecessary elaboration. Use bullet points when appropriate."),
        ]
        
        for (index, (name, prompt)) in defaults.enumerated() {
            let persona = PersonaEntry(name: name, systemPrompt: prompt, isDefault: index == 0)
            modelContext.insert(persona)
        }
        try? modelContext.save()
    }
}