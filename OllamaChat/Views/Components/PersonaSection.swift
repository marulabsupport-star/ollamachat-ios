import SwiftUI
import SwiftData

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