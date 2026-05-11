import Foundation
import SwiftData
import os

/// Handles backup (JSON export) and restore (JSON import) of chat data.
@MainActor
final class BackupService {
    
    private let logger = Logger(subsystem: "com.openclaw.ollamachat", category: "backup")
    
    private let chatRepo: ChatRepository
    
    init(chatRepo: ChatRepository) {
        self.chatRepo = chatRepo
    }
    
    // MARK: - Export
    
    /// Export all chat sessions to JSON data. API keys are excluded for security.
    func exportBackup() throws -> Data {
        let sessions = chatRepo.fetchSessions()
        
        let backupSessions = sessions.map { session -> BackupSession in
            let messages = chatRepo.fetchMessages(for: session)
            return BackupSession(
                id: session.id,
                title: session.title,
                modelName: session.modelName,
                connectionMode: session.connectionMode,
                systemPrompt: session.systemPrompt,
                pinned: session.pinned,
                createdAt: session.createdAt,
                updatedAt: session.updatedAt,
                messages: messages.map { msg in
                    BackupMessage(
                        id: msg.id,
                        role: msg.role,
                        content: msg.content,
                        thinkingContent: msg.thinkingContent,
                        createdAt: msg.createdAt
                    )
                }
            )
        }
        
        let backup = BackupData(
            version: BackupData.currentVersion,
            exportedAt: Date(),
            sessions: backupSessions
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        return try encoder.encode(backup)
    }
    
    /// Export to a file URL
    func exportToFile() throws -> URL {
        let data = try exportBackup()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let filename = "ollamachat_backup_\(formatter.string(from: Date())).json"
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url)
        
        return url
    }
    
    // MARK: - Import
    
    /// Import chat sessions from JSON data.
    /// Validates schema version and data before importing.
    func importBackup(from data: Data) throws -> Int {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let backup: BackupData
        do {
            backup = try decoder.decode(BackupData.self, from: data)
        } catch {
            throw OllamaError.backupImportFailed(reason: "Invalid backup file format")
        }
        
        // Validate version
        guard backup.version <= BackupData.currentVersion else {
            throw OllamaError.backupVersionUnsupported(version: backup.version)
        }
        
        guard backup.version >= 1 else {
            throw OllamaError.backupImportFailed(reason: "Unsupported backup version")
        }
        
        // Import each session
        var imported = 0
        for backupSession in backup.sessions {
            let session = chatRepo.createSession(
                title: backupSession.title,
                modelName: backupSession.modelName,
                connectionMode: backupSession.connectionMode,
                systemPrompt: backupSession.systemPrompt
            )
            // Restore original ID and dates
            // Note: SwiftData doesn't allow changing ID after insert, so we use new IDs
            
            for backupMsg in backupSession.messages {
                _ = chatRepo.addMessage(
                    role: backupMsg.role,
                    content: backupMsg.content,
                    thinkingContent: backupMsg.thinkingContent,
                    to: session
                )
            }
            
            if backupSession.pinned {
                chatRepo.pinSession(session)
            }
            
            imported += 1
        }
        
        logger.info("Imported \(imported) sessions from backup")
        return imported
    }
    
    /// Import from a file URL
    func importFromFile(at url: URL) throws -> Int {
        // Security-scoped resource access for file picker
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
        
        let data = try Data(contentsOf: url)
        return try importBackup(from: data)
    }
}