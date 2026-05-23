import Foundation
import os

/// Orchestrates web search via Tavily API and formats results for chat context.
@MainActor
@Observable
final class SearchService {
    
    private let logger = Logger(subsystem: "com.marulab.llmchat", category: "search")
    
    private let tavilyClient: TavilyClient
    
    var isSearching: Bool = false
    var searchResults: [TavilyResult] = []
    var searchError: String?
    
    init(tavilyClient: TavilyClient = TavilyClient()) {
        self.tavilyClient = tavilyClient
    }
    
    /// Search the web and return formatted context string for chat
    func search(query: String) async -> String? {
        guard !query.isEmpty else { return nil }
        
        isSearching = true
        searchError = nil
        
        do {
            let results = try await tavilyClient.search(query: query, maxResults: 3)
            searchResults = results
            isSearching = false
            
            if results.isEmpty { return nil }
            return formatResultsAsContext(results, query: query)
        } catch {
            searchError = error.localizedDescription
            isSearching = false
            logger.error("Search failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Format search results as a system context for the AI model.
    /// Injected as system message — never shown to the user directly.
    func formatResultsAsContext(_ results: [TavilyResult], query: String) -> String {
        guard !results.isEmpty else { return "" }
        
        var context = "[Web search for: \"\(query)\"]\n"
        for (index, result) in results.enumerated() {
            context += "\(index + 1). \(result.title)\n\(result.content)\n\n"
        }
        context += "Answer the user's question using this information. Do not mention that you searched the web or quote the search results directly. Just provide a natural, helpful response."
        
        return context
    }
}