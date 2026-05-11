import Foundation
import os

/// HTTP client for Tavily search API.
actor TavilyClient {
    
    private let logger = Logger(subsystem: "com.openclaw.ollamachat", category: "network")
    private let session = URLSession.shared
    
    private let settingsRepo: SettingsRepository
    
    init(settingsRepo: SettingsRepository = .shared) {
        self.settingsRepo = settingsRepo
    }
    
    func search(query: String, maxResults: Int = 5) async throws -> [TavilyResult] {
        guard let apiKey = settingsRepo.tavilyAPIKey else {
            throw OllamaError.apiKeyMissing
        }
        
        let url = URL(string: "https://api.tavily.com/search")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        
        let body = TavilySearchRequest(apiKey: apiKey, query: query, maxResults: maxResults)
        request.httpBody = try JSONEncoder().encode(body)
        
        logger.debug("Tavily search: \(query)")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.unexpected("Invalid response from Tavily")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw OllamaError.apiKeyInvalid
        case 429:
            throw OllamaError.rateLimited
        default:
            throw OllamaError.httpError(statusCode: httpResponse.statusCode, message: "Tavily API error")
        }
        
        let searchResponse = try JSONDecoder().decode(TavilySearchResponse.self, from: data)
        return searchResponse.results
    }
}