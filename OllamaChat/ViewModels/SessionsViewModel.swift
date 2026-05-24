import Foundation
import SwiftData

/// Manages session list (recents) screen state.
@MainActor
@Observable
final class SessionsViewModel {
    
    private let chatRepo: ChatRepository
    
    var sessions: [ChatSession] = []
    var searchText: String = ""
    var isSearching: Bool = false
    
    // MARK: - Init
    
    init(chatRepo: ChatRepository) {
        self.chatRepo = chatRepo
    }
    
    // MARK: - Load
    
    func loadSessions() {
        if searchText.isEmpty {
            sessions = chatRepo.fetchSessions()
        } else {
            sessions = chatRepo.searchSessions(query: searchText)
        }
    }
    
    // MARK: - Actions
    
    func pinSession(_ session: ChatSession) {
        chatRepo.pinSession(session)
        loadSessions()
    }
    
    func unpinSession(_ session: ChatSession) {
        chatRepo.unpinSession(session)
        loadSessions()
    }
    
    func deleteSession(_ session: ChatSession) {
        chatRepo.deleteSession(session)
        loadSessions()
    }
}