import SwiftUI
import SwiftData

/// Persona management UI — matches Android's Persona section in Settings.
struct PersonaSection: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var personas: [PersonaEntry] = []
    @State private var expanded = false
    @State private var selectedPersonaId: UUID?
    @State private var showAddSheet = false
    @State private var editingPersona: PersonaEntry?
    
    /// Whether the custom system prompt is overridden by a persona
    var onSystemPromptOverride: ((String?) -> Void)?
    
    private var repo: PersonaRepository {
        let r = PersonaRepository(modelContext: modelContext)
        return r
    }
    
    var body: some View {
        ExpandableSettingsCard(
            title: "Personas",
            icon: "person.crop.circle.fill",
            cardId: "personas",
            expandedCard: .constant(expanded ? "personas" : nil)
        ) {
            personaContent
        }
        .onAppear {
            loadPersonas()
        }
        .onChange(of: expanded) { _, _ in
            // no-op, just refresh
        }
        .sheet(isPresented: $showAddSheet) {
            PersonaEditSheet(mode: .add) { name, prompt in
                let persona = repo.create(name: name, systemPrompt: prompt)
                loadPersonas()
                selectedPersonaId = persona.id
                notifySystemPromptChange()
            }
        }
        .sheet(item: $editingPersona) { persona in
            PersonaEditSheet(mode: .edit(persona)) { name, prompt in
                repo.update(persona, name: name, systemPrompt: prompt)
                loadPersonas()
                notifySystemPromptChange()
            }
        }
    }
    
    // Using a separate binding approach for expandable card
    // Since ExpandableSettingsCard uses a shared expandedCard binding,
    // we need to integrate personas into SettingsScreen's expandedCard state.
    // For now, we provide the content and let SettingsScreen handle expansion.
    
    static func personaContent(modelContext: ModelContext, personas: Binding<[PersonaEntry]>, selectedPersonaId: Binding<UUID?>, onEdit: @escaping (PersonaEntry) -> Void, onSetDefault: @escaping (PersonaEntry) -> Void, onDelete: @escaping (PersonaEntry) -> Void, onSystemPromptChange: @escaping (String?) -> Void) -> some View {
        PersonaContentView(
            modelContext: modelContext,
            personas: personas,
            selectedPersonaId: selectedPersonaId,
            onEdit: onEdit,
            onSetDefault: onSetDefault,
            onDelete: onDelete,
            onSystemPromptChange: onSystemPromptChange
        )
    }
}

// MARK: - Persona Content View

struct PersonaContentView: View {
    let modelContext: ModelContext
    @Binding var personas: [PersonaEntry]
    @Binding var selectedPersonaId: UUID?
    let onEdit: (PersonaEntry) -> Void
    let onSetDefault: (PersonaEntry) -> Void
    let onDelete: (PersonaEntry) -> Void
    let onSystemPromptChange: (String?) -> Void
    
    @State private var showAddSheet = false
    
    private var repo: PersonaRepository {
        PersonaRepository(modelContext: modelContext)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Persona selector
            if personas.isEmpty {
                Text("No personas yet. Add one to customize AI behavior.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(personas) { persona in
                    PersonaRow(
                        persona: persona,
                        isSelected: selectedPersonaId == persona.id,
                        onSelect: {
                            if selectedPersonaId == persona.id {
                                // Deselect — use no persona
                                selectedPersonaId = nil
                                onSystemPromptChange(nil)
                            } else {
                                selectedPersonaId = persona.id
                                onSystemPromptChange(persona.systemPrompt)
                            }
                        },
                        onEdit: { onEdit(persona) },
                        onSetDefault: { onSetDefault(persona) },
                        onDelete: { onDelete(persona) }
                    )
                }
            }
            
            // Add persona button
            Button {
                showAddSheet = true
            } label: {
                Label("Add Persona", systemImage: "plus.circle.fill")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)
        }
        .sheet(isPresented: $showAddSheet) {
            PersonaEditSheet(mode: .add) { name, prompt in
                let persona = repo.create(name: name, systemPrompt: prompt)
                personas = repo.fetchAll()
                selectedPersonaId = persona.id
                onSystemPromptChange(persona.systemPrompt)
            }
        }
    }
}

// MARK: - Persona Row

struct PersonaRow: View {
    let persona: PersonaEntry
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onSetDefault: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            Button(action: onSelect) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .font(.title3)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(persona.name)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                    if persona.isDefault {
                        Text("Default")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.accentColor.opacity(0.8))
                            .clipShape(Capsule())
                    }
                }
                Text(persona.systemPrompt.prefix(60) + (persona.systemPrompt.count > 60 ? "..." : ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Actions menu
            Menu {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                Button(action: onSetDefault) {
                    Label("Set as Default", systemImage: "star")
                }
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Persona Edit Sheet

enum PersonaEditMode {
    case add
    case edit(PersonaEntry)
}

struct PersonaEditSheet: View {
    let mode: PersonaEditMode
    let onSave: (String, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var systemPrompt: String = ""
    
    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Name") {
                    TextField("Persona name", text: $name)
                }
                
                Section("System Prompt") {
                    TextField("Describe how the AI should behave...", text: $systemPrompt, axis: .vertical)
                        .lineLimit(3...10)
                }
            }
            .navigationTitle(isEditing ? "Edit Persona" : "New Persona")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        onSave(name.trimmingCharacters(in: .whitespaces), systemPrompt)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if case .edit(let persona) = mode {
                    name = persona.name
                    systemPrompt = persona.systemPrompt
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}