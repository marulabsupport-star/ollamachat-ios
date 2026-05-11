import SwiftUI
import UniformTypeIdentifiers

struct BackupRestoreScreen: View {
    @State private var exportedFileURL: URL?
    @State private var showShareSheet = false
    @State private var isImporting = false
    @State private var resultMessage: String?
    @State private var showingResult = false
    @State private var isExporting = false
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        List {
            Section("Export") {
                Button {
                    exportBackup()
                } label: {
                    HStack {
                        Label("Export Backup", systemImage: "square.and.arrow.up")
                        if isExporting {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isExporting)
                
                Text("Save all conversations as a JSON file. You can share it via AirDrop, Mail, or save to Files.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Import") {
                Button {
                    isImporting = true
                } label: {
                    Label("Import Backup", systemImage: "square.and.arrow.down")
                }
                
                Text("Import will add sessions from the backup file. Existing sessions are not modified.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                Text("Backups include all conversations and settings. API keys are excluded for security.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Backup & Restore")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
            importBackup(result)
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedFileURL {
                ShareSheetView(item: url)
            }
        }
        .alert("Backup", isPresented: $showingResult) {
            Button("OK") {}
        } message: {
            Text(resultMessage ?? "")
        }
    }
    
    private func exportBackup() {
        isExporting = true
        let chatRepo = ChatRepository(modelContext: modelContext)
        let backupService = BackupService(chatRepo: chatRepo)
        
        do {
            let url = try backupService.exportToFile()
            exportedFileURL = url
            isExporting = false
            showShareSheet = true
        } catch {
            isExporting = false
            resultMessage = "Export failed: \(error.localizedDescription)"
            showingResult = true
        }
    }
    
    private func importBackup(_ result: Result<URL, Error>) {
        let chatRepo = ChatRepository(modelContext: modelContext)
        let backupService = BackupService(chatRepo: chatRepo)
        
        switch result {
        case .success(let url):
            do {
                let count = try backupService.importFromFile(at: url)
                resultMessage = "Imported \(count) sessions successfully"
            } catch {
                resultMessage = "Import failed: \(error.localizedDescription)"
            }
        case .failure(let error):
            resultMessage = "Failed to read file: \(error.localizedDescription)"
        }
        showingResult = true
    }
}

// MARK: - Share Sheet Wrapper

struct ShareSheetView: UIViewControllerRepresentable {
    let item: URL
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: [item],
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}