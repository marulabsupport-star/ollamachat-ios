import SwiftUI
import SwiftData

struct MemorySection: View {
    @Query(sort: \MemoryEntry.updatedAt, order: .reverse) private var entries: [MemoryEntry]
    @Environment(\.modelContext) private var modelContext
    
    @State private var isExpanded = false
    @State private var newKey = ""
    @State private var newContent = ""
    @State private var editingEntry: MemoryEntry?
    @State private var editKey = ""
    @State private var editContent = ""
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(.purple)
                    Text("Memory")
                        .font(.headline)
                    Spacer()
                    Text("\(entries.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(spacing: 12) {
                    Text("Add key-value pairs injected into every conversation as context. The AI will remember these across all sessions.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Add new entry
                    Group {
                        TextField("Key (e.g. My Name)", text: $newKey)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Content (e.g. I prefer concise answers)", text: $newContent, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(2...4)
                        
                        Button {
                            addEntry()
                        } label: {
                            Label("Add Memory", systemImage: "plus")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newKey.trimmingCharacters(in: .whitespaces).isEmpty || newContent.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    
                    if !entries.isEmpty {
                        Divider()
                        
                        Text("\(entries.count) memory \(entries.count == 1 ? "entry" : "entries")")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        ForEach(entries) { entry in
                            if editingEntry?.id == entry.id {
                                MemoryEditRow(
                                    key: $editKey,
                                    content: $editContent,
                                    onSave: { saveEdit(entry) },
                                    onCancel: { editingEntry = nil }
                                )
                            } else {
                                MemoryEntryRow(
                                    entry: entry,
                                    onEdit: {
                                        editingEntry = entry
                                        editKey = entry.key
                                        editContent = entry.content
                                    },
                                    onDelete: { deleteEntry(entry) }
                                )
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func addEntry() {
        let key = newKey.trimmingCharacters(in: .whitespaces)
        let content = newContent.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty, !content.isEmpty else { return }
        
        let repo = MemoryRepository(modelContext: modelContext)
        repo.add(key: key, content: content)
        newKey = ""
        newContent = ""
    }
    
    private func saveEdit(_ entry: MemoryEntry) {
        let key = editKey.trimmingCharacters(in: .whitespaces)
        let content = editContent.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty, !content.isEmpty else { return }
        
        let repo = MemoryRepository(modelContext: modelContext)
        repo.update(entry, key: key, content: content)
        editingEntry = nil
    }
    
    private func deleteEntry(_ entry: MemoryEntry) {
        let repo = MemoryRepository(modelContext: modelContext)
        repo.delete(entry)
    }
}

// MARK: - Entry Row

struct MemoryEntryRow: View {
    let entry: MemoryEntry
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.key)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Text(entry.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            Spacer()
            
            Button { onEdit() } label: {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Button { onDelete() } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.7))
            }
        }
        .padding(10)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Edit Row

struct MemoryEditRow: View {
    @Binding var key: String
    @Binding var content: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            TextField("Key", text: $key)
                .textFieldStyle(.roundedBorder)
            
            TextField("Content", text: $content, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
            
            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .font(.subheadline)
                Button("Save", action: onSave)
                    .font(.subheadline)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(10)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}